//
//  MultipleQuery.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 04.02.2021.
//

import Foundation

struct MultipleQuery<T: Queryable>: Field {

    let childrenFields: [Field]
    let arguments: Arguments = [:]

    init(_ builder: QueryBuilder<T>) {
        let container = QueryContainer<T>(builder)
        self.childrenFields = container.fields
    }

    public func buildField() -> String {
        return self.childrenFields.map({ $0.buildField() }).joined()
    }

}
