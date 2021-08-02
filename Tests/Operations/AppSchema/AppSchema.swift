//
//  AppSchema.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 02.08.2021.
//  Copyright © 2021 RetailDriver LLC. All rights reserved.
//

import Foundation
@testable import Graphene

struct AppSchema: Schema {

    static let mode: OperationMode = .query

    let orders: Connection<Order>?
    let checkPhone: CheckPhone?
    let order: Order?

}

extension AppSchema: Queryable {

    final class QueryKeys: QueryKey {

        static func orders(first: Argument<Int>? = nil,
                           after: Argument<String>? = nil,
                           _ builder: @escaping QueryBuilder<Connection<Order>>) -> QueryKeys {
            return Query(CodingKeys.orders, args: ["first": first, "after": after], builder).asKey()
        }

        static func order(id: Argument<Order.ID>, _ builder: @escaping QueryBuilder<Order>) -> QueryKeys {
            return Query(CodingKeys.order, args: ["id": id], builder).asKey()
        }

        static func checkPhone(phone: Argument<String>, _ builder: @escaping QueryBuilder<CheckPhone>) -> QueryKeys {
            return Query(CodingKeys.checkPhone, args: ["phone": phone], builder).asKey()
        }

    }

}
