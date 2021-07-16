//
//  QueryKey.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 03.02.2021.
//

import Foundation

open class QueryKey {

    fileprivate(set) internal var object: Field

    public required init<T: Field>(_ field: T) {
        self.object = field
    }

    public init<T: CodingKey>(_ key: T) {
        self.object = key.stringValue
    }

}
