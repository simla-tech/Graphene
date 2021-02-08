//
//  GraphQLError.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 28.01.2021.
//

import Foundation

public struct GraphQLError: Error {
    
    public struct Location {
        public var line: Int
        public var column: Int
    }
    
    public var message: String
    public var rawData: [String: Any]
    public var locations: [Location]?
    public var path: [String]?
    public var extensions: Any?
    
    init?(_ json: Any) {

        guard let json = json as? [String: Any],
            let message = json["message"] as? String else {
            return nil
        }
        
        self.rawData = json
        self.message = message
        if let locations = json["locations"] as? [[String: Int]] {
            self.locations = locations.compactMap({
                if let line = $0["line"], let column = $0["column"] {
                    return Location(line: line, column: column)
                }
                return nil
            })
        }
        
        self.path = json["path"] as? [String]
        self.extensions = json["extensions"]
        
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
        return self.rawData
    }
}
