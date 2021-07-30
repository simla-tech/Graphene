//
//  Customer.swift
//  GrapheneTests
//
//  Created by Ilya Kharlamov on 04.02.2021.
//

import Foundation
@testable import Graphene

public struct Customer: Decodable, Identifiable {
    public var id: ID
    public var createdAt: Date?
    public var vip: Bool?
    public var bad: Bool?
    public var firstName: String?
    public var lastName: String?
}

extension Customer: Queryable {

    public class QueryKeys: QueryKey {
        static let id           = QueryKeys(CodingKeys.id)
        static let createdAt    = QueryKeys(CodingKeys.createdAt)
        static let vip          = QueryKeys(CodingKeys.vip)
        static let bad          = QueryKeys(CodingKeys.bad)
        static let firstName    = QueryKeys(CodingKeys.firstName)
        static let lastName     = QueryKeys(CodingKeys.lastName)
    }

}

extension Customer: EncodableVariable {

    public func encode(to encoder: VariableEncoder) {
        let container = encoder.container(keyedBy: CodingKeys.self)
        container.encode(self.id, forKey: .id)
        container.encode(self.vip, forKey: .vip)
        container.encode(self.bad, forKey: .bad)
        container.encode(self.firstName, forKey: .firstName)
        container.encode(self.lastName, forKey: .lastName)
    }

}
