//
//  SomeFragment.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 19.03.2021.
//

import Foundation

public protocol SomeFragment: SchemaType {
    static var fragmentName: String { get }
    static var childrenFields: [Field] { get }
}

extension SomeFragment {
    public static var fragmentName: String {
        var name = String(describing: self)
        if String(name.suffix(8)).lowercased() != "fragment" {
            name += "Fragment"
        }
        return name
    }
}
