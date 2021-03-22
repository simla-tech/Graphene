//
//  GraphQLErrors.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 11.02.2021.
//

import Foundation

public struct GraphQLErrors: LocalizedError, Codable {
    
    private let errors: [GraphQLError]
    
    internal init(_ errors: [GraphQLError]) {
        self.errors = errors
    }
    
    public var localizedDescription: String {
        return self.errors.map({ $0.localizedDescription }).joined(separator: ", ")
    }
    public var errorDescription: String? {
        return self.localizedDescription
    }
    
}

extension GraphQLErrors: Collection {
    
    // The upper and lower bounds of the collection, used in iterations
    public var startIndex: Int { return self.errors.startIndex }
    public var endIndex: Int { return self.errors.endIndex }
    
    // Required subscript, based on a dictionary index
    public subscript(index: Int) -> GraphQLError {
        return self.errors[index]
    }
    
    // Method that returns the next index when iterating
    public func index(after i: Int) -> Int {
        return self.errors.index(after: i)
    }
    
}

extension GraphQLErrors: CustomNSError {
    public static var errorDomain: String {
        return "Graphene.GraphQLErrors"
    }
    public var errorUserInfo: [String: Any] {
        return ["errors": self.errors.map({ $0.errorUserInfo })]
    }
}
