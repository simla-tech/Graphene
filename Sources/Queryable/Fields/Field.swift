//
//  Field.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 22.01.2021.
//

import Foundation

public protocol Field {
    var childrenFields: [Field] { get }
    func buildField() -> String
}

public extension Field {
    func asKey<T: QueryKey>(_ type: T.Type = T.self) -> T {
        T(self)
    }
}
