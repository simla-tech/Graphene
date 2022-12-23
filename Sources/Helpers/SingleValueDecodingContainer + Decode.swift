//
//  SingleValueDecodingContainer + Decode.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 03.02.2021.
//

import Foundation

extension SingleValueDecodingContainer {
    func decode<Z: Decodable>() throws -> Z {
        try self.decode(Z.self)
    }
}
