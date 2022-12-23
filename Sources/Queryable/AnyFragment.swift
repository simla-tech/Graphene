//
//  AnyFragment.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 04.02.2021.
//

import Foundation

internal struct AnyFragment: Field, Hashable {

    var fragmentType: String
    var fragmentName: String
    var childrenFields: [Field]

    func buildField() -> String {
        "...\(self.fragmentName)"
    }

    init<F: Fragment>(_ fragment: F.Type) {
        self.fragmentType = F.fragmentType
        self.fragmentName = F.fragmentName
        let container = QueryContainer<F.FragmentModel>(F.buildQuery(with:))
        self.childrenFields = container.fields
    }

    var fragmentBody: String {
        var result = [String]()
        result.append("fragment \(self.fragmentName) on \(self.fragmentType) {")
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
