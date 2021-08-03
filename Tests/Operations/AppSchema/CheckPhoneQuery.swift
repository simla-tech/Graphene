//
//  CheckPhone.swift
//  GrapheneTests
//
//  Created by Ilya Kharlamov on 04.02.2021.
//

import Foundation
@testable import Graphene

struct CheckPhoneQuery: GraphQLOperation {

    let variables: Variables

    struct Variables: QueryVariables {
        let phone: String
        static let allKeys: [PartialKeyPath<Variables>] = [\Variables.phone]
    }

    func handleResponse(_ response: ExecuteResponse<AppSchema>) throws -> CheckPhone {
        return try response.get({ $0.checkPhone })
    }
    
    static func buildQuery(with builder: QueryContainer<AppSchema>) {
        builder += .checkPhone(phone: .reference(to: \Variables.phone), { builder in
            builder += CheckPhoneFragment.self
        })
    }

}
