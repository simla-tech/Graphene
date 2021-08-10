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

extension Field {
    public func asKey<T: QueryKey>(_ type: T.Type = T.self) -> T {
        return T.init(self)
    }
}
