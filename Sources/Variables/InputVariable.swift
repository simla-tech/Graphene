//
//  InputVariable.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 09.03.2021.
//

import Foundation

public struct InputVariable<T: Variable>: SomeInputVariable {
    
    public let schemaType: String
    public let value: Variable?
    public let key: String
    
    private init(key: String?, _ value: T?, schemaType: String) {
        self.key = key ?? .random(length: 12)
        self.value = value
        self.schemaType = schemaType
    }
    
    public init(key: String? = nil, _ value: T) where T: SchemaType {
        self.init(key: key, value, schemaType: T.schemaType + "!")
    }
    
    public init(key: String? = nil, _ value: T?) where T: SchemaType {
        self.init(key: key, value, schemaType: T.schemaType)
    }
    
    public init<Z: SchemaType>(key: String? = nil, _ value: T) where T == [Z] {
        self.init(key: key, value, schemaType: "[\(Z.schemaType)!]!")
    }
    
    public init<Z: SchemaType>(key: String? = nil, _ value: T?) where T == [Z] {
        self.init(key: key, value, schemaType: "[\(Z.schemaType)!]")
    }
    
    public init<Z: SchemaType>(key: String? = nil, _ value: T) where T == [Z?] {
        self.init(key: key, value, schemaType: "[\(Z.schemaType)]!")
    }
    
    public init<Z: SchemaType>(key: String? = nil, _ value: T?) where T == [Z?] {
        self.init(key: key, value, schemaType: "[\(Z.schemaType)]")
    }
    
}

internal extension String {
    static func random(length: Int) -> String {
      let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
      return String((0..<length).map { _ in letters.randomElement()! })
    }
}
