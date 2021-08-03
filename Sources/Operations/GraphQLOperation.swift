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

    func handleResponse(_ response: ExecuteResponse<RootSchema>) throws -> Result

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

    public func handleResponse(_ response: ExecuteResponse<RootSchema>) throws -> RootSchema {
        return try response.get()
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
        let resultVariables = Self.Variables.allKeys.reduce(into: [String: Variable](), {
            $0[$1.identifier] = self.variables[keyPath: $1] as? Variable
        })
        return OperationContext(operationName: Self.operationName,
                                query: Self.buildQuery(),
                                variables: resultVariables)

    }

}
