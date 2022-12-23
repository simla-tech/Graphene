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
        let someString: String
        let someInt: Int?
        let someDict: [String: Double]?
        static var allKeys: [PartialKeyPath<Variables>] = [
            \Variables.orderId,
            \Variables.someString,
            \Variables.someInt,
            \Variables.someDict
        ]
    }

    static func decodePath(of decodable: Order.Type) -> String? {
        "order"
    }

    static func buildQuery(with builder: QueryContainer<APIQuerySchema>) {
        builder += .order(id: .reference(to: \Variables.orderId)) { builder in
            builder += OrderDetailFragment.self
        }
    }

}
