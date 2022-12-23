//
//  QueryKey.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 03.02.2021.
//

import Foundation

open class QueryKey {

    internal private(set) var object: Field

    public required init<T: Field>(_ field: T) {
        self.object = field
    }

    public init<T: CodingKey>(_ key: T) {
        self.object = Query(key)
    }

    public init(_ key: String) {
        self.object = Query(key)
    }

}
