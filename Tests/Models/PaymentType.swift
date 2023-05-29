//
//  PaymentType.swift
//  GrapheneTests
//
//  Created by Ilya Kharlamov on 01.02.2021.
//

import Foundation
@testable import Graphene

public struct APIPaymentType: Decodable, Identifiable {
    public var id: String
    public var name: String?
    public var active: Bool?
    public var description: String?
    public var defaultForCrm: Bool?
    public var defaultForApi: Bool?
}

extension APIPaymentType: Queryable {

    public static var schemaType: String { "PaymentType" }

    public class QueryKeys: QueryKey {
        static let id = QueryKeys(CodingKeys.id)
        static let name = QueryKeys(CodingKeys.name)
        static let active = QueryKeys(CodingKeys.active)
        static let description = QueryKeys(CodingKeys.description)
        static let defaultForCrm = QueryKeys(CodingKeys.defaultForCrm)
        static let defaultForApi = QueryKeys(CodingKeys.defaultForApi)
    }

}
