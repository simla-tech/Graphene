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
    public func perform(queue: DispatchQueue = .main, completion: @escaping (Result<O.Value, Error>) -> Void) -> CancellableOperationRequest {

        self.monitor.operation(willExecuteWith: self.context)

        let decoder = GraphQLDecoder(decodePath: O.decodePath, jsonDecoder: self.jsonDecoder)
        self.alamofireRequest.responseDecodable(of: O.ResponseValue.self,
                                      queue: .global(qos: .utility),
                                      decoder: decoder) { [weak self] dataResponse in

            guard let `self` = self else { return }

            if self.muteCanceledRequests, dataResponse.error?.isExplicitlyCancelledError ?? false {
                return
            }

            self.monitor.operation(with: self.context,
                                   didFinishWith: dataResponse.response?.statusCode ?? -999,
                                   interval: dataResponse.metrics?.taskInterval ?? .init())

            let result = O.mapResponse(dataResponse.result.mapError({ $0.underlyingError ?? $0 }))
            switch result {
            case .failure(let error):
                self.monitor.operation(with: self.context, didFailWith: error)
            default:
                break
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
