//
//  OrdersListOperation.swift
//  GrapheneTests
//
//  Created by Ilya Kharlamov on 04.02.2021.
//

import Foundation
@testable import Graphene

final class OrderListQuery: QueryOperation {

    let arguments: Arguments
    
    init(first: Int? = nil, after: String? = nil, filter: Arguments? = nil) {
        self.arguments = ["first": first, "after": after, "filter": filter]
    }
            
    lazy var query = Query<Connection<Order>>("orders", args: self.arguments) { builder in
        builder += .totalCount
        builder += .pageInfo
        builder += .edges({ order in
            order += .id
            order += .number
            order += .unionCustomer({ unionCustomer in
                unionCustomer += .id
                unionCustomer += .createdAt
            })
        })
    }
    
}
