//
//  OrderType.swift
//  GrapheneTests
//
//  Created by Ilya Kharlamov on 01.02.2021.
//

import Foundation
@testable import Graphene

public struct OrderType: Codable, Identifiable {
    public var id: String
    public var name: String?
    public var active: Bool?
    public var defaultForCrm: Bool?
    public var defaultForApi: Bool?
}

extension OrderType: Queryable {

    public class QueryKeys: QueryKey {
        static let id               = QueryKeys(CodingKeys.id)
        static let name             = QueryKeys(CodingKeys.name)
        static let active           = QueryKeys(CodingKeys.active)
        static let defaultForCrm    = QueryKeys(CodingKeys.defaultForCrm)
        static let defaultForApi    = QueryKeys(CodingKeys.defaultForApi)
    }

}
