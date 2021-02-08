//
//  CheckPhone.swift
//  GrapheneTests
//
//  Created by Ilya Kharlamov on 04.02.2021.
//

import Foundation
@testable import Graphene

struct CheckPhoneQuery: QueryOperation {

    let query: Query<CheckPhone>
        
    init(phone: String) {
        self.query = Query("checkPhone", args: ["phone": phone], fragment: CheckPhone.self)
    }
        
}
