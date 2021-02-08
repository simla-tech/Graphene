//
//  OnQuery.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 03.02.2021.
//

import Foundation

public struct OnQuery<T: Queryable & SchemaType>: Field {
    
    private let schemaType: String
    public var childrenFields: [Field]
    public let arguments: Arguments = [:]
    
    init(_ builder: @escaping QueryBuilder<T>, schemaType: String) {
        let container = QueryContainer<T>(builder)
        self.childrenFields = container.fields
        self.schemaType = schemaType
    }
    
    init(_ builder: @escaping QueryBuilder<T>) where T: SchemaType {
        self.init(builder, schemaType: T.schemaType)
    }
    
    public var fieldString: String {
        var res = [String]()
        res.append("...on \(self.schemaType) {")
        res.append(self.childrenFields.map({ $0.fieldString }).joined(separator: ","))
        res.append("}")
        return res.joined()
    }
    
}
