//
//  ExecuteRequest.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 21.09.2021.
//  Copyright © 2021 DIGITAL RETAIL TECHNOLOGIES, S.L. All rights reserved.
//

import Alamofire
import Foundation

public class ExecuteRequest<O: GraphQLOperation>: SuccessableRequest {

    public typealias ResultValue = O.Value

    private let alamofireRequest: DataRequest
    private weak var client: Client?
    private let muteCanceledRequests: Bool
    private let monitor: CompositeGrapheneEventMonitor
    private let queue: DispatchQueue
    private let errorModifier: Client.Configuration.ErrorModifier?
    private var closureStorage = ExecuteClosureStorage<ResultValue>()
    public let context: OperationContext
    public private(set) var isSending = false
    public var request: URLRequest? { self.alamofireRequest.request }
    public var task: URLSessionTask? { self.alamofireRequest.task }

    internal init(client: Client, alamofireRequest: DataRequest, decodePath: String?, context: OperationContext, queue: DispatchQueue) {
        self.client = client
        self.monitor = CompositeGrapheneEventMonitor(monitors: client.configuration.eventMonitors)
        self.muteCanceledRequests = client.configuration.muteCanceledRequests
        self.errorModifier = client.configuration.errorModifier
        self.alamofireRequest = alamofireRequest
        self.context = context
        self.queue = queue
        let jsonDecoder = JSONDecoder()
        jsonDecoder.keyDecodingStrategy = client.configuration.keyDecodingStrategy
        jsonDecoder.dateDecodingStrategy = client.configuration.dateDecodingStrategy
        jsonDecoder.userInfo[.operationName] = context.operationName
        let decoder = GraphQLDecoder(decodePath: O.decodePath, jsonDecoder: jsonDecoder)
        self.alamofireRequest
            .uploadProgress(queue: self.queue, closure: self.handleProgress(_:))
            .responseDecodable(queue: .global(qos: .utility), decoder: decoder, completionHandler: self.handleResponse(_:))
    }

    private func send() {
        guard !self.isSending else { return }
        self.isSending = true
        self.alamofireRequest.resume()
        if let client = self.client {
            self.monitor.client(client, didSend: self)
        }
    }

    private func handleProgress(_ progress: Progress) {
        if self.muteCanceledRequests, progress.isCancelled {
            return
        }
        self.closureStorage.progressClosure?(progress.fractionCompleted)
    }

    private func handleResponse(_ dataResponse: DataResponse<O.ResponseValue, AFError>) {

        defer {
            self.isSending = false
        }

        if self.muteCanceledRequests, dataResponse.error?.isExplicitlyCancelledError ?? false {
            return
        }

        let result = O.mapResponse(dataResponse.result.mapError({ $0.underlyingError ?? $0 }))

        self.queue.async {
            if !self.muteCanceledRequests || !self.alamofireRequest.isCancelled {
                do {
                    let result = try result.get()
                    try self.closureStorage.successClosure?(result)
                    if let client = self.client {
                        let response = GrapheneResponse(
                            context: self.context,
                            request: dataResponse.request,
                            response: dataResponse.response,
                            error: nil,
                            data: dataResponse.data,
                            metrics: dataResponse.metrics
                        )
                        self.monitor.client(client, didReceive: response)
                    }
                } catch {
                    let modifiedError = self.errorModifier?(error) ?? error
                    self.closureStorage.failureClosure?(modifiedError)
                    if let client = self.client {
                        let response = GrapheneResponse(
                            context: self.context,
                            request: dataResponse.request,
                            response: dataResponse.response,
                            error: modifiedError,
                            data: dataResponse.data,
                            metrics: dataResponse.metrics
                        )
                        self.monitor.client(client, didReceive: response)
                    }
                }
                self.closureStorage.finishClosure?()
            }
        }

    }

    @discardableResult
    public func onSuccess(_ closure: @escaping SuccessClosure) -> ProgressableRequest {
        self.closureStorage.successClosure = closure
        self.send()
        return self
    }

    @discardableResult
    public func onProgress(_ closure: @escaping ProgressClosure) -> FailureableRequest {
        self.closureStorage.progressClosure = closure
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
