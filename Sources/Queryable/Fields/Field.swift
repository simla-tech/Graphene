//
//  Field.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 22.01.2021.
//

import Foundation

public protocol Field {
    var childrenFields: [Field] { get }
    var arguments: Arguments { get }
    func buildField() -> String
}

extension Field {
    
    internal var fragments: Set<AnyFragment> {
        return Self.searchFragments(in: self.childrenFields)
    }
    
    internal var variables: [SomeInputVariable] {
        return Self.searchVariables(in: self)
    }
    
    private static func searchVariables(in field: Field) -> [SomeInputVariable] {
        var result: [SomeInputVariable] = self.searchVariables(in: Array(field.arguments.values))
        for field in field.childrenFields {
            result.append(contentsOf: self.searchVariables(in: field))
        }
        return result
    }
    
    private static func searchVariables(in arguments: [Argument]) -> [SomeInputVariable] {
        var result: [SomeInputVariable] = []
        for argument in arguments {
            switch argument {
            case let inputVariable as SomeInputVariable:
                guard inputVariable.value != nil else {
                    continue
                }
                result.append(inputVariable)
            case let args as Arguments:
                result.append(contentsOf: self.searchVariables(in: Array(args.values)))
            default:
                continue
            }
        }
        return result
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
    
    public func asKey<T: QueryKey>(_ type: T.Type = T.self) -> T {
        return T.init(self)
    }

}
