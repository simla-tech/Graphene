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
    public var nullable: Bool = false

    public init(_ data: Data, name: String) {
        self.data = data
        self.name = name
    }

    public init(url: URL) throws {
        let fileData = try NSData(contentsOf: url, options: []) as Data
        self.init(fileData, name: url.lastPathComponent)
    }

    internal var contentType: String {
        return MimeType(path: self.name).value
    }

    public var json: Any? {
        return nil
    }

}
