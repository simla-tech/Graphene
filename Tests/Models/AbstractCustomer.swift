//
//  AbstractCustomer.swift
//  GrapheneTests
//
//  Created by Ilya Kharlamov on 04.02.2021.
//

import Foundation
@testable import Graphene

public enum AbstractCustomer: Identifiable {

    case customer(Customer)
    case corporate(CustomerCorporate)
    
    public var id: ID {
        switch self {
        case .corporate(let value): return .init(value.id)
        case .customer(let value): return .init(value.id)
        }
    }
    
}

extension AbstractCustomer: AbstractDecodable {
    
    public init(schemaType: String, container: SingleValueDecodingContainer) throws {
        switch schemaType {
        case Customer.schemaType:
            self = .customer(try container.decode())
        case CustomerCorporate.schemaType:
            self = .corporate(try container.decode())
        default:
            throw GrapheneError.unknownSchemaType(schemaType)
        }
    }
    
}

extension AbstractCustomer: Queryable {
    
    public class QueryKeys: QueryKey {
        
        static let id        = QueryKeys("id")
        static let createdAt = QueryKeys("createdAt")

        static func onCustomer(_ builder: @escaping QueryBuilder<Customer>) -> QueryKeys {
            return On(Customer.self, builder).asKey()
        }
        
        static func onCorporateCustomer(_ builder: @escaping QueryBuilder<CustomerCorporate>) -> QueryKeys {
            return On(CustomerCorporate.self, builder).asKey()
        }
        
    }
}
