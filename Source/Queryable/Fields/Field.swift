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
    
    internal var variables: [InputVariable] {
        return Self.searchVariables(in: self)
    }
    
    private static func searchVariables(in field: Field) -> [InputVariable] {
        var result: [InputVariable] = field.arguments.compactMap({ $0.value as? InputVariable })
        for field in field.childrenFields {
            result.append(contentsOf: self.searchVariables(in: field))
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
