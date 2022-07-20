//
//  Response.swift
//  GrapheneInspector
//
//  Created by Ilya Kharlamov on 7/18/22.
//

import Foundation
import Graphene

public extension GrapheneInspector {

    struct Response: Decodable {

        public let errors: [GraphQLError]
        public let deprecated: [GraphQLError]

        private enum CodingKeys: String, CodingKey {
            case errors
            case deprecated
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.errors = (try? container.decodeIfPresent([GraphQLError].self, forKey: .errors)) ?? []
            self.deprecated = (try? container.decodeIfPresent([GraphQLError].self, forKey: .deprecated)) ?? []
        }

    }

}
