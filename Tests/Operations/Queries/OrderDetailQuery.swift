//
//  OrderDetailQuery.swift
//  GrapheneTests
//
//  Created by Ilya Kharlamov on 03.02.2021.
//

import Foundation
@testable import Graphene

final class OrderDetailQuery: QueryOperation {    
        
    let orderId: Order.ID
    
    init(orderId: Order.ID) {
        self.orderId = orderId
    }

    lazy var query = Query<Order>("order", args: ["id": self.orderId]) { builder in
        builder += OrderDetailFragment()
    }
    
    static func mapResult(_ result: Order) throws -> OrderType? {
        return result.orderType
    }
    
}
