//
//  IfPresent.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 12.10.2021.
//  Copyright © 2021 RetailDriver LLC. All rights reserved.
//

import Foundation

private func ifPresentErrorString(operationName: String?, path: [CodingKey]) -> String {
    var result = path.map({ key -> String in
        if let intValue = key.intValue {
            return "[\(intValue)]"
        } else {
            return key.stringValue
        }
    }).joined(separator: ".")
    if let operationName = operationName {
        result += " from \"\(operationName)\" operation"
    }
    return "Value at path \(result) doen't exists"
}

public enum IfPresent<Wrapped> {

    case some(Wrapped)
    case empty(operationName: String?, path: [CodingKey])

    public func map<U>(_ transform: (Wrapped) throws -> U) rethrows -> IfPresent<U> {
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
            fatalError(ifPresentErrorString(operationName: operationName, path: path))
        }
    }

    public func get(function: StaticString = #function, file: StaticString  = #file, line: UInt  = #line) throws -> Wrapped {
        switch self {
        case .empty(let operationName, let path):
            throw IfPresentError(operationName: operationName, path: path, function: function, file: file, line: line)
        case .some(let wrapped):
            return wrapped
        }
    }

}

public struct IfPresentError: LocalizedError, CustomNSError {

    public let operationName: String?
    public let path: [CodingKey]
    public let function: StaticString
    public let file: StaticString
    public let line: UInt

    public var errorDescription: String? {
        return ifPresentErrorString(operationName: self.operationName, path: self.path)
    }

    public var errorUserInfo: [String: Any] {
        return [
            "path": self.path.map({ key -> String in
                if let intValue = key.intValue {
                    return "[\(intValue)]"
                } else {
                    return key.stringValue
                }
            }).joined(separator: "."),
            "function": self.function,
            "line": self.line,
            "file": self.file,
            "operationName": self.operationName ?? "Unknown"
        ]
    }

}

extension IfPresent: Decodable where Wrapped: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self = .some(try container.decode(Wrapped.self))
    }
}

extension IfPresent: Encodable where Wrapped: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(try self.get())
    }
}

extension IfPresent: Equatable where Wrapped: Hashable {
    public static func == (lhs: IfPresent<Wrapped>, rhs: IfPresent<Wrapped>) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}

extension IfPresent: Hashable where Wrapped: Hashable {
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .some(let value):
            hasher.combine(value)
        case .empty:
            hasher.combine(0)
        }
    }
}

extension KeyedDecodingContainer {
    public func decode<T>(_ type: IfPresent<T>.Type, forKey key: K) throws -> IfPresent<T> where T: Decodable {
        if let value = try decodeIfPresent(type, forKey: key) {
            return value
        } else {
            let userInfo = try? self.superDecoder().userInfo
            return .empty(operationName: userInfo?[.operationName] as? String, path: self.codingPath + [key])
        }
    }
}
