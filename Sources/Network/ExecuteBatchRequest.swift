//
//  ExecuteBatchRequest.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 21.09.2021.
//  Copyright © 2021 DIGITAL RETAIL TECHNOLOGIES, S.L. All rights reserved.
//

import Alamofire
import Foundation

public class ExecuteBatchRequest<O: GraphQLOperation>: SuccessableRequest {

    public typealias ResultValue = [O.Value]

    public let context: OperationContext
    public var request: URLRequest? { nil }
    public var task: URLSessionTask? { nil }

    fileprivate let queue: DispatchQueue
    fileprivate var closureStorage = ExecuteClosureStorage<ResultValue>()
    public fileprivate(set) var isSending = false

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

public class ExecuteBatchRequestImpl<O: GraphQLOperation>: ExecuteBatchRequest<O> {

    private var alamofireRequest: DataRequest
    private weak var client: Client?
    private let jsonDecoder: JSONDecoder
    private let muteCanceledRequests: Bool
    private let monitor: CompositeGrapheneEventMonitor
    private let errorModifier: Client.Configuration.ErrorModifier?

    override public var request: URLRequest? { self.alamofireRequest.request }
    override public var task: URLSessionTask? { self.alamofireRequest.task }

    internal init(client: Client, alamofireRequest: DataRequest, decodePath: String?, context: OperationContext, queue: DispatchQueue) {
        self.client = client
        self.monitor = CompositeGrapheneEventMonitor(monitors: client.configuration.eventMonitors)
        self.muteCanceledRequests = client.configuration.muteCanceledRequests
        self.errorModifier = client.configuration.errorModifier
        self.alamofireRequest = alamofireRequest
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = client.configuration.keyDecodingStrategy
        decoder.dateDecodingStrategy = client.configuration.dateDecodingStrategy
        decoder.userInfo[.operationName] = context.operationName
        self.jsonDecoder = decoder

        super.init(context: context, queue: queue)

        self.alamofireRequest
            .uploadProgress(queue: self.queue, closure: self.handleProgress(_:))
            .responseData(queue: .global(qos: .utility), completionHandler: self.handleResponse(_:))

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

    private func handleResponse(_ dataResponse: DataResponse<Data, AFError>) {

        defer {
            self.isSending = false
        }

        var result: Result<[O.Value], Error>
        do {
            let data = try dataResponse.result.mapError({ $0.underlyingError ?? $0 }).get()
            let values = try self.jsonDecoder.decodeArray([O.ResponseValue].self, from: data, keyPath: O.decodePath, keyPathSeparator: ".")
            let mappedValues = try values.map({ try O.mapResponse(.success($0)).get() })
            result = .success(mappedValues)
        } catch {
            var storedError = error
            if let data = dataResponse.value,
               let errors = try? self.jsonDecoder.decode([GraphQLErrors].self, from: data).flatMap(\.errors)
            {
                if errors.count > 1 {
                    storedError = GraphQLErrors(errors)
                } else if let error = errors.first {
                    storedError = error
                }
            }
            result = .failure(storedError)
        }

        self.queue.async {
            var muteClosures = false
            do {
                try self.closureStorage.successClosure?(result.get())
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
                let isCancellationError = error is CancellationError
                muteClosures = (isCancelledError || isCancellationError) && self.muteCanceledRequests
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

    override public func cancel() {
        self.alamofireRequest.cancel()
    }

    override public func withCacheIgnoringServer(maxAge: Int) -> Self {
        self.alamofireRequest
            .storeCacheIgnoringServer(
                context: self.context,
                maxAge: maxAge,
                in: self.client?.session.sessionConfiguration.urlCache ?? .shared
            )
        return self
    }

}

public class ExecuteBatchRequestMock<O: GraphQLOperation>: ExecuteBatchRequest<O> {

    public let mockedResult: Result<ResultValue, Error>
    public let timeout: TimeInterval
    private var responseWorkItem: DispatchWorkItem?

    public init(result: Result<ResultValue, Error>, timeout: TimeInterval, queue: DispatchQueue = .main) {
        self.mockedResult = result
        self.timeout = timeout
        super.init(context: BatchOperationContextData(operation: O.self, operationContexts: []), queue: queue)
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
