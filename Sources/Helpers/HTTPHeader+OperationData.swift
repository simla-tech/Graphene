//
//  HTTPHeader+OperationData.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 11/13/23.
//  Copyright © 2023 DIGITAL RETAIL TECHNOLOGIES, S.L. All rights reserved.
//

import Alamofire
import Foundation

extension HTTPHeader {

    static var operationNameKey = "Operation-Name"
    static var variablesHashKey = "Variables-Hash"

    static func operationName(_ value: String) -> HTTPHeader {
        HTTPHeader(name: self.operationNameKey, value: value)
    }

    static func variablesHash(_ value: String) -> HTTPHeader {
        HTTPHeader(name: "Variables-Hash", value: value)
    }

}
