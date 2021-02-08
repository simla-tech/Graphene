//
//  MultipleQuery.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 04.02.2021.
//

import Foundation

struct MultipleQuery<T: Queryable>: Field {
    
    let key: String
    var childrenFields: [Field] = []
    let arguments: Arguments = [:]

    init(_ key: String, _ builder: QueryBuilder<T>) {
        self.key = key
        let container = QueryContainer<T>(builder)
        self.childrenFields = container.fields
    }

    var fieldString: String {
        return self.childrenFields.map({ $0.fieldString }).joined()
    }
    
}
