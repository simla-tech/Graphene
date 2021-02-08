//
//  PageInfo.swift
//  GrapheneTests
//
//  Created by Ilya Kharlamov on 04.02.2021.
//

import Foundation
@testable import Graphene

public struct PageInfo: Codable, SchemaType {
    
    public let hasNextPage: Bool
    public let endCursor: String?
    
    init() {
        self.hasNextPage = false
        self.endCursor = nil
    }
}

extension PageInfo: Queryable {

    public class QueryKeys: QueryKey {
        fileprivate static let hasNextPage  = QueryKeys(CodingKeys.hasNextPage)
        fileprivate static let endCursor    = QueryKeys(CodingKeys.endCursor)
    }
    
}

extension PageInfo: Fragment {
    public static func fragmentQuery(_ query: QueryContainer<PageInfo>) {
        query += .hasNextPage
        query += .endCursor
    }
}
