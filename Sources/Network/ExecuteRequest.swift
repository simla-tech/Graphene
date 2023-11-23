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

    public let context: OperationContext
    public fileprivate(set) var isSending = false

    public var request: URLRequest? {
        nil
    }

    public var task: URLSessionTask? {
        nil
    }

    fileprivate let queue: DispatchQueue
    fileprivate var closureStorage = ExecuteClosureStorage<ResultValue>()

    init(context: OperationContext, queue: DispatchQueue) {
        self.context = context
        self.queue = queue
    }

    public func cancel() {
        fatalError("Override cancel func in \(type(of: Self.self))")
    }

    fileprivate func send() {
        fatalError("Override send func in \(type(of: Self.self))")
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

    public func withCacheIgnoringServer(maxAge: Int) -> Self {
        fatalError("Override withCacheIgnoringServer func in \(type(of: Self.self))")
    }

}

internal class ExecuteRequestImpl<O: GraphQLOperation>: ExecuteRequest<O> {

    private let alamofireRequest: DataRequest
    private weak var client: Client?
    private let muteCanceledRequests: Bool
    private let monitor: CompositeGrapheneEventMonitor
    private let errorModifier: Client.Configuration.ErrorModifier?

    override var request: URLRequest? { self.alamofireRequest.request }
    override var task: URLSessionTask? { self.alamofireRequest.task }

    internal init(client: Client, alamofireRequest: DataRequest, decodePath: String?, context: OperationContext, queue: DispatchQueue) {
        self.client = client
        self.monitor = CompositeGrapheneEventMonitor(monitors: client.configuration.eventMonitors)
        self.muteCanceledRequests = client.configuration.muteCanceledRequests
        self.errorModifier = client.configuration.errorModifier
        self.alamofireRequest = alamofireRequest
        super.init(context: context, queue: queue)
        let jsonDecoder = JSONDecoder()
        jsonDecoder.keyDecodingStrategy = client.configuration.keyDecodingStrategy
        jsonDecoder.dateDecodingStrategy = client.configuration.dateDecodingStrategy
        jsonDecoder.userInfo[.operationName] = context.operationName
        let decoder = GraphQLDecoder(decodePath: O.decodePath, jsonDecoder: jsonDecoder)
        self.alamofireRequest
            .uploadProgress(queue: self.queue, closure: self.handleProgress(_:))
            .responseDecodable(queue: .global(qos: .utility), decoder: decoder, completionHandler: self.handleResponse(_:))

    }

    override fileprivate func send() {
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

        let result = O.mapResponse(dataResponse.result.mapError({ $0.underlyingError ?? $0 }))

        self.queue.async {
            var muteClosures = false
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
                let isCancelledError = modifiedError.asAFError?.isExplicitlyCancelledError ?? false
                muteClosures = isCancelledError && self.muteCanceledRequests
                if !muteClosures {
                    self.closureStorage.failureClosure?(modifiedError)
                }
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
            if !muteClosures {
                self.closureStorage.finishClosure?()
            }
        }

    }

    override func cancel() {
        self.alamofireRequest.cancel()
    }

    override func withCacheIgnoringServer(maxAge: Int) -> Self {
        self.alamofireRequest.storeCacheIgnoringServer(
            context: self.context,
            maxAge: maxAge,
            in: self.client?.session.sessionConfiguration.urlCache ?? .shared
        )
        return self
    }

}

public class ExecuteRequestMock<O: GraphQLOperation>: ExecuteRequest<O> {

    public let mockedResult: Result<ResultValue, Error>
    public let timeout: TimeInterval
    private var responseWorkItem: DispatchWorkItem?

    public init(result: Result<ResultValue, Error>, timeout: TimeInterval, queue: DispatchQueue = .main) {
        self.mockedResult = result
        self.timeout = timeout
        super.init(context: OperationContextData(operation: O.self, variables: [:]), queue: queue)
    }

    override func send() {
        guard !self.isSending else { return }
        self.isSending = true
        let responseWorkItem = DispatchWorkItem(block: { [weak self] in
            guard let self else { return }
            do {
                let value = try self.mockedResult.get()
                try self.closureStorage.successClosure?(value)
            } catch {
                self.closureStorage.failureClosure?(error)
            }
            self.closureStorage.finishClosure?()
        })
        self.queue.asyncAfter(deadline: .now() + self.timeout, execute: responseWorkItem)
        self.responseWorkItem = responseWorkItem
    }

    override public func cancel() {
        self.responseWorkItem?.cancel()
        self.isSending = false
    }

    override public func withCacheIgnoringServer(maxAge: Int) -> Self {
        self
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
