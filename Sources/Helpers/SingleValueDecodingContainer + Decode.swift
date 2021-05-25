//
//  SingleValueDecodingContainer + Decode.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 03.02.2021.
//

import Foundation

extension SingleValueDecodingContainer {
    internal func decode<Z: Decodable>() throws -> Z {
        return try self.decode(Z.self)
    }
}
