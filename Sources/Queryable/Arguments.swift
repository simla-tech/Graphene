//
//  Arguments.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 22.01.2021.
//

import Foundation

public typealias AnyArguments = [String: AnyArgument?]

public protocol AnyArgument {
    var rawValue: String { get }
}

public struct Argument<Value>: AnyArgument {
    public var rawValue: String
}

extension Argument where Value: AnyArgument {
    public init(value: Value) {
        self.rawValue = value.rawValue
    }
}

extension Argument where Value: Variable {

    public static func reference<Root: QueryVariables>(to value: KeyPath<Root, Value>) -> Argument<Value> {
        return .init(rawValue: "$\(value.identifier)")
    }

    public static func reference<Root: QueryVariables>(to value: KeyPath<Root, Value?>) -> Argument<Value> {
        return .init(rawValue: "$\(value.identifier)")
    }

}

extension Argument: ExpressibleByIntegerLiteral where Value == IntegerLiteralType {
    public init(integerLiteral value: IntegerLiteralType) {
        self.rawValue = "\(value)"
    }
}

extension Argument: ExpressibleByUnicodeScalarLiteral where Value == String.UnicodeScalarLiteralType {
    public init(unicodeScalarLiteral value: String.UnicodeScalarLiteralType) {
        self.rawValue = String(format: "\"%@\"", value.escaped)
    }
}

extension Argument: ExpressibleByExtendedGraphemeClusterLiteral where Value == String.ExtendedGraphemeClusterLiteralType {
    public init(extendedGraphemeClusterLiteral value: String.ExtendedGraphemeClusterLiteralType) {
        self.rawValue = String(format: "\"%@\"", value.escaped)
    }
}

extension Argument: ExpressibleByStringLiteral where Value == StringLiteralType {
    public init(stringLiteral value: StringLiteralType) {
        self.rawValue = String(format: "\"%@\"", value.escaped)
    }
}

extension Argument: ExpressibleByFloatLiteral {
    public init(floatLiteral value: FloatLiteralType) {
        self.rawValue = "\(value)"
    }
}

extension Argument: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: BooleanLiteralType) {
        self.rawValue = String(value)
    }
}

extension Argument: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Argument<Value>...) {
        self.rawValue = "[\(elements.map({ $0.rawValue }).joined(separator: ","))]"
    }
}

extension Argument: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (AnyHashable, Argument<Value>)...) {
        self.rawValue = "{\(elements.map({ "\($0): \($1.rawValue)" }).joined(separator: ","))}"
    }
}

extension String {
    internal var escaped: String {
        var res: String = ""
        for char in self {
            switch char {
            case "\\": res += "\\\\"
            case "\n": res += "\\n"
            case "\r": res += "\\r"
            case "\r\n": res += "\\r\\n"
            case "\"": res += "\\\""
            default: res += "\(char)"
            }
        }
        return res
    }
}
