//
//  GraphQLOperation.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 22.01.2021.
//

import Foundation

public protocol QueryVariables {
    static var allKeys: [PartialKeyPath<Self>] { get }
}

public protocol Schema: Queryable, Decodable {
    static var mode: OperationMode { get }
}

public struct DefaultVariables: QueryVariables {
    public static let allKeys: [PartialKeyPath<Self>] = []
}

/// Basic operation protocol
public protocol GraphQLOperation {

    /// Type associated with some Queryable model
    associatedtype Result
    associatedtype RootSchema: Schema
    associatedtype Variables: QueryVariables

    var variables: Variables { get }

    func handleSuccess(with result: RootSchema) throws -> Result

    func handleFailure(with error: Error) -> Swift.Result<Result, Error>

    static var operationName: String { get }

    static func buildQuery(with builder: QueryContainer<RootSchema>)

}

extension GraphQLOperation {

    public var variables: DefaultVariables {
        return DefaultVariables()
    }

    public static var operationName: String {
        return String(describing: self)
    }

    public func handleFailure(with error: Error) -> Swift.Result<Result, Error> {
        return .failure(error)
    }

    public func handleSuccess(with result: RootSchema) throws -> RootSchema {
        return result
    }

    internal static func buildQuery() -> String {
        var query = "\(RootSchema.mode.rawValue) \(self.operationName)"
        if !Variables.allKeys.isEmpty {
            let variablesStrCompact = Variables.allKeys.map { variable -> String in
                return "$\(variable.identifier):\(variable.variableType)"
            }
            query += "(\(variablesStrCompact.joined(separator: ",")))"
        }
        let container = QueryContainer<RootSchema>(self.buildQuery)
        query += " {\(container.fields.map({ $0.buildField() }).joined(separator: ","))}"
        let fragments = self.searchFragments(in: container.fields)
        if !fragments.isEmpty {
            query += fragments.map({ $0.fragmentBody }).joined()
        }
        return query
    }

    private static func searchFragments(in fields: [Field]) -> Set<AnyFragment> {
        var result: Set<AnyFragment> = []
        for field in fields {
            if let fragment = field as? AnyFragment {
                result.insert(fragment)
            }
            result.formUnion(self.searchFragments(in: field.childrenFields))
        }
        return result
    }

}

extension GraphQLOperation {

    public func prepareContext() -> OperationContext {
        var resultVariables: [String: Variable] = [:]
        Self.Variables.allKeys.forEach({ keyPath in
            if let value = self.variables[keyPath: keyPath] as? Variable {
                print(keyPath.identifier, value)
                resultVariables[keyPath.identifier] = value
            } else {
                print(keyPath.identifier, "none")
                resultVariables[keyPath.identifier] = String?.none
            }
        })
        return OperationContext(operationName: Self.operationName,
                                query: Self.buildQuery(),
                                variables: resultVariables)

    }

}
