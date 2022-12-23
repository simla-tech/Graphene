//
//  KeyPath+Identifier.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 30.07.2021.
//  Copyright © 2021 DIGITAL RETAIL TECHNOLOGIES, S.L. All rights reserved.
//

import Foundation

extension AnyKeyPath {

    var identifier: String {
        let hashids = Hashids(salt: "com.simla.Graphene")
        return hashids.encode(abs(self.hashValue))!
    }

}
