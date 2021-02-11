//
//  Alias.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 10.02.2021.
//

import Foundation

public struct Alias: AnyQuery {

    public let name: String
    public let alias: String?
    public let arguments: Arguments = [:]
    public let childrenFields: [Field] = []
       
    public init(_ alias: String, source: String) {
        self.name = source
        self.alias = alias
    }
    
    public init<Key: CodingKey>(_ alias: Key, source: String) {
        self.name = source
        self.alias = alias.stringValue
    }
    
}
