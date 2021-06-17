//
//  BaseQuery.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 22.01.2021.
//

import Foundation

public struct Query<T>: AnyQuery {

    public let name: String
    public let arguments: Arguments
    internal(set) public var alias: String?
    private(set) public var childrenFields: [Field]

    public init(_ name: String, args: Arguments = [:]) {
        self.name = name
        self.alias = nil
        self.arguments = args
        self.childrenFields = []
    }

    public init(alias: String, name: String, args: Arguments = [:]) {
        self.init(name, args: args)
        self.alias = alias
    }

    public init<Key: CodingKey>(_ key: Key, args: Arguments = [:]){
        self.init(key.stringValue, args: args)
    }

    public init<Key: CodingKey>(alias: Key, name: String, args: Arguments = [:]) {
        self.init(alias: alias.stringValue, name: name, args: args)
    }

}

extension Query where T: Queryable {

    public init(_ name: String,
                args: Arguments = [:],
                _ builder: @escaping QueryBuilder<T>) {
        self.init(name, args: args)
        let container = QueryContainer<T>(builder)
        self.childrenFields = container.fields
        if T.self is AbstractDecodable.Type {
            self.childrenFields.insert("__typename", at: 0)
        }
    }
    
    public init(alias: String,
                name: String,
                args: Arguments = [:],
                _ builder: @escaping QueryBuilder<T>) {
        self.init(name, args: args, builder)
        self.alias = alias
    }
    
    public init<Key: CodingKey>(_ key: Key,
                                args: Arguments = [:],
                                _ builder: @escaping QueryBuilder<T>) {
        self.init(key.stringValue, args: args, builder)
    }
    
    public init<Key: CodingKey>(alias: Key,
                                name: String,
                                args: Arguments = [:],
                                _ builder: @escaping QueryBuilder<T>) {
        self.init(alias: alias.stringValue, name: name, args: args, builder)
    }
    
}
