//
//  GraphQLOperationData.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 19.05.2021.
//

import Foundation
import Alamofire

public struct OperationContext {

    public let operationName: String
    public let query: String
    public let variables: [String: Variable]

    public func jsonVariablesString(prettyPrinted: Bool = false) -> String? {

        guard !self.variables.isEmpty else { return nil }

        let variablesJson = self.variables.reduce(into: [String: Any?](), {
            // if let value = $1.value { $0[$1.key] = value.json }
            $0[$1.key] = $1.value.json
        })

        guard let variablesData = try? JSONSerialization.data(withJSONObject: variablesJson,
                                                              options: prettyPrinted ? [.prettyPrinted, .sortedKeys] : []) else {
            return nil
        }

        return String(data: variablesData, encoding: .utf8)

    }

    internal func getMultipartFormData() -> MultipartFormData {
        let multipartFormData = MultipartFormData(fileManager: .default, boundary: nil)

        let operations = String(format: "{\"query\":\"%@\",\"variables\": %@,\"operationName\":\"%@\"}",
                                self.query.escaped,
                                self.jsonVariablesString(prettyPrinted: false) ?? "{}",
                                self.operationName)

        if let data = operations.data(using: .utf8) {
            multipartFormData.append(data, withName: "operations")
        }

        let dictVariables = self.variables.reduce(into: Variables(), { $0[$1.key] = $1.value })
        let uploads = self.searchUploads(in: dictVariables, currentPath: [])
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
        return multipartFormData
    }

    private func searchUploads(in variables: Variables, currentPath: [String]) -> [String: Upload] {
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
