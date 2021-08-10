//
//  KeyPath+Identifier.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 30.07.2021.
//  Copyright © 2021 RetailDriver LLC. All rights reserved.
//

import Foundation

internal extension AnyKeyPath {

    var identifier: String {
        let hashids = Hashids(salt: "com.retaildriver.Graphene")
        return hashids.encode(abs(self.hashValue))!
    }

}
