//
//  Arguments.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 22.01.2021.
//

import Foundation

public typealias Arguments = KeyValuePairs<String, Argument>

public protocol Argument {
    var rawValue: String { get }
}

extension KeyValuePairs: Argument where Key == String, Value == Argument {
    public var rawValue: String {
        return "{\(map({ "\($0): \($1.rawValue)" }).joined(separator: ","))}"
    }
}

extension Dictionary: Argument where Key == String, Value == Argument {
    public var rawValue: String {
        return "{\(map({ "\($0): \($1.rawValue)" }).joined(separator: ","))}"
    }
}

extension String: Argument {
    public var rawValue: String {
        return String(format: "\"%@\"", self.escaped)
    }
}

extension Bool: Argument {
    public var rawValue: String {
        return String(self)
    }
}

extension Int: Argument {
    public var rawValue: String {
        return "\(self)"
    }
}

extension Double: Argument {
    public var rawValue: String {
        return "\(self)"
    }
}

extension Float: Argument {
    public var rawValue: String {
        return "\(self)"
    }
}

extension Array: Argument where Element: Argument {
    public var rawValue: String {
        return "[\(self.map({ $0.rawValue }).joined(separator: ","))]"
    }
}

extension Optional: Argument where Wrapped: Argument {
    public var rawValue: String {
        switch self {
        case .some(let value):
            return value.rawValue
        case .none:
            return "null"
        }
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
