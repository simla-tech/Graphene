//
//  Money.swift
//  GrapheneTests
//
//  Created by Ilya Kharlamov on 01.02.2021.
//

import Foundation
@testable import Graphene

public struct Money: Codable, Fragment {
    
    public var amount: Double = 0
    public var currency: String = "rub"
    
    public init(amount: Double, currency: String = "rub") {
        self.amount = amount
        self.currency = currency
    }
    
    public static func fragmentQuery(_ builder: QueryContainer<Money>) {
        builder += .amount
        builder += .currency
    }
    
}

extension Money: Queryable {

    public class QueryKeys: QueryKey {
        static let amount   = QueryKeys(CodingKeys.amount)
        static let currency = QueryKeys(CodingKeys.currency)
    }
    
}
