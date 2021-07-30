//
//  Order.swift
//  GrapheneTests
//
//  Created by Ilya Kharlamov on 01.02.2021.
//

import Foundation
@testable import Graphene

public struct Order: Decodable, Identifiable {
    public var id: ID
    public var externalId: String?
    public var number: String?
    public var createdAt: String?
    public var nickName: String?
    public var firstName: String?
    public var lastName: String?
    public var patronymic: String?
    public var orderType: OrderType?
    public var payments: [Payment]?
    public var manager: User?
    public var updateStateDate: String?
    public var contragent: Contragent?
    public var unionCustomer: AbstractCustomer?
    public var orderProducts: Connection<OrderProduct>?
}

// MARK: - Queryable

extension Order: Queryable {

    public class QueryKeys: QueryKey {

        static let id               = QueryKeys(CodingKeys.id)
        static let number           = QueryKeys(CodingKeys.number)
        static let createdAt        = QueryKeys(CodingKeys.createdAt)
        static let nickName         = QueryKeys(CodingKeys.nickName)
        static let firstName        = QueryKeys(CodingKeys.firstName)
        static let lastName         = QueryKeys(CodingKeys.lastName)
        static let patronymic       = QueryKeys(CodingKeys.patronymic)
        static let updateStateDate  = QueryKeys(CodingKeys.updateStateDate)
        static let externalId       = QueryKeys(CodingKeys.externalId)

        static func payments(_ builder: @escaping QueryBuilder<Payment>) -> QueryKeys {
            return Query(CodingKeys.payments, builder).asKey()
        }

        static func manager(_ builder: @escaping QueryBuilder<User>) -> QueryKeys {
            return Query(CodingKeys.manager, builder).asKey()
        }

        static func orderType(_ builder: @escaping QueryBuilder<OrderType>) -> QueryKeys {
            return Query(CodingKeys.orderType, builder).asKey()
        }

        static func contragent(_ builder: @escaping QueryBuilder<Contragent>) -> QueryKeys {
            return Query(CodingKeys.contragent, builder).asKey()
        }

        static func unionCustomer(_ builder: @escaping QueryBuilder<AbstractCustomer>) -> QueryKeys {
            return Query(CodingKeys.unionCustomer, builder).asKey()
        }

        static func orderProducts(first: Int? = nil, after: String? = nil, _ builder: @escaping QueryBuilder<Connection<OrderProduct>>) -> QueryKeys {
            return Query(CodingKeys.orderProducts, args: ["first": first, "after": after], builder).asKey()
        }

    }

}

// MARK: - Variable

extension Order: EncodableVariable {
    public func encode(to encoder: VariableEncoder) {
        let conatiner = encoder.container(keyedBy: CodingKeys.self)
        conatiner.encode(self.number, forKey: .number)
        conatiner.encode(self.nickName, forKey: .nickName)
        conatiner.encode(self.firstName, forKey: .firstName)
        conatiner.encode(self.lastName, forKey: .lastName)
        conatiner.encode(self.externalId, forKey: .externalId)
        conatiner.encode(self.patronymic, forKey: .patronymic)
        conatiner.encode(self.manager?.id, forKey: .manager)
        conatiner.encode(self.orderType?.id, forKey: .orderType)
        conatiner.encode(self.payments, forKey: .payments)
        conatiner.encode(self.contragent, forKey: .contragent)
    }
}
