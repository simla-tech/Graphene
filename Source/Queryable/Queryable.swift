//
//  Queryable.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 22.01.2021.
//

import Foundation

public protocol Queryable {
    associatedtype QueryKeys: QueryKey
}

extension Array: Queryable where Element: Queryable {
    public typealias QueryKeys = Element.QueryKeys
}
