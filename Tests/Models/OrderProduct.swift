//
//  OrderProduct.swift
//  GrapheneTests
//
//  Created by Ilya Kharlamov on 05.02.2021.
//

import Foundation
@testable import Graphene

public struct OrderProduct: Codable, Identifiable {
    public var id: ID
    public var initialPrice: Money?
}

extension OrderProduct: Queryable {

    public class QueryKeys: QueryKey {
        static let id           = QueryKeys(CodingKeys.id)
        static let initialPrice = QueryKeys(Query(CodingKeys.initialPrice, fragment: Money.self))
    }
    
}
