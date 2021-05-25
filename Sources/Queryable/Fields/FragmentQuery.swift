//
//  FragmentQuery.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 10.02.2021.
//

import Foundation

public struct FragmentQuery<T: Fragment>: AnyQuery {
    
    public let name: String
    internal(set) public var alias: String?
    public let arguments: Arguments
    private(set) public var childrenFields: [Field]
    
    public init(_ name: String,
                args: Arguments = [:],
                fragment: T) {
        self.name = name
        self.alias = nil
        self.arguments = args
        self.childrenFields = [AnyFragment(fragment)]
        if T.self is AbstractDecodable.Type {
            self.childrenFields.insert("__typename", at: 0)
        }
    }
    
    public init<Key: CodingKey>(_ key: Key,
                                args: Arguments = [:],
                                fragment: T) {
        self.init(key.stringValue, args: args, fragment: fragment)
    }
    
    public init(alias: String,
                name: String,
                args: Arguments = [:],
                fragment: T) {
        self.init(name, args: args, fragment: fragment)
        self.alias = alias
    }
    
    public init<Key: CodingKey>(alias: Key,
                                name: String,
                                args: Arguments = [:],
                                fragment: T) {
        self.init(name, args: args, fragment: fragment)
        self.alias = alias.stringValue
    }
    
}
