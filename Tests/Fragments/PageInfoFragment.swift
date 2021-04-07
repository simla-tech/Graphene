//
//  PageInfoFragment.swift
//  GrapheneTests
//
//  Created by Ilya Kharlamov on 15.03.2021.
//

import Foundation
@testable import Graphene

struct PageInfoFragment: Fragment {
    func fragmentQuery(_ query: QueryContainer<PageInfo>) {
        query += .hasNextPage
        query += .endCursor
    }
}
