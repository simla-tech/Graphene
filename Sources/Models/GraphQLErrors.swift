//
//  GraphQLErrors.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 11.02.2021.
//

import Foundation

public struct GraphQLErrors: Error, Decodable {

    public let errors: [GraphQLError]

    public init(_ errors: [GraphQLError]) {
        self.errors = errors
    }

}

extension GraphQLErrors: Collection {

    public var startIndex: Int { self.errors.startIndex }
    public var endIndex: Int { self.errors.endIndex }

    public subscript(index: Int) -> GraphQLError {
        self.errors[index]
    }

    public func index(after i: Int) -> Int {
        self.errors.index(after: i)
    }

}

extension GraphQLErrors: CustomNSError {

    public static var errorDomain: String { "GraphQLErrors" }

    public var errorUserInfo: [String: Any] {
        ["errors": self.errors.map(\.errorUserInfo)]
    }

}

extension GraphQLErrors: LocalizedError {

    public var errorDescription: String? {
        self.errors.map(\.localizedDescription).joined(separator: ", ")
    }

}
