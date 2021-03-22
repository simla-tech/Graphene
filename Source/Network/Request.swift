//
//  RequestPerformer.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 28.01.2021.
//

import Foundation
import Alamofire

open class Request<ResponseType: Decodable>: FailureableRequest {
    
    private var callback: SuccessableCallback<ResponseType>? {
        return self.storedCallback as? SuccessableCallback<ResponseType>
    }
    
    internal init<O>(operation: O, client: Client, queue: DispatchQueue) where O: Operation {
        super.init(operation: operation, client: client, queue: queue, callback: SuccessableCallback<ResponseType>())
    }
    
    @discardableResult
    public func onSuccess(_ callback: @escaping SuccessableCallback<ResponseType>.Closure) -> FailureableRequest {
        self.callback?.success = callback
        self.fetchDataErrors { result in
            do {
                let (rawData, gqlError) = try result.get()
                
                if let rawData = rawData {
                    let decoder = JSONDecoder()
                    var key = self.configuration.rootResponseKey
                    if let rootKey = self.decoderRootKey?.trimmingCharacters(in: .whitespacesAndNewlines), !rootKey.isEmpty {
                        key += ".\(rootKey)"
                    }
                    do {
                        let result = try decoder.decode(ResponseType.self, from: rawData, keyPath: key, keyPathSeparator: ".")
                        self.performResponseBlock(error: nil) {
                            self.callback?.success?(result)
                        }
                    } catch {
                        throw gqlError ?? error
                    }
                    
                } else {
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
        }
        return self
    }
    
    private func decodeResponse(from targetJson: Any?, gqlError: Error?) throws -> ResponseType {
        var mappedData: ResponseType?
        if let data = targetJson as? ResponseType {
            mappedData = data
        } else if let data = targetJson {
            do {
                let data = try JSONSerialization.data(withJSONObject: data, options: [])
                mappedData = try self.configuration.decoder.decode(ResponseType.self, from: data)
            } catch {
                if !(error is DecodingError), let gqlError = gqlError {
                    throw gqlError
                }
                throw error
            }
        }
        guard let successData = mappedData else {
            throw gqlError ?? GrapheneError.responseDataIsNull
        }
        return successData
    }

}
