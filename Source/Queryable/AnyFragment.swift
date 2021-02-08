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
    
    var fieldString: String {
        return "...\(self.fragmentName)"
    }
    
    var arguments: Arguments {
        return [:]
    }
    
    init<F: Fragment>(_ fragment: F.Type) {
        self.schemaType = fragment.schemaType
        self.fragmentName = fragment.fragmentName
        let container = QueryContainer<F.FragmentModel>(fragment.fragmentQuery)
        self.childrenFields = container.fields
    }
    
    var fragmentBody: String {
        var result = [String]()
        result.append("fragment \(self.fragmentName) on \(self.schemaType) {")
        result.append(self.childrenFields.map({ $0.fieldString }).joined(separator: ","))
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
