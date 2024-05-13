//
//  GraphQLOperationData.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 19.05.2021.
//

import Alamofire
import CryptoKit
import Foundation

public protocol OperationContext {
    var mode: OperationMode { get }
    var operationName: String { get }
    var query: String { get }
    var variables: VariablesData? { get }
}

internal struct BatchOperationContextData: OperationContext {

    let mode: OperationMode
    let operationName: String
    let query: String
    let variables: VariablesData?

    init<O: GraphQLOperation>(operation: O.Type, operationContexts: [OperationContextData]) {
        let variablesJson = operationContexts
            .map(\.variablesDict)
            .filter({ !$0.isEmpty })
            .enumerated()
            .reduce(into: [String: Any?](), {
                for variable in $1.element {
                    $0["\($1.offset)-\(variable.key)"] = variable.value.json
                }
            })
        self.mode = operation.RootSchema.mode
        self.operationName = "Batch_" + O.operationName
        self.query = O.buildQuery()
        self.variables = VariablesData(json: variablesJson)
    }

}

internal struct OperationContextData: OperationContext {

    let mode: OperationMode
    let operationName: String
    let query: String
    let variables: VariablesData?
    fileprivate let variablesDict: [String: Variable]

    init<O: GraphQLOperation>(operation: O) {
        let variables = O.Variables.allKeys.enumerated().reduce(into: [String: Variable](), { dict, item in
            let (index, keyPath) = item
            guard let value = operation.variables[keyPath: keyPath] as? Variable else { return }
            if !operation.variables.encodeNull, value.json == nil { return }
            dict[argumentIdentifier(for: index)] = value
        })
        self.init(operation: O.self, variables: variables)
    }

    init<O: GraphQLOperation>(operation: O.Type, variables: [String: Variable]) {
        self.mode = O.RootSchema.mode
        self.operationName = O.operationName
        self.query = O.buildQuery()
        self.variablesDict = variables
        self.variables = VariablesData(
            json: variables.reduce(into: [String: Any?](), {
                $0[$1.key] = $1.value.json
            })
        )
    }

    internal func getOperationJSON() -> String {
        let variablesString: String? = {
            if let variablesData = self.variables?.data {
                return String(decoding: variablesData, as: UTF8.self)
            }
            return nil
        }()
        return String(
            format: "{\"query\":\"%@\",\"variables\": %@,\"operationName\":\"%@\"}",
            self.query.escaped,
            variablesString ?? "{}",
            self.operationName
        )
    }

    internal func getUploads() -> [String: Upload] {
        let dictVariables = self.variablesDict.reduce(into: Variables(), { $0["variables.\($1.key)"] = $1.value })
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
                result.merge(newResults, uniquingKeysWith: { aVar, _ in aVar })
            } else if let value = variable as? Variables {
                let newResults = self.searchUploads(in: value, currentPath: path)
                result.merge(newResults, uniquingKeysWith: { aVar, _ in aVar })
            }
        }
        return result
    }

}

public struct VariablesData {
    public let json: [String: Any?]
    public let data: Data
    public let hash: String

    public var prettyJSON: String? {
        if let data = try? JSONSerialization.data(
            withJSONObject: json,
            options: [.sortedKeys, .prettyPrinted]
        ) {
            return String(decoding: data, as: UTF8.self)
        }
        return nil
    }
}

extension VariablesData: Hashable {

    public static func == (lhs: VariablesData, rhs: VariablesData) -> Bool {
        lhs.hash == rhs.hash
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.hash)
    }

}

extension VariablesData {
    init?(json: [String: Any?]) {
        guard !json.isEmpty else { return nil }
        do {
            let data = try JSONSerialization.data(
                withJSONObject: json,
                options: [.sortedKeys]
            )
            self.json = json
            self.data = data
            self.hash = SHA256.hash(data: data)
                .compactMap({ String(format: "%02x", $0) })
                .joined()
        } catch {
            assertionFailure(error.localizedDescription)
            return nil
        }
    }
}
