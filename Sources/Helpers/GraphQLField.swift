//
//  GraphQLField.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 12.10.2021.
//  Copyright © 2021 DIGITAL RETAIL TECHNOLOGIES, S.L. All rights reserved.
//

import Foundation

private func graphQLFieldUnwrapErrorString(operationName: String?, path: String) -> String {
    var result = path
    if let operationName {
        result += " from \"\(operationName)\" operation"
    }
    return "Value at path \(result) doesn't exists"
}

public enum GraphQLField<Wrapped> {

    case some(Wrapped)
    case empty(operationName: String?, path: String)

    public func map<U>(_ transform: (Wrapped) throws -> U) rethrows -> GraphQLField<U> {
        switch self {
        case .empty(let operationName, let path):
            return .empty(operationName: operationName, path: path)
        case .some(let value):
            return .some(try transform(value))
        }
    }

    public var unsafelyUnwrapped: Wrapped {
        switch self {
        case .some(let value):
            return value
        case .empty(let operationName, let path):
            fatalError(graphQLFieldUnwrapErrorString(operationName: operationName, path: path))
        }
    }

    public var value: Wrapped? {
        switch self {
        case .some(let wrapped):
            return wrapped
        case .empty:
            return nil
        }
    }

    public func get(function: StaticString = #function, file: StaticString = #file, line: UInt = #line) throws -> Wrapped {
        switch self {
        case .empty(let operationName, let path):
            throw GraphQLFieldUnwrapError(operationName: operationName, path: path, function: function, file: file, line: line)
        case .some(let wrapped):
            return wrapped
        }
    }

}

public struct GraphQLFieldUnwrapError: LocalizedError, CustomNSError {

    public let operationName: String?
    public let path: String
    public let function: StaticString
    public let file: StaticString
    public let line: UInt

    public var errorDescription: String? {
        graphQLFieldUnwrapErrorString(operationName: self.operationName, path: self.path)
    }

    public var errorUserInfo: [String: Any] {
        [
            "path": self.path,
            "function": self.function,
            "line": self.line,
            "file": self.file,
            "operationName": self.operationName ?? "Unknown"
        ]
    }

}

private extension GraphQLField {
    struct EmptyInfo: Codable {
        let operationName: String?
        let path: String
    }
}

extension GraphQLField: Decodable where Wrapped: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        do {
            self = .some(try container.decode(Wrapped.self))
        } catch {
            if let emptyInfo = try? container.decode(EmptyInfo.self) {
                self = .empty(operationName: emptyInfo.operationName, path: emptyInfo.path)
            } else {
                throw error
            }
        }
    }
}

extension GraphQLField: Encodable where Wrapped: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .some(let wrapped):
            try container.encode(wrapped)
        case .empty(let operationName, let path):
            try container.encode(EmptyInfo(operationName: operationName, path: path))
        }
    }
}

extension GraphQLField: Equatable where Wrapped: Hashable {
    public static func == (lhs: GraphQLField<Wrapped>, rhs: GraphQLField<Wrapped>) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}

extension GraphQLField: Hashable where Wrapped: Hashable {
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .some(let value):
            hasher.combine(value)
        case .empty:
            hasher.combine(0)
        }
    }
}

extension GraphQLField: CustomStringConvertible {
    public var description: String {
        switch self {
        case .some(let wrapped):
            return ".some(\(wrapped))"
        case .empty(_, let path):
            return ".empty(\(path))"
        }
    }
}

public extension KeyedDecodingContainer {

    func decode<T>(_ type: GraphQLField<T>.Type, forKey key: K) throws -> GraphQLField<T> where T: Decodable {
        do {
            return .some(try self.decode(T.self, forKey: key))
        } catch DecodingError.keyNotFound(let key, _) {
            let userInfo = try? self.superDecoder().userInfo
            let path = (self.codingPath + [key]).map({ key -> String in
                if key.intValue != nil { return "[*]" }
                return key.stringValue
            }).joined(separator: ".")
            return .empty(operationName: userInfo?[.operationName] as? String, path: path)
        } catch {
            throw error
        }
    }
}
