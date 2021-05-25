//
//  Variables.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 28.01.2021.
//

import Foundation

public protocol Variable {
    var json: Any? { get }
}

extension RawRepresentable where Self: Variable {
    public var json: Any? {
        return self.rawValue
    }
}

public typealias Variables = [String: Variable?]

// swiftlint:disable:next syntactic_sugar
extension Dictionary: Variable where Key == String, Value == Optional<Variable> {
    public var json: Any? {
        return self.mapValues({ $0?.json })
    }
}

extension Array: Variable where Element: Variable {
    public var json: Any? {
        return self.map({ $0.json })
    }
}

extension String: Variable {
    public var json: Any? {
        return self
    }
}

extension Bool: Variable {
    public var json: Any? {
        return self
    }
}

extension Int: Variable {
    public var json: Any? {
        return self
    }
}

extension Double: Variable {
    public var json: Any? {
        return self
    }
}

extension Float: Variable {
    public var json: Any? {
        return self
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
}
