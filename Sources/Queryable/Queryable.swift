//
//  Queryable.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 22.01.2021.
//

import Foundation

public protocol Queryable {
    associatedtype QueryKeys: QueryKey
    static var schemaType: String { get }
}

public extension Queryable {
    static var schemaType: String {
        String(describing: self)
    }
}

extension Array: Queryable where Element: Queryable {
    public typealias QueryKeys = Element.QueryKeys
}
