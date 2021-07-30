//
//  MultipleOperationResponse.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 04.02.2021.
//

import Foundation

/*
public struct MultipleOperationResponse<T> {
    public typealias ResponseType = [String: T]
    internal var data: ResponseType = [:]
}

extension MultipleOperationResponse: Queryable {
    public class QueryKeys: QueryKey {
        static func childrenOperation<O: Graphene.QueryOperation>(operation: O, key: String) -> QueryKeys {
            var query = operation.query
            query.alias = key
            return QueryKeys(query)
        }
    }
}

extension MultipleOperationResponse: Decodable where T: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.data = try container.decode([String: T].self)
    }
}
*/
