//
//  Money.swift
//  GrapheneTests
//
//  Created by Ilya Kharlamov on 01.02.2021.
//

import Foundation
@testable import Graphene

public struct Money: Codable {

    public var amount: Double = 0
    public var currency = "rub"

    public init(amount: Double, currency: String = "rub") {
        self.amount = amount
        self.currency = currency
    }

}

extension Money: Queryable {

    public class QueryKeys: QueryKey {
        static let amount = QueryKeys(CodingKeys.amount)
        static let currency = QueryKeys(CodingKeys.currency)
    }

}
