//
//  Enums.swift
//  GrapheneTests
//
//  Created by Ilya Kharlamov on 04.02.2021.
//

import Foundation
@testable import Graphene

enum AttachEntity: String, Variable, AnyArgument, Codable {
    case customer = "CUSTOMER"
    case order = "ORDER"
}

public enum ContragentType: String, Variable, Codable {
    case individual = "INDIVIDUAL"
    case legalEntity = "LEGAL_ENTITY"
    case enterpreneur = "ENTERPRENEUR"
}
