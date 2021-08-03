//
//  OrderDetailQuery.swift
//  GrapheneTests
//
//  Created by Ilya Kharlamov on 03.02.2021.
//

import Foundation
@testable import Graphene

struct OrderDetailQuery: GraphQLOperation {

    let variables: Variables

    struct Variables: QueryVariables {
        let orderId: Order.ID
        static var allKeys: [PartialKeyPath<Variables>] = [\Variables.orderId]
    }

    static func handleResponse(_ response: ExecuteResponse<AppSchema>) throws -> Order {
        return try response.get({ $0.order })
    }

    static func buildQuery(with builder: QueryContainer<AppSchema>) {
        builder += .order(id: .reference(to: \Variables.orderId)) { builder in
            builder += OrderDetailFragment.self
        }
    }

}
