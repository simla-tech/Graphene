//
//  GraphQLErrors.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 11.02.2021.
//

import Foundation

public protocol ArrayError: Collection, LocalizedError, CustomNSError {
    associatedtype ErrorType: CustomNSError
    var errors: [ErrorType] { get }
}

extension ArrayError {

    // The upper and lower bounds of the collection, used in iterations
    public var startIndex: Int { return self.errors.startIndex }
    public var endIndex: Int { return self.errors.endIndex }

    // Required subscript, based on a dictionary index
    public subscript(index: Int) -> ErrorType {
        return self.errors[index]
    }

    // Method that returns the next index when iterating
    public func index(after i: Int) -> Int {
        return self.errors.index(after: i)
    }

    public static var errorDomain: String { "ArrayError.\(ErrorType.errorDomain)" }

    public var errorUserInfo: [String: Any] {
        return ["errors": self.errors.map({ $0.errorUserInfo })]
    }

    public var errorDescription: String? {
        return self.errors.map(\.localizedDescription).joined(separator: ", ")
    }

}

public struct GraphQLErrors: ArrayError, Decodable {

    public let errors: [GraphQLError]

    public init(_ errors: [GraphQLError]) {
        self.errors = errors
    }

}
