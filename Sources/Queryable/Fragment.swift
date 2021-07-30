//
//  Fragment.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 04.02.2021.
//

import Foundation

public protocol Fragment {
    associatedtype FragmentModel: Queryable
    static var fragmentName: String { get }
    static func buildQuery(with builder: QueryContainer<FragmentModel>)
}

extension Fragment {
    public static var fragmentName: String {
        var name = String(describing: self)
        if String(name.suffix(8)).lowercased() != "fragment" {
            name += "Fragment"
        }
        return name
    }
}
