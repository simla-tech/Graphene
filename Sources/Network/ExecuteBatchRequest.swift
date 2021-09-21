//
//  ExecuteBatchRequest.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 21.09.2021.
//  Copyright © 2021 RetailDriver LLC. All rights reserved.
//

import Foundation
import Alamofire

public class ExecuteBatchRequest<O: GraphQLOperation>: SuccessableRequest {

    public typealias ResultValue = [O.Value]
    
    private let alamofireRequest: DataRequest
    private let jsonDecoder: JSONDecoder
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
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = config.keyDecodingStrategy
        decoder.dateDecodingStrategy = config.dateDecodingStrategy
        self.jsonDecoder = decoder
    }
    
    private func send() {
        guard !self.isSent else { return }
        self.isSent = true
        self.monitor.operation(willExecuteWith: self.context)
        self.alamofireRequest.responseData(queue: .global(qos: .utility), completionHandler: self.handleResponse(_:))
    }
    
    private func handleResponse(_ dataResponse: DataResponse<Data, AFError>) {
        
        if self.muteCanceledRequests, dataResponse.error?.isExplicitlyCancelledError ?? false {
            return
        }

        self.monitor.operation(with: self.context,
                               didFinishWith: dataResponse.response?.statusCode ?? -999,
                               interval: dataResponse.metrics?.taskInterval ?? .init())

        var result: Result<[O.Value], Error>
        do {
            let data = try dataResponse.result.mapError({ $0.underlyingError ?? $0 }).get()
            let values = try self.jsonDecoder.decodeArray([O.ResponseValue].self, from: data, keyPath: O.decodePath, keyPathSeparator: ".")
            let mappedValues = try values.map({ try O.mapResponse(.success($0)).get() })
            result = .success(mappedValues)
        } catch {
            var storedError = error
            if let data = dataResponse.value, let errors = try? self.jsonDecoder.decode([GraphQLErrors].self, from: data).flatMap({ $0.errors }) {
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
