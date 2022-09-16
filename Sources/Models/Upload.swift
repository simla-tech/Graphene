//
//  Upload.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 28.01.2021.
//

import Foundation

public struct Upload: Codable, Variable {

    public var data: Data
    public var name: String

    public init(_ data: Data, name: String) {
        self.data = data
        self.name = name
    }

    public init(url: URL, name: String? = nil) throws {
        let fileData = try NSData(contentsOf: url, options: []) as Data
        self.init(fileData, name: name ?? url.lastPathComponent)
    }

    public var json: Any? {
        return nil
    }

}
