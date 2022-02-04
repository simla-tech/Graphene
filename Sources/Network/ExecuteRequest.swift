//
//  ExecuteRequest.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 21.09.2021.
//  Copyright © 2021 RetailDriver LLC. All rights reserved.
//

import Foundation
import Alamofire

public class ExecuteRequest<O: GraphQLOperation>: SuccessableRequest {

    public typealias ResultValue = O.Value

    private let alamofireRequest: DataRequest
    private let muteCanceledRequests: Bool
    private let monitor: CompositeGrapheneEventMonitor
    private let queue: DispatchQueue
    private var closureStorage = ExecuteClosureStorage<ResultValue>()
    public let context: OperationContext
    public private(set) var isSending: Bool = false
    public var request: URLRequest? { self.alamofireRequest.request }

    internal init(alamofireRequest: DataRequest, decodePath: String?, context: OperationContext, config: Client.Configuration, queue: DispatchQueue) {
        self.monitor = CompositeGrapheneEventMonitor(monitors: config.eventMonitors)
        self.muteCanceledRequests = config.muteCanceledRequests
        self.alamofireRequest = alamofireRequest
        self.context = context
        self.queue = queue
        let jsonDecoder = JSONDecoder()
        jsonDecoder.keyDecodingStrategy = config.keyDecodingStrategy
        jsonDecoder.dateDecodingStrategy = config.dateDecodingStrategy
        jsonDecoder.userInfo[.operationName] = context.operationName
        let decoder = GraphQLDecoder(decodePath: O.decodePath, jsonDecoder: jsonDecoder)
        self.alamofireRequest.responseDecodable(queue: .global(qos: .utility), decoder: decoder, completionHandler: self.handleResponse(_:))
    }

    private func send() {
        guard !self.isSending else { return }
        self.isSending = true
        self.monitor.client(willExecute: self)
        self.alamofireRequest.resume()
    }

    private func handleResponse(_ dataResponse: DataResponse<O.ResponseValue, AFError>) {

        defer {
            self.isSending = false
        }

        if self.muteCanceledRequests, dataResponse.error?.isExplicitlyCancelledError ?? false {
            return
        }

        let result = O.mapResponse(dataResponse.result.mapError({ $0.underlyingError ?? $0 }))

        self.queue.sync {
            if !self.muteCanceledRequests || !self.alamofireRequest.isCancelled {
                switch result {
                case .failure(let error):
                    self.monitor.client(didExecute: self, response: dataResponse.response, error: error, data: dataResponse.data, metrics: dataResponse.metrics)
                    self.closureStorage.failureClosure?(error)
                case .success(let result):
                    self.monitor.client(didExecute: self, response: dataResponse.response, error: nil, data: dataResponse.data, metrics: dataResponse.metrics)
                    self.closureStorage.successClosure?(result)
                }
                self.closureStorage.finishClosure?()
            }
        }

    }

    @discardableResult
    public func onSuccess(_ closure: @escaping SuccessClosure) -> FailureableRequest {
        self.closureStorage.successClosure = closure
        self.send()
        return self
    }

    @discardableResult
    public func onFailure(_ closure: @escaping FailureClosure) -> FinishableRequest {
        self.closureStorage.failureClosure = closure
        self.send()
        return self
    }

    @discardableResult
    public func onFinish(_ closure: @escaping FinishClosure) -> GrapheneRequest {
        self.closureStorage.finishClosure = closure
        self.send()
        return self
    }

    public func cancel() {
        self.alamofireRequest.cancel()
    }

}

private class GraphQLDecoder: DataDecoder {

    let decodePath: String
    let jsonDecoder: JSONDecoder

    init(decodePath: String, jsonDecoder: JSONDecoder) {
        self.decodePath = decodePath
        self.jsonDecoder = jsonDecoder
    }

    func decode<D>(_ type: D.Type, from data: Data) throws -> D where D: Decodable {
        do {
            return try self.jsonDecoder.decode(type, from: data, keyPath: self.decodePath)
        } catch {
            if let errors = try? self.jsonDecoder.decode(GraphQLErrors.self, from: data) {
                if errors.count > 1 {
                    throw errors
                } else if let error = errors.first {
                    throw error
                }
            }
            throw error
        }
    }

}
