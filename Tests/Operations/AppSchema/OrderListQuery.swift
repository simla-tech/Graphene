//
//  OrdersListOperation.swift
//  GrapheneTests
//
//  Created by Ilya Kharlamov on 04.02.2021.
//

import Foundation
@testable import Graphene

struct OrderListQuery: GraphQLOperation {

    let variables: Variables

    struct Variables: QueryVariables {
        var after: String?
        static var allKeys: [PartialKeyPath<Variables>] = [\Variables.after]
    }
    
    func handleResponse(_ response: ExecuteResponse<AppSchema>) throws -> Connection<Order> {
        return try response.get({ $0.orders })
    }

    static func buildQuery(with builder: QueryContainer<AppSchema>) {
        builder += .orders(first: 20, after: .reference(to: \Variables.after)) { builder in
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

}
