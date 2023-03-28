//
//  APICustomerCorporate.swift
//  GrapheneTests
//
//  Created by Ilya Kharlamov on 04.02.2021.
//

import Foundation
@testable import Graphene

public struct APICustomerCorporate: Decodable, Identifiable {
    public var id: String
    public var createdAt: Date?
    public var vip: Bool?
    public var bad: Bool?
    public var nickName: String?
}

extension APICustomerCorporate: Queryable {

    public class QueryKeys: QueryKey {
        static let id = QueryKeys(CodingKeys.id)
        static let createdAt = QueryKeys(CodingKeys.createdAt)
        static let vip = QueryKeys(CodingKeys.vip)
        static let bad = QueryKeys(CodingKeys.bad)
        static let nickName = QueryKeys(CodingKeys.nickName)
    }

}

extension APICustomerCorporate: EncodableVariable {

    public func encode(to encoder: VariableEncoder) {
        let container = encoder.container(keyedBy: CodingKeys.self)
        container.encode(self.id, forKey: .id)
        container.encode(self.vip, forKey: .vip)
        container.encode(self.bad, forKey: .bad)
        container.encode(self.nickName, forKey: .nickName)
    }

}
