//
//  APIAbstractCustomer.swift
//  GrapheneTests
//
//  Created by Ilya Kharlamov on 04.02.2021.
//

import Foundation
@testable import Graphene

public enum APIAbstractCustomer: Identifiable {

    case customer(Customer)
    case corporate(APICustomerCorporate)

    public var id: String {
        switch self {
        case .corporate(let value): return value.id
        case .customer(let value): return value.id
        }
    }

}

extension APIAbstractCustomer: AbstractDecodable {

    public init(schemaType: String, container: SingleValueDecodingContainer) throws {
        switch schemaType {
        case Customer.schemaType:
            self = .customer(try container.decode())
        case APICustomerCorporate.schemaType:
            self = .corporate(try container.decode())
        default:
            throw GrapheneError.unknownSchemaType(schemaType)
        }
    }

}

extension APIAbstractCustomer: Queryable {

    public static var schemaType: String { "AbstractCustomer" }

    public class QueryKeys: QueryKey {

        static let id = QueryKeys("id")
        static let createdAt = QueryKeys("createdAt")

        static func onCustomer(_ builder: @escaping QueryBuilder<Customer>) -> QueryKeys {
            On(Customer.self, builder).asKey()
        }

        static func onCorporateCustomer(_ builder: @escaping QueryBuilder<APICustomerCorporate>) -> QueryKeys {
            On(APICustomerCorporate.self, builder).asKey()
        }

    }
}
