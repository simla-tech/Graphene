//
//  BatchOperationRequest.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 04.08.2021.
//  Copyright © 2021 RetailDriver LLC. All rights reserved.
//

import Foundation
import Alamofire

public class BatchOperationRequest<O: GraphQLOperation>: CancellableOperationRequest {

    @discardableResult
    public func perform(queue: DispatchQueue = .main, completion: @escaping (Result<[O.ResponseValue], Error>) -> Void) -> CancellableOperationRequest {

        self.monitor.operation(willExecuteWith: self.context)
        self.alamofireRequest.responseData(queue: .global(qos: .utility)) { [weak self] dataResponse in

            guard let `self` = self else { return }

            if self.muteCanceledRequests, dataResponse.error?.isExplicitlyCancelledError ?? false {
                return
            }

            self.monitor.operation(with: self.context,
                                   didFinishWith: dataResponse.response?.statusCode ?? -999,
                                   interval: dataResponse.metrics?.taskInterval ?? .init())

            var result: Result<[O.ResponseValue], Error>
            do {
                let data = try dataResponse.result.mapError({ $0.underlyingError ?? $0 }).get()
                let values = try self.jsonDecoder.decodeArray([O.ResponseValue].self, from: data, keyPath: O.decodePath, keyPathSeparator: ".")
                result = .success(values)
            } catch {
                var storedError = error
                if let data = dataResponse.value, let errors = try? self.jsonDecoder.decode([GraphQLErrors].self, from: data).flatMap({ $0.errors }) {
                    if errors.count > 1 {
                        storedError = GraphQLErrors(errors)
                    } else if let error = errors.first {
                        storedError = error
                    }
                }
                self.monitor.operation(with: self.context, didFailWith: storedError)
                result = .failure(storedError)
            }

            queue.async {
                if !self.muteCanceledRequests || !self.alamofireRequest.isCancelled {
                    completion(result)
                }
            }

        }

        return self
    }

}
