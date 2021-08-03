//
//  GraphQLOperationData.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 19.05.2021.
//

import Foundation
import Alamofire

public protocol OperationContext {
    var operationName: String { get }
    var query: String { get }
    func variables(prettyPrinted: Bool) -> String?
}

internal struct BatchOperationContextData: OperationContext {

    var operationName: String
    var query: String
    private let variables: [[String: Variable]]

    init<O: GraphQLOperation>(operation: O.Type, operationContexts: [OperationContextData]) {
        self.operationName = "Batch_" + O.operationName
        self.query = O.buildQuery()
        self.variables = operationContexts.filter({ !$0.variables.isEmpty }).map({ $0.variables })
    }

    func variables(prettyPrinted: Bool) -> String? {
        guard !self.variables.isEmpty else { return nil }

        let variablesJson = self.variables.flatMap({ $0 }).reduce(into: [String: Any?](), {
            $0[$1.key] = $1.value.json
        })

        guard let variablesData = try? JSONSerialization.data(withJSONObject: variablesJson,
                                                              options: prettyPrinted ? [.prettyPrinted, .sortedKeys] : []) else {
            return nil
        }

        return String(data: variablesData, encoding: .utf8)
    }

}

internal struct OperationContextData: OperationContext {

    public let operationName: String
    public let query: String
    fileprivate let variables: [String: Variable]

    init<O: GraphQLOperation>(operation: O) {
        self.operationName = O.operationName
        self.query = O.buildQuery()
        self.variables = O.Variables.allKeys.reduce(into: [String: Variable](), {
            $0[$1.identifier] = operation.variables[keyPath: $1] as? Variable
        })
    }

    public func variables(prettyPrinted: Bool = false) -> String? {

        guard !self.variables.isEmpty else { return nil }

        let variablesJson = self.variables.reduce(into: [String: Any?](), {
            $0[$1.key] = $1.value.json
        })

        guard let variablesData = try? JSONSerialization.data(withJSONObject: variablesJson,
                                                              options: prettyPrinted ? [.prettyPrinted, .sortedKeys] : []) else {
            return nil
        }

        return String(data: variablesData, encoding: .utf8)

    }

    internal func getOperationJSON() -> String {
        return String(format: "{\"query\":\"%@\",\"variables\": %@,\"operationName\":\"%@\"}",
                      self.query.escaped,
                      self.variables(prettyPrinted: false) ?? "{}",
                      self.operationName)
    }

    internal func getUploads() -> [String: Upload] {
        let dictVariables = self.variables.reduce(into: Variables(), { $0[$1.key] = $1.value })
        return self.searchUploads(in: dictVariables, currentPath: [])
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
