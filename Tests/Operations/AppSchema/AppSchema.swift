//
//  APIQuerySchema.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 02.08.2021.
//  Copyright © 2021 DIGITAL RETAIL TECHNOLOGIES, S.L. All rights reserved.
//

import Foundation
@testable import Graphene

struct APIQuerySchema: QuerySchema {

    final class QueryKeys: QueryKey {

        static func orders(
            first: Argument<Int>? = nil,
            after: Argument<String>? = nil,
            _ builder: @escaping QueryBuilder<Connection<Order>>
        ) -> QueryKeys {
            Query("orders", args: ["first": first, "after": after], builder).asKey()
        }

        static func order(id: Argument<Order.ID>, _ builder: @escaping QueryBuilder<Order>) -> QueryKeys {
            Query("order", args: ["id": id], builder).asKey()
        }

        static func checkPhone(phone: Argument<String>, _ builder: @escaping QueryBuilder<CheckPhone>) -> QueryKeys {
            Query("checkPhone", args: ["phone": phone], builder).asKey()
        }

    }

}
