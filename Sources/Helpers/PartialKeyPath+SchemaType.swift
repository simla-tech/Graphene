//
//  PartialKeyPath+SchemaType.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 30.07.2021.
//  Copyright © 2021 RetailDriver LLC. All rights reserved.
//

import Foundation

internal extension PartialKeyPath {

    var variableType: String {
        let valueType = type(of: self).valueType
        if let valueType = valueType as? Variable.Type {
            return valueType.variableType
        } else {
            return "Unknown_\(valueType)"
        }
    }

}
