//
//  RequestPerformer.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 28.01.2021.
//

import Foundation
import Alamofire

public struct Request<ResponseType: Decodable> {
    
    private let configuration: Client.Configuration
    private let loggerQueue: DispatchQueue
    private let logger: LoggerProtocol
    private var initError: Error?
    internal var dataRequest: Alamofire.DataRequest
    
    public var operationName: String
    public var query: String
    public var variables: String?
    public var decoderRootKey: String?
    
    internal init<O: Operation>(operation: O, client: Client) {
        
        self.operationName = O.operationName
        self.decoderRootKey = operation.decoderRootKey
        self.configuration = client.configuration
        self.loggerQueue = client.loggerQueue
        self.logger = client.logger
        
        let field = operation.asField
        
        // Encode variables
        let variables = field.variables
        var variablesJsonString = "{}"
        if !variables.isEmpty {
            let variablesJson = variables.reduce(into: [String: Any](), { $0[$1.key] = $1.value.json })
            do {
                let variablesData = try JSONSerialization.data(withJSONObject: variablesJson, options: [])
                variablesJsonString = String(data: variablesData, encoding: .utf8) ?? "{}"
            } catch {
                self.initError = error
            }
            if let variablesDataPretty = try? JSONSerialization.data(withJSONObject: variablesJson, options: [.prettyPrinted, .sortedKeys]) {
                self.variables = String(data: variablesDataPretty, encoding: .utf8)
            }
        }
        
        // Prepare query string
        self.query = "\(O.mode.rawValue) \(O.operationName)"
        if !variables.isEmpty {
            let variablesStr = variables.map { variable -> String in
                return "$\(variable.key): \(variable.schemaType)!"
            }
            self.query += "(\(variablesStr.joined(separator: ",")))"
        }
        self.query += " {\(field.buildField())}"
        
        let fragments = field.fragments
        if !fragments.isEmpty {
            self.query += fragments.map({ $0.fragmentBody }).joined()
        }
        
        var httpHeaders = client.configuration.httpHeaders ?? []
        if !httpHeaders.contains(where: { $0.name.lowercased() == "user-agent" }),
           let version = Bundle(for: Client.self).infoDictionary?["CFBundleShortVersionString"] as? String {
            httpHeaders.add(name: "User-Agent", value: "Graphene /\(version)")
        }
        
        let operations = String(format: "{\"query\": \"%@\",\"variables\": %@, \"operationName\": null}", self.query.escaped, variablesJsonString)
        
        self.dataRequest = client.session.upload(
            multipartFormData: { multipartFormData in
                if let data = operations.data(using: .utf8) {
                    multipartFormData.append(data, withName: "operations")
                }
                
                // Map & attach uploads
                let dictVariables = variables.reduce(into: Variables(), { $0[$1.key] = $1.value })
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
        
        // Set up validators
        if let customValidation = client.configuration.validation {
            self.dataRequest = self.dataRequest.validate(customValidation)
        }
        self.dataRequest = self.dataRequest.validate(ResponseValidator.validateStatus(request:response:data:)).validate()
        
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

}

extension Request {
    
    @discardableResult
    public func perform(queue: DispatchQueue = .main, completionHandler: @escaping (Result<ResponseType, Error>) -> Void) -> CancelableRequest {
        if let initError = self.initError {
            queue.async {
                completionHandler(.failure(initError))
            }
            return .init(self.dataRequest)
        }
        self.loggerQueue.async {
            self.logger.requestSended(operation: self.operationName, query: self.query, variablesJson: self.variables)
        }
        self.dataRequest.responseJSON(queue: .global(qos: .utility)) { response in
            do {
                                
                self.loggerQueue.async {
                    self.logger.responseRecived(operation: self.operationName,
                                                statusCode: response.response?.statusCode ?? -999,
                                                interval: response.metrics?.taskInterval ?? DateInterval())
                }
                
                let value = try response.result.get()

                var key = self.configuration.rootResponseKey
                if let rootKey = self.decoderRootKey {
                    key += ".\(rootKey)"
                }
                let result = try? self.extractObject(for: key, from: value)

                let checkGraphQLErrors = {
                    if let errorsKey = self.configuration.rootErrorsKey,
                        let dict = value as? [AnyHashable: Any],
                        let errorsRaw = dict[errorsKey] as? [Any] {
                        let errors = errorsRaw.compactMap({ GraphQLError($0) })
                        if !errors.isEmpty {
                            if errors.count == 1, let error = errors.first {
                                throw error
                            }
                            throw GraphQLErrors(errors)
                        }
                    }
                }
                
                var mappedData: ResponseType?
                if let data = result as? ResponseType {
                    mappedData = data
                } else if let data = result {
                    do {
                        let data = try JSONSerialization.data(withJSONObject: data, options: [])
                        mappedData = try self.configuration.decoder.decode(ResponseType.self, from: data)
                    } catch {
                        if !(error is DecodingError) {
                            try checkGraphQLErrors()
                        }
                        throw error
                    }
                }
                
                guard let successData = mappedData else {
                    try checkGraphQLErrors()
                    throw GrapheneError.responseDataIsNull
                }
                
                if self.configuration.muteCanceledRequests, self.dataRequest.isCancelled { return }
                queue.async {
                    completionHandler(.success(successData))
                }
                
            } catch {
                if self.configuration.muteCanceledRequests,
                   ((error.asAFError?.isExplicitlyCancelledError ?? false) || self.dataRequest.isCancelled) {
                    return
                }
                queue.async {
                    completionHandler(.failure(error.asAFError?.underlyingError ?? error))
                }
            }
        }
        return .init(self.dataRequest)
    }
    
}
