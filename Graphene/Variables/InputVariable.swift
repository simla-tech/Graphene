//
//  InputVariable.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 04.02.2021.
//

import Foundation

public struct InputVariable: Argument, Variable {
    
    let schemaType: String
    let value: Variable
    let key: String
    
    init<T: Variable & SchemaType>(key: String = .random(length: 6), _ value: T) {
        self.key = key
        self.value = value
        self.schemaType = type(of: value).schemaType
    }
    
    public var rawValue: String {
        return "$\(self.key)"
    }
    
    public var json: Any? {
        return [self.key: self.value.json]
    }
    
}

private extension String {
    static func random(length: Int) -> String {
      let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
      return String((0..<length).map{ _ in letters.randomElement()! })
    }
}
