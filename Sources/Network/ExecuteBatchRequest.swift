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

    private let alamofireRequest: DataRequest
    private weak var client: Client?
    private let jsonDecoder: JSONDecoder
    private let muteCanceledRequests: Bool
    private let monitor: CompositeGrapheneEventMonitor
    private let errorModifier: Client.Configuration.ErrorModifier?
    private let queue: DispatchQueue
    private var isSent = false
    private var closureStorage = ExecuteClosureStorage<ResultValue>()
    public let context: OperationContext
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
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = client.configuration.keyDecodingStrategy
        decoder.dateDecodingStrategy = client.configuration.dateDecodingStrategy
        decoder.userInfo[.operationName] = context.operationName
        self.jsonDecoder = decoder
        self.alamofireRequest
            .uploadProgress(queue: self.queue, closure: self.handleProgress(_:))
            .responseData(queue: .global(qos: .utility), completionHandler: self.handleResponse(_:))
    }

    private func send() {
        guard !self.isSent else { return }
        self.isSent = true
        if let client = self.client {
            self.monitor.client(client, willSend: self)
        }
        self.alamofireRequest.resume()
    }

    private func handleProgress(_ progress: Progress) {
        if self.muteCanceledRequests, progress.isCancelled {
            return
        }
        self.closureStorage.progressClosure?(progress.fractionCompleted)
    }

    private func handleResponse(_ dataResponse: DataResponse<Data, AFError>) {

        if self.muteCanceledRequests, dataResponse.error?.isExplicitlyCancelledError ?? false {
            return
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
            if !self.muteCanceledRequests || !self.alamofireRequest.isCancelled {
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
        self.isSent = false
    }

}
