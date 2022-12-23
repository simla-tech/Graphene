//
//  VariableEncoderKeyedContainer.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 28.01.2021.
//

import Foundation

public class VariableEncoderKeyedContainer<Key: CodingKey>: VariableEncoderContainer {

    public func encodeIfPresent(
        _ value: Variable?,
        forKey key: KeyedEncodingContainer<Key>.Key,
        required: Bool = false
    ) {
        self.encodeIfPresent(value, forKey: key.stringValue, required: required)
    }

    public func encode(
        _ value: Variable?,
        forKey key: KeyedEncodingContainer<Key>.Key,
        required: Bool = false
    ) {
        self.encode(value, forKey: key.stringValue, required: required)
    }

}
