//
//  OrderEditMutation.swift
//  GrapheneTests
//
//  Created by Ilya Kharlamov on 03.02.2021.
//

import Foundation
@testable import Graphene

struct OrderEditMutation: GraphQLOperation {

    let variables: Variables

    struct Variables: QueryVariables {
        let input: EditOrderInput
        static var allKeys: [PartialKeyPath<Variables>] = [\Variables.input]
    }

    func handleResponse(_ response: ExecuteResponse<AppMutation>) throws -> Order {
        return try response.get({ $0.editOrder?.order })
    }
    
    static func buildQuery(with builder: QueryContainer<AppMutation>) {
        builder += .editOrder(input: .reference(to: \Variables.input), { builder in
            builder += .order({ builder in
                builder += OrderDetailFragment.self
            })
        })
    }

}
