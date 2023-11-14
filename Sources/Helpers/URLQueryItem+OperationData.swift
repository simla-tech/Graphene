//
//  URLQueryItem+OperationData.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 11/13/23.
//  Copyright © 2023 DIGITAL RETAIL TECHNOLOGIES, S.L. All rights reserved.
//

import Foundation

extension URLQueryItem {

    static var operationNameKey = "operation"
    static var variablesHashKey = "variables"

    static func operationName(_ value: String) -> URLQueryItem {
        URLQueryItem(name: self.operationNameKey, value: value)
    }

    static func variablesHash(_ value: String) -> URLQueryItem {
        URLQueryItem(name: self.variablesHashKey, value: value)
    }

}
