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
    
    internal init<O>(operation: O, client: Client, queue: DispatchQueue, callback: FailureableCallback = FailureableCallback()) where O: Operation {
        super.init(operation: operation, client: client, queue: queue, callback: callback)
    }
    
    @discardableResult
    public func onFailure(_ completionHandler: @escaping FailureableCallback.Closure) -> FinishableRequest {
        self.callback?.failure = completionHandler
        self.fetchTargetJson({ result in
            do {
                let (targetJson, gqlError) = try result.get()
                if targetJson == nil {
                    throw gqlError ?? GrapheneError.responseDataIsNull
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
    
    internal func fetchTargetJson(_ completion: @escaping (Result<(Any?, Error?), Error>) -> Void) {
        self.fetchRawJson({ result in
            do {
                let response = try result.get()
                let value = try response.result.get()
                var key = self.configuration.rootResponseKey
                if let rootKey = self.decoderRootKey {
                    key += ".\(rootKey)"
                }
                let result = try? self.extractObject(for: key, from: value)
                let gqlErrors = self.searchGraphQLErrors(in: value)
                completion(.success((result, gqlErrors)))
            } catch {
                completion(.failure(error))
            }
        })
    }
    
    private func searchGraphQLErrors(in response: Any) -> Error? {
        guard let errorsKey = self.configuration.rootErrorsKey, let dict = response as? [AnyHashable: Any], let errorsRaw = dict[errorsKey] as? [Any] else {
            return nil
        }
        let errors = errorsRaw.compactMap({ GraphQLError($0) })
        guard !errors.isEmpty else { return nil }
        if errors.count == 1, let error = errors.first {
            return error
        }
        return GraphQLErrors(errors)
    }
    
    private func extractObject(for key: String, from data: Any) throws -> Any {
        
        var currentObj = data
        
        for pathComponent in key.split(separator: ".").map({ String($0) }) {
            
            if let index = Int(pathComponent) {
                
                if let dict = currentObj as? [Any], index < dict.count {
                    currentObj = dict[index]
                    
                } else {
                    throw GrapheneError.unknownKey(pathComponent)
                }
                
            } else {
                
                if let dict = currentObj as? [String: Any?], let nextObj = dict[pathComponent] {
                    if let nextObj = nextObj {
                        currentObj = nextObj
                    } else {
                        throw GrapheneError.unknownKey(pathComponent)
                    }
                } else {
                    throw GrapheneError.unknownKey(pathComponent)
                }
                
            }
        }
        
        return currentObj
    }
    
}
