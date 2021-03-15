//
//  MoneyFragment.swift
//  GrapheneTests
//
//  Created by Ilya Kharlamov on 15.03.2021.
//

import Foundation
@testable import Graphene

struct MoneyFragment: Fragment {
    static func fragmentQuery(_ builder: QueryContainer<Money>) {
        builder += .amount
        builder += .currency
    }
}
