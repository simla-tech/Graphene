//
//  AbstractDecodable.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 03.02.2021.
//

import Foundation

private enum TypeNameCodingKey: String, CodingKey {
    case typename = "__typename"
}

public protocol AbstractDecodable: Decodable {
    init(schemaType: String, container: SingleValueDecodingContainer) throws
}

public extension AbstractDecodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: TypeNameCodingKey.self)
        let nestedType = try container.decode(String.self, forKey: .typename)
        let nestedContainer = try decoder.singleValueContainer()
        try self.init(schemaType: nestedType, container: nestedContainer)
    }
}
