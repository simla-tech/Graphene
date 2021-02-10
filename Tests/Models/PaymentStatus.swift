//
//  PaymentStatus.swift
//  GrapheneTests
//
//  Created by Ilya Kharlamov on 01.02.2021.
//

import Foundation
@testable import Graphene

public struct PaymentStatus: Decodable, Identifiable {
    public var id: ID
    public var name: String?
    public var active: Bool?
    public var description: String?
    public var defaultForCrm: Bool?
    public var defaultForApi: Bool?
    public var paymentComplete: Bool?
    public var ordering: Int?
    public var paymentTypes: [PaymentType]?
}

extension PaymentStatus: Queryable {
    
    public class QueryKeys: QueryKey {
        
        static let id               = QueryKeys(CodingKeys.id)
        static let name             = QueryKeys(CodingKeys.name)
        static let active           = QueryKeys(CodingKeys.active)
        static let description      = QueryKeys(CodingKeys.description)
        static let defaultForCrm    = QueryKeys(CodingKeys.defaultForCrm)
        static let defaultForApi    = QueryKeys(CodingKeys.defaultForApi)
        static let paymentComplete  = QueryKeys(CodingKeys.paymentComplete)
        static let ordering         = QueryKeys(CodingKeys.ordering)
        
        static func paymentTypes(_ builder: @escaping QueryBuilder<PaymentType>) -> QueryKeys {
            return Query(CodingKeys.paymentTypes, builder).asKey()
        }
        
    }
    
}
