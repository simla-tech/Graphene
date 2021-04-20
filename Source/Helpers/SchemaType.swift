//
//  SchemaType.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 03.02.2021.
//

import Foundation

public protocol SchemaType {
    static var schemaType: String { get }
}

extension SchemaType {
    public static var schemaType: String {
        return String(describing: self)
    }
}

extension String: SchemaType {}

extension Int: SchemaType {}

extension Double: SchemaType {}

extension Bool: SchemaType {
    public static var schemaType: String {
        return "Boolean"
    }
}

extension Float: SchemaType {
    public static var schemaType: String {
        return "Double"
    }
}
