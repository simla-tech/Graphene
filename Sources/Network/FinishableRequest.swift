//
//  FinishableRequest.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 03.03.2021.
//

import Foundation
import Alamofire

open class FinishableRequest: CancelableRequest {
    
    private let responseQueue: DispatchQueue
    private let context: OperationContext
    private let loggerDelegateQueue = DispatchQueue(label: "com.graphene.logger", qos: .utility)

    internal let decoderRootKey: String?
    internal let configuration: Client.Configuration
    internal var storedCallback: FinishableCallback

    private(set) public var isSended: Bool = false
    
    internal init<O: GraphQLOperation>(operation: O, client: Client, queue: DispatchQueue, callback: FinishableCallback = FinishableCallback()) {
        
        self.storedCallback = callback
        self.responseQueue = queue
        self.configuration = client.configuration
        self.decoderRootKey = operation.decoderRootKey
                
        var httpHeaders = client.configuration.httpHeaders ?? []
        if !httpHeaders.contains(where: { $0.name.lowercased() == "user-agent" }),
           let version = Bundle(for: Session.self).infoDictionary?["CFBundleShortVersionString"] as? String {
            httpHeaders.add(name: "User-Agent", value: "Graphene /\(version)")
        }
        
        let operationContext = operation.prepareContext()
        
        let dataRequest = client.alamofireSession.upload(
            multipartFormData: { multipartFormData in
                
                let operations = String(format: "{\"query\":\"%@\",\"variables\": %@,\"operationName\":\"%@\"}",
                                        operationContext.query.escaped,
                                        operationContext.jsonVariablesString(prettyPrinted: false) ?? "{}",
                                        operationContext.operationName)
                
                if let data = operations.data(using: .utf8) {
                    multipartFormData.append(data, withName: "operations")
                }
                
                let dictVariables = operationContext.variables.reduce(into: Variables(), { $0[$1.key] = $1.value })
                let uploads = Self.searchUploads(in: dictVariables, currentPath: [])
                let mapStr = uploads.enumerated().map({ (index, upload) -> String in
                    return "\"\(index)\": [\"variables.\(upload.key)\"]"
                }).joined(separator: ",")
                if let data = "{\(mapStr)}".data(using: .utf8) {
                    multipartFormData.append(data, withName: "map")
                }
                for (index, upload) in uploads.enumerated() {
                    multipartFormData.append(upload.value.data,
                                             withName: "\(index)",
                                             fileName: upload.value.name,
                                             mimeType: MimeType(path: upload.value.name).value)
                }
                
            },
            to: client.url,
            usingThreshold: MultipartFormData.encodingMemoryThreshold,
            method: .post,
            headers: httpHeaders,
            requestModifier: client.configuration.requestModifier
        )
        
        self.context = operationContext
        super.init(request: dataRequest)
        
        // Set up validators
        if let customValidation = client.configuration.validation {
            self.dataRequest = self.dataRequest.validate(customValidation)
        }
        self.dataRequest = self.dataRequest.validate(GrapheneStatusValidator.validateStatus(request:response:data:)).validate()
        
    }
    
    private static func searchUploads(in variables: Variables, currentPath: [String]) -> [String: Upload] {
        var result: [String: Upload] = [:]
        for (key, variable) in variables {
            let path = currentPath + [key]
            if let values = variable as? [Upload] {
                let resultPath = path.joined(separator: ".")
                for (index, value) in values.enumerated() {
                    result["\(resultPath).\(index)"] = value
                }
            } else if let value = variable as? Upload {
                let resultPath = path.joined(separator: ".")
                result[resultPath] = value
            } else if let value = variable as? EncodableVariable {
                let newResults = self.searchUploads(in: value.variables, currentPath: path)
                result.merge(newResults, uniquingKeysWith: { aVar, _ in return aVar })
            } else if let value = variable as? Variables {
                let newResults = self.searchUploads(in: value, currentPath: path)
                result.merge(newResults, uniquingKeysWith: { aVar, _ in return aVar })
            }
        }
        return result
    }

    @discardableResult
    public func onFinish(_ completionHandler: @escaping FinishableCallback.Closure) -> CancelableRequest {
        self.storedCallback.finish = completionHandler
        self.fetchRawData({ _ in
            self.performResponseBlock(error: nil) {
                self.storedCallback.finish?()
            }
        })
        return self
    }
    
    internal func fetchRawData(_ completion: @escaping (Result<AFDataResponse<Data?>, Error>) -> Void) {
        
        guard !self.isSended, !self.dataRequest.isCancelled else { return }
        self.isSended = true
                
        self.loggerDelegateQueue.async {
            self.configuration.loggerDelegate?.requestSended(context: self.context)
        }
    
        self.dataRequest.response(queue: .global(qos: .utility)) { response in
            self.loggerDelegateQueue.async {
                self.configuration.loggerDelegate?.responseRecived(statusCode: response.response?.statusCode ?? -999,
                                                                   interval: response.metrics?.taskInterval ?? DateInterval(),
                                                                   context: self.context)
            }
            completion(.success(response))
        }
    }
    
    internal func performResponseBlock(error: Error?, _ block: () -> Void) {
        if self.configuration.muteCanceledRequests,
           ((error?.asAFError?.isExplicitlyCancelledError ?? false) || self.dataRequest.isCancelled) {
            return
        }
        if let error = error {
            self.loggerDelegateQueue.async {
                self.configuration.loggerDelegate?.errorCatched(error, context: self.context)
            }
        }
        self.responseQueue.sync {
            block()
        }
    }
    
}
