//
//  InputVariable.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 09.03.2021.
//

import Foundation

public struct InputVariable<T: Variable & SchemaType>: SomeInputVariable {
    
    public let schemaType: String
    public let value: Variable?
    public let key: String
    
    public init(key: String? = nil, _ value: T?) {
        self.key = key ?? .random(length: 12)
        self.value = value
        self.schemaType = T.schemaType
    }
    
}

private extension String {
    static func random(length: Int) -> String {
      let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
      return String((0..<length).map { _ in letters.randomElement()! })
    }
}
