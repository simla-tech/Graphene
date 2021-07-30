//
//  CheckPhoneFragment.swift
//  GrapheneTests
//
//  Created by Ilya Kharlamov on 15.03.2021.
//

import Foundation
@testable import Graphene

struct CheckPhoneFragment: Fragment {
    static func buildQuery(with builder: QueryContainer<CheckPhone>) {
        builder += .phone
        builder += .isValid
        builder += .region
        builder += .timezoneOffset
        builder += .providerName
    }
}
