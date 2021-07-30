//
//  PageInfo.swift
//  GrapheneTests
//
//  Created by Ilya Kharlamov on 04.02.2021.
//

import Foundation
@testable import Graphene

public struct PageInfo: Codable {

    public let hasNextPage: Bool
    public let endCursor: String?

    init() {
        self.hasNextPage = false
        self.endCursor = nil
    }
}

extension PageInfo: Queryable {

    public class QueryKeys: QueryKey {
        public static let hasNextPage  = QueryKeys(CodingKeys.hasNextPage)
        public static let endCursor    = QueryKeys(CodingKeys.endCursor)
    }

}
