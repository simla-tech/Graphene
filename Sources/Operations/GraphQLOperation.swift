//
//  GraphQLOperation.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 22.01.2021.
//

import Foundation

public protocol QueryVariables {
    var encodeNull: Bool { get }
    static var allKeys: [PartialKeyPath<Self>] { get }
}

public extension QueryVariables {
    var encodeNull: Bool { false }
}

public protocol OperationSchema: Queryable {
    static var mode: OperationMode { get }
}

public protocol QuerySchema: OperationSchema { }
public extension QuerySchema {
    static var mode: OperationMode { .query }
}

public protocol MutationSchema: OperationSchema { }
public extension MutationSchema {
    static var mode: OperationMode { .mutation }
}

public protocol SubscriptionSchema: OperationSchema { }
public extension SubscriptionSchema {
    static var mode: OperationMode { .subscription }
}

public struct DefaultVariables: QueryVariables {
    public static let allKeys: [PartialKeyPath<Self>] = []
}

/// Basic operation protocol
public protocol GraphQLOperation {

    /// Type associated with some Queryable model
    associatedtype Value
    associatedtype ResponseValue: Decodable
    associatedtype RootSchema: OperationSchema
    associatedtype Variables: QueryVariables

    var variables: Variables { get }

    static func decodePath(of decodable: ResponseValue.Type) -> String?

    static func mapResponse(_ response: Result<ResponseValue, Error>) -> Result<Value, Error>

    static var operationName: String { get }

    static func buildQuery(with builder: QueryContainer<RootSchema>)

}

public extension GraphQLOperation {

    var variables: DefaultVariables {
        DefaultVariables()
    }

    static var operationName: String {
        String(describing: self)
    }

    static func mapResponse(_ response: Result<ResponseValue, Error>) -> Result<ResponseValue, Error> {
        response
    }

    internal static var decodePath: String {
        ["data", Self.decodePath(of: ResponseValue.self)].compactMap({ $0 }).joined(separator: ".")
    }

    static func buildQuery() -> String {
        var query = "\(RootSchema.mode.rawValue) \(self.operationName)"
        if !Variables.allKeys.isEmpty {
            let variablesStrCompact = Variables.allKeys.map { variable -> String in
                "$\(variable.identifier):\(variable.variableType)"
            }
            query += "(\(variablesStrCompact.joined(separator: ",")))"
        }
        let container = QueryContainer<RootSchema>(self.buildQuery)
        query += " {\(container.fields.map({ $0.buildField() }).joined(separator: ","))}"
        let fragments = self.searchFragments(in: container.fields)
        if !fragments.isEmpty {
            query += fragments.map(\.fragmentBody).joined()
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
