//
//  OperationRequest.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 03.08.2021.
//  Copyright © 2021 RetailDriver LLC. All rights reserved.
//

import Foundation
import Alamofire

public class OperationRequest<O: GraphQLOperation>: CancellableOperationRequest {

    @discardableResult
    public func perform(queue: DispatchQueue = .main, completion: @escaping (ExecuteResponse<O.Result>) -> Void) -> CancellableOperationRequest {

        self.monitor.operation(willExecuteWith: self.context)
        self.alamofireRequest.responseDecodable(of: OperationRawResponse<O.RootSchema>.self,
                                      queue: .global(qos: .utility),
                                      decoder: self.jsonDecoder) { [weak self] dataResponse in

            guard let `self` = self else { return }

            if self.muteCanceledRequests, dataResponse.error?.isExplicitlyCancelledError ?? false {
                return
            }

            self.monitor.operation(self.context,
                                didFinishWith: dataResponse.response?.statusCode ?? -999,
                                interval: dataResponse.metrics?.taskInterval ?? .init())

            var firstResponse: ExecuteResponse<O.RootSchema>
            do {
                firstResponse = .success(try dataResponse.result.get().getData())
            } catch {
                firstResponse = .failure(error.asAFError?.underlyingError ?? error)
            }

            var secondResponse: ExecuteResponse<O.Result>
            do {
                secondResponse = .success(try O.handleResponse(firstResponse))
            } catch {
                self.monitor.operation(self.context, didFailWith: error)
                secondResponse = .failure(error)
            }

            queue.async {
                if !self.muteCanceledRequests || !self.alamofireRequest.isCancelled {
                    completion(secondResponse)
                }
            }

        }

        return self
    }

}

public class BatchOperationRequest<O: GraphQLOperation>: CancellableOperationRequest {

    @discardableResult
    public func perform(queue: DispatchQueue = .main, completion: @escaping (ExecuteResponse<[O.Result]>) -> Void) -> CancellableOperationRequest {

        self.monitor.operation(willExecuteWith: self.context)
        self.alamofireRequest.responseDecodable(of: [OperationRawResponse<O.RootSchema>].self,
                                      queue: .global(qos: .utility),
                                      decoder: self.jsonDecoder) { [weak self] dataResponse in

            guard let `self` = self else { return }

            if self.muteCanceledRequests, dataResponse.error?.isExplicitlyCancelledError ?? false {
                return
            }

            self.monitor.operation(self.context,
                                didFinishWith: dataResponse.response?.statusCode ?? -999,
                                interval: dataResponse.metrics?.taskInterval ?? .init())

            var secondResponse: ExecuteResponse<[O.Result]>
            do {
                let alamofireResults = try dataResponse.result.get()
                var results: [O.Result] = []
                for alamofireResult in alamofireResults {
                    var firstResponse: ExecuteResponse<O.RootSchema>
                    do {
                        firstResponse = .success(try alamofireResult.getData())
                    } catch {
                        firstResponse = .failure(error)
                    }
                    do {
                        results.append(try O.handleResponse(firstResponse))
                    } catch {
                        throw error
                    }
                }
                secondResponse = .success(results)

            } catch {
                self.monitor.operation(self.context, didFailWith: error)
                secondResponse = .failure(error.asAFError?.underlyingError ?? error)
            }

            queue.async {
                if !self.muteCanceledRequests || !self.alamofireRequest.isCancelled {
                    completion(secondResponse)
                }
            }

        }

        return self
    }

}

public class CancellableOperationRequest {

    internal let alamofireRequest: UploadRequest
    internal let jsonDecoder: JSONDecoder
    internal let muteCanceledRequests: Bool
    internal let monitor: CompositeGrapheneEventMonitor
    public let context: OperationContext

    internal init(alamofireRequest: UploadRequest, context: OperationContext, config: Client.Configuration) {
        self.monitor = CompositeGrapheneEventMonitor(monitors: config.eventMonitors)
        self.muteCanceledRequests = config.muteCanceledRequests
        self.alamofireRequest = alamofireRequest
        self.context = context
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = config.keyDecodingStrategy
        decoder.dateDecodingStrategy = config.dateDecodingStrategy
        self.jsonDecoder = decoder
    }

    public func cancel() {
        self.alamofireRequest.cancel()
    }

}
