//
//  OperationRawResponse.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 03.08.2021.
//  Copyright © 2021 RetailDriver LLC. All rights reserved.
//

import Foundation

internal struct OperationRawResponse<Root: Decodable>: Decodable {

    let data: Root?
    let errors: [GraphQLError]?

    func getData() throws-> Root {
        guard let data = self.data else {
            if let graphqlErrors = self.errors, graphqlErrors.count > 1 {
                throw GraphQLErrors(graphqlErrors)
            }
            throw self.errors?.first ?? GrapheneError.invalidResponse
        }
        return data
    }

}
