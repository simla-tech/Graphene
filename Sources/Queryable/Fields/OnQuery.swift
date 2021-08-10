//
//  OnQuery.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 03.02.2021.
//

import Foundation

public struct On<T: Queryable>: Field {

    public var childrenFields: [Field]

    public init(_ type: T.Type = T.self, _ builder: @escaping QueryBuilder<T>) {
        let container = QueryContainer<T>(builder)
        self.childrenFields = container.fields
    }

    public func buildField() -> String {
        var res = [String]()
        res.append("...on \(T.schemaType) {")
        res.append(self.childrenFields.map({ $0.buildField() }).joined(separator: ","))
        res.append("}")
        return res.joined()
    }

}
