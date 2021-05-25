//
//  AnyFragment.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 04.02.2021.
//

import Foundation

internal struct AnyFragment: Field, Hashable {
 
    var schemaType: String
    var fragmentName: String
    var childrenFields: [Field]
    
    func buildField() -> String {
        return "...\(self.fragmentName)"
    }
    
    var arguments: Arguments {
        return [:]
    }
    
    init<T: SomeFragment>(_ fragment: T) {
        self.schemaType = T.schemaType
        self.fragmentName = T.fragmentName
        self.childrenFields = fragment.childrenFields
    }
    
    var fragmentBody: String {
        var result = [String]()
        result.append("fragment \(self.fragmentName) on \(self.schemaType) {")
        result.append(self.childrenFields.map({ $0.buildField() }).joined(separator: ","))
        result.append("}")
        return result.joined()
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.fragmentName)
    }
    
    static func == (lhs: AnyFragment, rhs: AnyFragment) -> Bool {
        lhs.fragmentName == rhs.fragmentName
    }
    
}
