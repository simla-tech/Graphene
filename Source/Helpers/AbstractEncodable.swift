//
//  AbstractEncodable.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 16.03.2021.
//

import Foundation

public protocol AbstractEncodable: Encodable {
    func encode(to encoder: AbstractEncoder) throws
}

extension AbstractEncodable {
    public func encode(to encoder: Encoder) throws {
        let abstractEncoder = AbstractEncoder(encoder: encoder)
        try self.encode(to: abstractEncoder)
    }
}

public struct AbstractEncodingContainer {
    private let encoder: Encoder
    internal init(encoder: Encoder) {
        self.encoder = encoder
    }
    private enum CodingKeys: String, CodingKey {
        case typename = "__typename"
    }
    public func encode<T: Encodable & SchemaType>(_ value: T) throws {
        var container = self.encoder.container(keyedBy: CodingKeys.self)
        try container.encode(T.schemaType, forKey: .typename)
        try value.encode(to: self.encoder)
    }
}

public struct AbstractEncoder {
    private let encoder: Encoder
    internal init(encoder: Encoder) {
        self.encoder = encoder
    }
    public func abstractContainer() -> AbstractEncodingContainer {
        return AbstractEncodingContainer(encoder: self.encoder)
    }
}
