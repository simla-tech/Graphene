//
//  CheckPhone.swift
//  GrapheneTests
//
//  Created by Ilya Kharlamov on 04.02.2021.
//

import Foundation
@testable import Graphene

public struct CheckPhone: Decodable {
    public var phone: String
    public var isValid: Bool?
    public var region: String?
    public var timezoneOffset: Int?
    public var providerName: String?
}

extension CheckPhone: Queryable {
    public class QueryKeys: QueryKey {
        static let phone          = QueryKeys(CodingKeys.phone)
        static let isValid        = QueryKeys(CodingKeys.isValid)
        static let region         = QueryKeys(CodingKeys.region)
        static let timezoneOffset = QueryKeys(CodingKeys.timezoneOffset)
        static let providerName   = QueryKeys(CodingKeys.providerName)
    }
}
