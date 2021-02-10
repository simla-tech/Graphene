//
//  EditOrderPayload.swift
//  GrapheneTests
//
//  Created by Ilya Kharlamov on 01.02.2021.
//

import Foundation
@testable import Graphene

public struct EditOrderPayload: Decodable {
    public var order: Order
}

extension EditOrderPayload: Queryable {
    
    public class QueryKeys: QueryKey {
        static func order(_ builder: @escaping QueryBuilder<Order>) -> QueryKeys {
            return Query(CodingKeys.order, builder).asKey()
        }
    }
    
}
