//
//  RequestPerformer.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 28.01.2021.
//

import Foundation
import Alamofire

public class CancelableRequest {
    private let requst: Alamofire.DataRequest
    internal init(_ requst: Alamofire.DataRequest) {
        self.requst = requst
    }
    public func cancel(){
        self.requst.cancel()
    }
}

internal struct Request<O: Operation> {
    
    private let operation: O
    private let configuration: Client.Configuration
    private let loggerQueue: DispatchQueue
    private let logger: LoggerProtocol
    internal var initError: Error?
    internal var dataRequest: Alamofire.DataRequest

    internal init(operation: O, client: Client) {
        self.operation = operation
        self.configuration = client.configuration
        self.loggerQueue = client.loggerQueue
        self.logger = client.logger
        
        var httpHeaders = self.configuration.httpHeaders ?? []
        if !httpHeaders.contains(where: { $0.name.lowercased() == "user-agent" }),
           let version = Bundle(for: Client.self).infoDictionary?["CFBundleShortVersionString"] as? String {
            httpHeaders.add(name: "User-Agent", value: "Graphene /\(version)")
        }
        
        var storedError: Error?
        self.dataRequest = client.session.upload(
            multipartFormData: { multipartFormData in
                do {
                    try Self.prepareFormData(multipartFormData, for: operation, logger: client.logger, loggerQueue: client.loggerQueue)
                } catch {
                    storedError = error
                }
            },
            to: client.url,
            usingThreshold: MultipartFormData.encodingMemoryThreshold,
            method: .post,
            headers: httpHeaders,
            requestModifier: self.configuration.requestModifier
        )
        self.initError = storedError
        
        // Set up validators
        if let customValidation = self.configuration.validation {
            self.dataRequest = self.dataRequest.validate(customValidation)
        }
        self.dataRequest = self.dataRequest.validate(ResponseValidator.validateStatus(request:response:data:)).validate()
    }
    
    private func extractObject(for key: String, from data: Any) throws -> Any {
        
        var currentObj = data
        
        for pathComponent in key.split(separator: ".").map({ String($0) }){
            
            if let index = Int(pathComponent) {
                
                if let dict = currentObj as? [Any], index < dict.count {
                    currentObj = dict[index]
                    
                }else{
                    throw GrapheneError.unknownKey(pathComponent)
                }
                
                
            }else{
                
                if let dict = currentObj as? [String: Any?], let nextObj = dict[pathComponent] {
                    if let nextObj = nextObj{
                        currentObj = nextObj
                    }else{
                        throw GrapheneError.unknownKey(pathComponent)
                    }
                }else{
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
                result.merge(newResults, uniquingKeysWith: { a, _ in return a })
            } else if let value = variable as? Variables {
                let newResults = self.searchUploads(in: value, currentPath: path)
                result.merge(newResults, uniquingKeysWith: { a, _ in return a })
            }
        }
        return result
    }

    private static func prepareFormData(_ multipartFormData: MultipartFormData, for operation: O, logger: LoggerProtocol, loggerQueue: DispatchQueue) throws {
        
        let field = operation.asField
        
        // Encode variables
        let variables = field.variables
        let variablesJson = variables.reduce(into: [String : Any](), { $0[$1.key] = $1.value.json })
        let variablesData = try JSONSerialization.data(withJSONObject: variablesJson, options: [])
        let variablesJsonString = String(data: variablesData, encoding: .utf8) ?? "{}"

        // Prepare query string
        var queryStr = type(of: operation).mode.rawValue
        if !variables.isEmpty {
            let variablesStr = variables.map { variable -> String in
                return "$\(variable.key): \(variable.schemaType)!"
            }
            queryStr += "(\(variablesStr.joined(separator: ",")))"
        }
        queryStr += "{\(field.fieldString)}"
        
        let fragments = field.fragments
        if !fragments.isEmpty {
            queryStr += fragments.map({ $0.fragmentBody }).joined()
        }
        
        let operations = String(format: "{\"query\": \"%@\",\"variables\": %@, \"operationName\": null}", queryStr.escaped, variablesJsonString)
        if let data = operations.data(using: .utf8) {
            multipartFormData.append(data, withName: "operations")
        }
        
        // Log request
        loggerQueue.async {
            if !variables.isEmpty {
                guard let variablesLoggerData = try? JSONSerialization.data(withJSONObject: variablesJson, options: [.prettyPrinted, .sortedKeys]) else {
                    return
                }
                logger.requestSended(query: queryStr, variablesJson: String(data: variablesLoggerData, encoding: .utf8))
            } else {
                logger.requestSended(query: queryStr, variablesJson: nil)
            }
        }
        
        // Map & attach uploads
        let dictVariables = variables.reduce(into: Variables(), { $0[$1.key] = $1.value })
        let uploads = self.searchUploads(in: dictVariables, currentPath: [])
        let mapStr = uploads.enumerated().map({ (index, upload) -> String in
            return "\"\(index)\": [\"variables.\(upload.key)\"]"
        }).joined(separator: ",")
        if let data = "{\(mapStr)}".data(using: .utf8) {
            multipartFormData.append(data, withName: "map")
        }
        for (index, upload) in uploads.enumerated() {
            multipartFormData.append(upload.value.data, withName: "\(index)", fileName: upload.value.name, mimeType: MimeType(path: upload.value.name).value)
        }
        
    }
    
}

extension Request {
    
    internal func executeAny(queue: DispatchQueue = .main, completionHandler: @escaping (Result<GrapheneResponse<Any>, Error>) -> Void) {
        self.dataRequest.responseJSON(queue: .global(qos: .utility)) { response in
            do {
                                
                self.loggerQueue.async {
                    self.logger.responseRecived(id: self.operation.operationIdentifier,
                                                statusCode: response.response?.statusCode ?? -999,
                                                interval: response.metrics?.taskInterval ?? DateInterval())
                }
                
                let value = try response.result.get()

                var key = self.configuration.rootResponseKey
                if let rootKey = self.operation.decoderRootKey {
                    key += ".\(rootKey)"
                }
                let result = try? self.extractObject(for: key, from: value)

                var grapheneResponse = GrapheneResponse<Any>(data: result)
                
                if let errorsKey = self.configuration.rootErrorsKey,
                    let dict = value as? [AnyHashable: Any],
                    let errors = dict[errorsKey] as? [Any] {
                    grapheneResponse.errors = errors.compactMap({ GraphQLError($0) })
                }
                
                if self.configuration.muteCanceledRequests, self.dataRequest.isCancelled { return }
                queue.async {
                    completionHandler(.success(grapheneResponse))
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
    }
    
}

extension Request where O.QueryModel: Decodable {

    internal func execute(queue: DispatchQueue = .main,
                          completionHandler: @escaping (Result<GrapheneResponse<O.QueryModel>, Error>) -> Void) {
        
        return self.executeAny(queue: .global(qos: .utility)) { result in
            
            do{
                
                let response = try result.get()
                var mappedData: O.QueryModel?
                
                if let data = response.data as? O.QueryModel {
                    mappedData = data
                }else if let data = response.data {
                    let data = try JSONSerialization.data(withJSONObject: data, options: [])
                    mappedData = try self.configuration.decoder.decode(O.QueryModel.self, from: data)
                }
                
                var newResponse = GrapheneResponse<O.QueryModel>(data: mappedData)
                newResponse.errors = response.errors
                
                if self.configuration.muteCanceledRequests, self.dataRequest.isCancelled { return }
                queue.async {
                    completionHandler(.success(newResponse))
                }
                
            }catch{
                
                if self.configuration.muteCanceledRequests,
                   ((error.asAFError?.isExplicitlyCancelledError ?? false) || self.dataRequest.isCancelled) {
                    return
                }
                queue.async {
                    completionHandler(.failure(error.asAFError?.underlyingError ?? error))
                }
            }
            
        }
        
    }
    
}
