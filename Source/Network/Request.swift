//
//  RequestPerformer.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 28.01.2021.
//

import Foundation
import Alamofire

open class Request<O: GraphQLOperation>: FailureableRequest {
    
    private var callback: SuccessableCallback<O.Result>? {
        return self.storedCallback as? SuccessableCallback<O.Result>
    }
    
    internal init(operation: O, client: Client, queue: DispatchQueue) {
        super.init(operation: operation, client: client, queue: queue, callback: SuccessableCallback<O.Result>())
    }
    
    @discardableResult
    public func onSuccess(_ callback: @escaping SuccessableCallback<O.Result>.Closure) -> FailureableRequest {
        self.callback?.success = callback
        self.fetchDataErrors { result in
            do {
                let (rawData, gqlError) = try result.get()
                
                if let rawData = rawData {
                    var key = self.configuration.rootResponseKey
                    if let rootKey = self.decoderRootKey?.trimmingCharacters(in: .whitespacesAndNewlines), !rootKey.isEmpty {
                        key += ".\(rootKey)"
                    }
                    do {
                        let decoder = JSONDecoder()
                        decoder.dateDecodingStrategy = self.configuration.dateDecodingStrategy
                        decoder.keyDecodingStrategy = self.configuration.keyDecodingStrategy
                        let response = try decoder.decode(O.DecodableResponse.self, from: rawData, keyPath: key, keyPathSeparator: ".")
                        let result = try O.handleSuccess(with: response)
                        self.performResponseBlock(error: nil) {
                            self.callback?.success?(result)
                        }
                    } catch {
                        if let gqlError = gqlError {
                            throw gqlError
                        } else if case .valueNotFound(_, let context) = error as? DecodingError,
                                  context.codingPath.last?.stringValue == self.decoderRootKey {
                            throw GrapheneError.emptyResponse
                        } else {
                            throw error
                        }
                    }
                    
                } else {
                    throw gqlError ?? GrapheneError.emptyResponse
                }
                
            } catch {
                switch O.handleFailure(with: error) {
                case .success(let result):
                    self.performResponseBlock(error: nil) {
                        self.callback?.success?(result)
                    }
                case .failure(let error):
                    self.performResponseBlock(error: error) {
                        self.callback?.failure?(error)
                    }
                }
            }
            self.performResponseBlock(error: nil) {
                self.callback?.finish?()
            }
        }
        return self
    }

}
