//
//  IfPresent.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 12.10.2021.
//  Copyright © 2021 DIGITAL RETAIL TECHNOLOGIES, S.L. All rights reserved.
//

import Foundation

private func ifPresentErrorString(operationName: String?, path: String) -> String {
    var result = path
    if let operationName = operationName {
        result += " from \"\(operationName)\" operation"
    }
    return "Value at path \(result) doen't exists"
}

public enum IfPresent<Wrapped> {

    case some(Wrapped)
    case empty(operationName: String?, path: String)

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
    public let path: String
    public let function: StaticString
    public let file: StaticString
    public let line: UInt

    public var errorDescription: String? {
        return ifPresentErrorString(operationName: self.operationName, path: self.path)
    }

    public var errorUserInfo: [String: Any] {
        return [
            "path": self.path,
            "function": self.function,
            "line": self.line,
            "file": self.file,
            "operationName": self.operationName ?? "Unknown"
        ]
    }

}

private extension IfPresent {
    struct EmptyInfo: Codable {
        let operationName: String?
        let path: String
    }
}

extension IfPresent: Decodable where Wrapped: Decodable {
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

extension IfPresent: Encodable where Wrapped: Encodable {
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

extension IfPresent: CustomStringConvertible {
    public var description: String {
        switch self {
        case .some(let wrapped):
            return ".some(\(wrapped))"
        case .empty(_, let path):
            return ".empty(\(path))"
        }
    }
}

extension KeyedDecodingContainer {
    public func decode<T>(_ type: IfPresent<T>.Type, forKey key: K) throws -> IfPresent<T> where T: Decodable {
        if let value = try decodeIfPresent(type, forKey: key) {
            return value
        } else {
            let userInfo = try? self.superDecoder().userInfo
            let path = (self.codingPath + [key]).map({ key -> String in
                if let intValue = key.intValue {
                    return "[\(intValue)]"
                } else {
                    return key.stringValue
                }
            }).joined(separator: ".")
            return .empty(operationName: userInfo?[.operationName] as? String, path: path)
        }
    }
}
