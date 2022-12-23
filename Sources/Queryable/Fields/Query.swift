//
//  BaseQuery.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 22.01.2021.
//

import Foundation

public struct Query: Field {

    public let name: String
    public let arguments: AnyArguments
    public internal(set) var alias: String?
    public private(set) var childrenFields: [Field]

    public init(_ name: String, args: AnyArguments = [:]) {
        self.name = name
        self.alias = nil
        self.arguments = args
        self.childrenFields = []
    }

    public init(alias: String, name: String, args: AnyArguments = [:]) {
        self.init(name, args: args)
        self.alias = alias
    }

    public init<Key: CodingKey>(_ key: Key, args: AnyArguments = [:]) {
        self.init(key.stringValue, args: args)
    }

    public init<Key: CodingKey>(alias: Key, name: String, args: AnyArguments = [:]) {
        self.init(alias: alias.stringValue, name: name, args: args)
    }

    public func buildField() -> String {
        var res = [String]()

        if let alias = self.alias {
            res.append("\(alias):\(self.name)")
        } else {
            res.append(self.name)
        }
        let nonNullArgs = self.arguments.compactMapValues({ $0?.rawValue })
        if !nonNullArgs.isEmpty {
            let argumentsStr = nonNullArgs
                .map({ "\($0.key):\($0.value)" })
                .joined(separator: ",")
            res.append("(\(argumentsStr))")
        }

        if !self.childrenFields.isEmpty {
            res.append("{\(self.childrenFields.map({ $0.buildField() }).joined(separator: ","))}")
        }

        return res.joined()
    }

}

public extension Query {

    init<Q: Queryable>(_ name: String, args: AnyArguments = [:], _ builder: @escaping QueryBuilder<Q>) {
        self.init(name, args: args)
        let container = QueryContainer<Q>(builder)
        self.childrenFields = container.fields
        if Q.self is AbstractDecodable.Type {
            self.childrenFields.insert(Query("__typename"), at: 0)
        }
    }

    init<Q: Queryable>(alias: String, name: String, args: AnyArguments = [:], _ builder: @escaping QueryBuilder<Q>) {
        self.init(name, args: args, builder)
        self.alias = alias
    }

    init<Key: CodingKey, Q: Queryable>(_ key: Key, args: AnyArguments = [:], _ builder: @escaping QueryBuilder<Q>) {
        self.init(key.stringValue, args: args, builder)
    }

    init<Q: Queryable>(
        alias: some CodingKey,
        name: String,
        args: AnyArguments = [:],
        _ builder: @escaping QueryBuilder<Q>
    ) {
        self.init(alias: alias.stringValue, name: name, args: args, builder)
    }

}

public extension Query {

    init<F: Fragment>(_ name: String, args: AnyArguments = [:], fragment: F.Type) {
        self.init(name, args: args)
        self.childrenFields = [AnyFragment(fragment)]
        if F.self is AbstractDecodable.Type {
            self.childrenFields.insert(Query("__typename"), at: 0)
        }
    }

    init<F: Fragment>(alias: String, name: String, args: AnyArguments = [:], fragment: F.Type) {
        self.init(name, args: args, fragment: fragment)
        self.alias = alias
    }

    init<Key: CodingKey, F: Fragment>(_ key: Key, args: AnyArguments = [:], fragment: F.Type) {
        self.init(key.stringValue, args: args, fragment: fragment)
    }

    init<Key: CodingKey, F: Fragment>(alias: Key, name: String, args: AnyArguments = [:], fragment: F.Type) {
        self.init(alias: alias.stringValue, name: name, args: args, fragment: fragment)
    }

}
