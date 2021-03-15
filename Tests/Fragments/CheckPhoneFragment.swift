//
//  CheckPhoneFragment.swift
//  GrapheneTests
//
//  Created by Ilya Kharlamov on 15.03.2021.
//

import Foundation
@testable import Graphene

struct CheckPhoneFragment: Fragment {
    public static func fragmentQuery(_ builder: QueryContainer<CheckPhone>) {
        builder += .phone
        builder += .isValid
        builder += .region
        builder += .timezoneOffset
        builder += .providerName
    }
}
