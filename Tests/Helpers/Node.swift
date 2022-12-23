//
//  Node.swift
//  GrapheneTests
//
//  Created by Ilya Kharlamov on 04.02.2021.
//

import Foundation
@testable import Graphene

internal struct Node<T> {
    let node: T
}

extension Node: Queryable where T: Queryable {
    class QueryKeys: QueryKey {
        static func node(_ builder: @escaping QueryBuilder<T>) -> QueryKeys {
            .init(Query("node", builder))
        }
    }
}

extension Node: Decodable where T: Decodable { }
extension Node: Encodable where T: Encodable { }
