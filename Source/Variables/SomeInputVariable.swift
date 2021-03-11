//
//  AnyInputVariable.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 04.02.2021.
//

import Foundation

public protocol SomeInputVariable: Argument {
    var schemaType: String { get }
    var value: Variable? { get }
    var key: String { get }
}

extension SomeInputVariable {
    
    public var rawValue: String {
        if self.value != nil {
            return "$\(self.key)"
        } else {
            return "null"
        }
    }
    
}
