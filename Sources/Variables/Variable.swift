//
//  Variables.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 28.01.2021.
//

import Foundation

public protocol Variable {
    var json: Any? { get }
    static var variableType: String { get }
}

public extension Variable {
    static var variableType: String {
        String(describing: self) + "!"
    }
}

public extension RawRepresentable where Self: Variable {
    var json: Any? {
        self.rawValue
    }
}

public typealias Variables = [String: Variable?]

extension [String: Variable?]: Variable {
    public var json: Any? {
        self.mapValues({ $0?.json })
    }
}

extension Array: Variable where Element: Variable {
    public var json: Any? {
        self.map(\.json)
    }

    public static var variableType: String {
        "[\(Element.variableType)]!"
    }
}

extension String: Variable {
    public var json: Any? {
        self
    }
}

extension Bool: Variable {
    public var json: Any? {
        self
    }

    public static var variableType: String {
        "Boolean!"
    }
}

extension Int: Variable {
    public var json: Any? {
        self
    }
}

extension Double: Variable {
    public var json: Any? {
        self
    }
}

extension Float: Variable {
    public var json: Any? {
        self
    }

    public static var variableType: String {
        "Double!"
    }
}

extension Optional: Variable where Wrapped: Variable {
    public var json: Any? {
        switch self {
        case .some(let value):
            return value.json
        case .none:
            return nil
        }
    }

    public static var variableType: String {
        if Wrapped.variableType.last == "!" {
            return String(Wrapped.variableType.dropLast())
        } else {
            return Wrapped.variableType
        }
    }
}
