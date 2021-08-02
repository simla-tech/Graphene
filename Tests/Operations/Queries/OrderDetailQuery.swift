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

        let orderInput: String
        let anotherInput: Int?
        let test: [String: Float]

        static var allKeys: [PartialKeyPath<Variables>] = [
            \Variables.orderInput,
            \Variables.anotherInput,
            \Variables.test
        ]

    }

    static func buildQuery(with builder: QueryContainer<AppSchema>) {
        builder += .orders(orderInput: .from(\Variables.anotherInput)) { builder in
            builder += .edges({ builder in
                builder += .id
                builder += .payments({ builder in
                    builder += .amount
                })
            })
        }
    }

}

struct AppSchema: Schema {

    static let mode: OperationMode = .query

    let orders: Connection<Order>?

}

extension AppSchema: Queryable {

    final class QueryKeys: QueryKey {

        static func orders(orderInput: VariableKeyPath<Int?>, _ builder: @escaping QueryBuilder<Connection<Order>>) -> QueryKeys {
            let query = Query(CodingKeys.orders, args: ["input": orderInput], builder)
            return query.asKey()
        }

    }

}
