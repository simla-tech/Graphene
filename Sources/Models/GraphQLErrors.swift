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

   public var startIndex: Int { return self.errors.startIndex }
   public var endIndex: Int { return self.errors.endIndex }

   public subscript(index: Int) -> GraphQLError {
       return self.errors[index]
   }

   public func index(after i: Int) -> Int {
       return self.errors.index(after: i)
   }

}

extension GraphQLErrors: CustomNSError {

    public static var errorDomain: String { "GraphQLErrors" }

    public var errorUserInfo: [String: Any] {
        return ["errors": self.errors.map({ $0.errorUserInfo })]
    }

}

extension GraphQLErrors: LocalizedError {

    public var errorDescription: String? {
        return self.errors.map(\.localizedDescription).joined(separator: ", ")
    }

}
