//
//  Payment.swift
//  GrapheneTests
//
//  Created by Ilya Kharlamov on 01.02.2021.
//

import Foundation
@testable import Graphene

public struct Payment: Decodable, Identifiable, ChangeSetIdentifiable {
    public var id: String
    public var type: APIPaymentType?
    public var amount: Money?
    public var paidAt: Date?
    public var comment: String?
    public var status: PaymentStatus?
    public var deleted: Bool?
}

extension Payment: Queryable {

    public class QueryKeys: QueryKey {

        static var id = QueryKeys(CodingKeys.id)
        static let amount = QueryKeys(Query(CodingKeys.amount, fragment: MoneyFragment.self))
        static let paidAt = QueryKeys(CodingKeys.paidAt)
        static let comment = QueryKeys(CodingKeys.comment)

        static func status(_ builder: @escaping QueryBuilder<PaymentStatus>) -> QueryKeys {
            Query(CodingKeys.status, builder).asKey()
        }

        static func type(_ builder: @escaping QueryBuilder<APIPaymentType>) -> QueryKeys {
            Query(CodingKeys.type, builder).asKey()
        }

    }

}

extension Payment: EncodableVariable {

    public func encode(to encoder: VariableEncoder) {
        let container = encoder.container(keyedBy: CodingKeys.self)
        container.encode(self.id, forKey: .id, required: true)
        container.encode(self.amount?.amount, forKey: .amount)
        container.encode(self.comment, forKey: .comment)
        let dateFormatter = DateFormatter()
        if let paidAt = self.paidAt {
            container.encode(dateFormatter.string(from: paidAt), forKey: .paidAt)
        } else {
            container.encode(nil, forKey: .paidAt)
        }
        container.encode(self.status?.id, forKey: .status)
        container.encode(self.type?.id, forKey: .type, required: true)
        container.encode(self.deleted, forKey: .deleted)
    }

}
