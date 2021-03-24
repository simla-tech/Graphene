//
//  FailureableRequest.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 03.03.2021.
//

import Foundation
import Alamofire

open class FailureableRequest: FinishableRequest {
    
    private var callback: FailureableCallback? {
        return self.storedCallback as? FailureableCallback
    }
    
    internal init<O>(operation: O, client: Client, queue: DispatchQueue, callback: FailureableCallback = FailureableCallback()) where O: GraphQLOperation {
        super.init(operation: operation, client: client, queue: queue, callback: callback)
    }
    
    @discardableResult
    public func onFailure(_ completionHandler: @escaping FailureableCallback.Closure) -> FinishableRequest {
        self.callback?.failure = completionHandler
        self.fetchDataErrors({ result in
            do {
                let (targetJson, gqlError) = try result.get()
                if let gqlError = gqlError {
                    throw gqlError
                } else if targetJson == nil {
                    throw GrapheneError.responseDataIsNull
                }
            } catch {
                self.performResponseBlock(error: error) {
                    self.callback?.failure?(error)
                }
            }
            self.performResponseBlock(error: nil) {
                self.callback?.finish?()
            }
        })
        return self
    }
    
    internal func fetchDataErrors(_ completion: @escaping (Result<(Data?, Error?), Error>) -> Void) {
        self.fetchRawData({ result in
            do {
                let response = try result.get()
                let value = try response.result.get()
                let gqlErrors = self.searchGraphQLErrors(in: value)
                completion(.success((value, gqlErrors)))
            } catch {
                completion(.failure(error.asAFError?.underlyingError ?? error))
            }
        })
    }
    
    private func searchGraphQLErrors(in response: Data?) -> Error? {
        guard let data = response, let errorsKey = self.configuration.rootErrorsKey else { return nil }
        guard let errors = try? self.configuration.decoder.decode([GraphQLError].self, from: data, keyPath: errorsKey), !errors.isEmpty else {
            return nil
        }
        if errors.count == 1, let error = errors.first {
            return error
        }
        return GraphQLErrors(errors)
    }

}
