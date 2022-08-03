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

public protocol QuerySchema: OperationSchema {}
extension QuerySchema {
    public static var mode: OperationMode { .query }
}

public protocol MutationSchema: OperationSchema {}
extension MutationSchema {
    public static var mode: OperationMode { .mutation }
}

public protocol SubscriptionSchema: OperationSchema {}
extension SubscriptionSchema {
    public static var mode: OperationMode { .subscription }
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

    // periphery:ignore:parameters decodable
    static func decodePath(of decodable: ResponseValue.Type) -> String?

    static func mapResponse(_ response: Result<ResponseValue, Error>) -> Result<Value, Error>

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

    public static func mapResponse(_ response: Result<ResponseValue, Error>) -> Result<ResponseValue, Error> {
        return response
    }

    internal static var decodePath: String {
        return ["data", Self.decodePath(of: ResponseValue.self)].compactMap({ $0 }).joined(separator: ".")
    }

    public static func buildQuery() -> String {
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
