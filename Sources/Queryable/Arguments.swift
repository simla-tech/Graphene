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

public extension Argument {
    static func raw(_ value: String) -> Argument {
        .init(rawValue: value)
    }
}

public extension Argument where Value: Variable {

    static func reference<Root: QueryVariables>(to value: KeyPath<Root, Value>) -> Argument<Value> {
        if let i = Root.allKeys.firstIndex(of: value) {
            return Argument(index: i)
        } else {
            fatalError("Can't find reference to \(value)")
        }
    }

    static func reference<Root: QueryVariables>(to value: KeyPath<Root, Value?>) -> Argument<Value> {
        if let i = Root.allKeys.firstIndex(of: value) {
            return Argument(index: i)
        } else {
            fatalError("Can't find reference to \(value)")
        }
    }

}

extension Argument {
    init(index: Int) {
        self.init(rawValue: "$\(argumentIdentifier(for: index))")
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
        self.rawValue = "[\(elements.map(\.rawValue).joined(separator: ","))]"
    }
}

extension Argument: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (AnyHashable, Argument<Value>)...) {
        self.rawValue = "{\(elements.map({ "\($0): \($1.rawValue)" }).joined(separator: ","))}"
    }
}

extension String {
    var escaped: String {
        var res = ""
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

func argumentIdentifier(for index: Int) -> String {
    String(format: "var%03d", index + 1)
}
