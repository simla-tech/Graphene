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
    private var isSent: Bool = false
    private var closureStorage = ExecuteClosureStorage<ResultValue>()
    public let context: OperationContext

    internal init(alamofireRequest: DataRequest, decodePath: String?, context: OperationContext, config: Client.Configuration, queue: DispatchQueue) {
        self.monitor = CompositeGrapheneEventMonitor(monitors: config.eventMonitors)
        self.muteCanceledRequests = config.muteCanceledRequests
        self.alamofireRequest = alamofireRequest
        self.context = context
        self.queue = queue
        let jsonDecoder = JSONDecoder()
        jsonDecoder.keyDecodingStrategy = config.keyDecodingStrategy
        jsonDecoder.dateDecodingStrategy = config.dateDecodingStrategy
        let decoder = GraphQLDecoder(decodePath: O.decodePath, jsonDecoder: jsonDecoder)
        self.alamofireRequest.responseDecodable(queue: .global(qos: .utility), decoder: decoder, completionHandler: self.handleResponse(_:))
    }

    private func send() {
        guard !self.isSent else { return }
        self.isSent = true
        self.monitor.operation(willExecuteWith: self.context)
        self.alamofireRequest.resume()
    }

    private func handleResponse(_ dataResponse: DataResponse<O.ResponseValue, AFError>) {

        if self.muteCanceledRequests, dataResponse.error?.isExplicitlyCancelledError ?? false {
            return
        }

        self.monitor.operation(with: self.context,
                               didFinishWith: dataResponse.response?.statusCode ?? -999,
                               interval: dataResponse.metrics?.taskInterval ?? .init())

        let result = O.mapResponse(dataResponse.result.mapError({ $0.underlyingError ?? $0 }))

        self.queue.sync {
            if !self.muteCanceledRequests || !self.alamofireRequest.isCancelled {
                switch result {
                case .failure(let error):
                    self.monitor.operation(with: self.context, didFailWith: error)
                    self.closureStorage.failureClosure?(error)
                case .success(let result):
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
    public func onFinish(_ closure: @escaping FinishClosure) -> CancellableRequest {
        self.closureStorage.finishClosure = closure
        self.send()
        return self
    }

    public func cancel() {
        self.alamofireRequest.cancel()
        self.isSent = false
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
