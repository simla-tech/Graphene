//
//  PageInfoFragment.swift
//  GrapheneTests
//
//  Created by Ilya Kharlamov on 15.03.2021.
//

import Foundation
@testable import Graphene

struct PageInfoFragment: Fragment {
    static func buildQuery(with builder: QueryContainer<PageInfo>) {
        builder += .hasNextPage
        builder += .endCursor
    }
}
