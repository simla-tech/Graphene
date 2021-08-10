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

extension Queryable {
    public static var schemaType: String {
        return String(describing: self)
    }
}

extension Array: Queryable where Element: Queryable {
    public typealias QueryKeys = Element.QueryKeys
}
