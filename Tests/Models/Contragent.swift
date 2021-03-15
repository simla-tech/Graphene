//
//  Contragent.swift
//  GrapheneTests
//
//  Created by Ilya Kharlamov on 02.02.2021.
//

import Foundation
@testable import Graphene

public struct Contragent: Decodable {
    public var contragentType: ContragentType
    public var legalName: String?
    public var legalAddress: String?
    public var INN: String?
    public var OKPO: String?
    public var KPP: String?
    public var OGRN: String?
    public var OGRNIP: String?
}

extension Contragent: Queryable {
    
    public class QueryKeys: QueryKey {
        static let contragentType   = QueryKeys(CodingKeys.contragentType)
        static let legalName        = QueryKeys(CodingKeys.legalName)
        static let legalAddress     = QueryKeys(CodingKeys.legalAddress)
        static let INN              = QueryKeys(CodingKeys.INN)
        static let OKPO             = QueryKeys(CodingKeys.OKPO)
        static let KPP              = QueryKeys(CodingKeys.KPP)
        static let OGRN             = QueryKeys(CodingKeys.OGRN)
        static let OGRNIP           = QueryKeys(CodingKeys.OGRNIP)
    }
    
}

extension Contragent: EncodableVariable {

    public func encode(to encoder: VariableEncoder) {
        let container = encoder.container(keyedBy: CodingKeys.self)
        container.encode(self.contragentType, forKey: .contragentType, required: true)
        container.encode(self.legalName, forKey: .legalName)
        container.encode(self.legalAddress, forKey: .legalAddress)
        container.encode(self.INN, forKey: .INN)
        container.encode(self.OKPO, forKey: .OKPO)
        container.encode(self.KPP, forKey: .KPP)
        container.encode(self.OGRN, forKey: .OGRN)
        container.encode(self.OGRNIP, forKey: .OGRNIP)
    }
    
}
