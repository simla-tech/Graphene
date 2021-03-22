//
//  GraphQLError.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 28.01.2021.
//

import Foundation

public struct GraphQLError: Error, Codable {
    
    public var message: String
    public var locations: [Location]?
    public var path: [String]?
    public var extensions: Extensions?
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.message = try container.decode(String.self, forKey: .message)
        self.locations = try? container.decodeIfPresent([Location].self, forKey: .locations)
        self.path = try? container.decodeIfPresent([String].self, forKey: .path)
        self.extensions = try? container.decodeIfPresent(Extensions.self, forKey: .extensions)
    }
    
}

extension GraphQLError {
    public struct Location: Codable {
        public var line: Int
        public var column: Int
    }
}

extension GraphQLError {
    public struct Extensions: Codable {
        public var category: Category
        public var field: String?
    }
}

extension GraphQLError.Extensions {
    public enum Category: String, Codable {
        case graphql
        case user
        case server
    }
}

extension GraphQLError: LocalizedError {
    public var localizedDescription: String {
        return self.message
    }
    public var errorDescription: String? {
        return self.message
    }
}

extension GraphQLError: CustomNSError {
    public static var errorDomain: String {
        return "Graphene.GraphQLError"
    }
    public var errorUserInfo: [String: Any] {
        var result = [String: Any]()
        if let locations = self.locations {
            result["locations"] = locations
        }
        if let path = self.path {
            result["path"] = path
        }
        if let extensions = self.extensions {
            result["extensions"] = extensions
        }
        return result
    }
}
