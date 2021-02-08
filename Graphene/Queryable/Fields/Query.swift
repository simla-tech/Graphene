//
//  BaseQuery.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 22.01.2021.
//

import Foundation

public struct Query<T: Queryable>: Field {

    public let name: String
    internal(set) public var alias: String?
    public let arguments: Arguments
    private(set) public var childrenFields: [Field]
       
    public init(_ name: String, alias: String? = nil, on type: T.Type? = nil, args: Arguments = [:], _ builder: @escaping QueryBuilder<T>) {
        self.name = name
        self.alias = alias
        self.arguments = args
        let container = QueryContainer<T>(builder)
        self.childrenFields = container.fields
        if T.self is AbstractDecodable.Type {
            self.childrenFields.insert("__typename", at: 0)
        }
    }
    
    public init<Key: CodingKey>(_ key: Key, alias: String? = nil, on type: T.Type? = nil, args: Arguments = [:], _ builder: @escaping QueryBuilder<T>) {
        self.init(key.stringValue, alias: alias, on: type, args: args, builder)
    }
    
    public init<F: Fragment>(_ name: String, alias: String? = nil, args: Arguments = [:], fragment: F.Type) where F.FragmentModel == T {
        self.init(name, alias: alias, args: args) { builder in
            builder += .fragment(fragment)
        }
    }
    
    public init<Key: CodingKey, F: Fragment>(_ key: Key, alias: String? = nil, args: Arguments = [:], fragment: F.Type) where F.FragmentModel == T {
        self.init(key.stringValue, alias: alias, args: args, fragment: fragment)
    }
    
}

extension Query {

    public var fieldString: String {
        var res = [String]()
        
        if let alias = self.alias {
            res.append("\(alias): \(self.name)")
        } else {
            res.append(self.name)
        }
        if !self.arguments.isEmpty {
            let argumentsStr = self.arguments
                .map({ "\($0): \($1.rawValue)" })
                .joined(separator: ",")
            res.append("(\(argumentsStr))")
        }
        
        if !self.childrenFields.isEmpty {
            res.append("{\(self.childrenFields.map({ $0.fieldString }).joined(separator: ","))}")
        }
        
        return res.joined()
    }
    
}
