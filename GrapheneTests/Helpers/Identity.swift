//
//  Identity.swift
//  GrapheneTests
//
//  Created by Ilya Kharlamov on 03.02.2021.
//

import Foundation
@testable import Graphene

// MARK: - Core API
/// Protocol used to mark a given type as being identifiable, meaning
/// that it has a type-safe identifier, backed by a raw value, which
/// defaults to String.
public protocol Identifiable: Graphene.Identifiable {
    /// Shorthand type alias for this type's identifier.
    typealias ID = Identifier<Self>
    /// The ID of this instance.
    var id: ID { get }
}

extension Identifiable {
    public var identifier: ID {
        return self.id
    }
}

/// A type-safe identifier for a given `Value`, backed by a raw value.
/// When backed by a `Codable` type, `Identifier` also becomes codable,
/// and will be encoded into a single value according to its raw value.
public struct Identifier<Value: Identifiable>: Hashable {
    
    /// The raw value that is backing this identifier.
    public let idValue: String?
    public let vendorValue: UUID
    
    public var isVendorValue: Bool {
        return self.idValue == nil
    }
        
    /// Initialize an instance with a raw value.
    public init(_ value: String? = nil) {
        self.idValue = value
        self.vendorValue = UUID()
    }
    
    public init<T: Identifiable>(_ someIdentifier: Identifier<T>) {
        self.idValue = someIdentifier.idValue
        self.vendorValue = someIdentifier.vendorValue
    }
    
    public func hash(into hasher: inout Hasher) {
        if let idValue = self.idValue {
            hasher.combine(idValue)
        } else {
            hasher.combine(self.vendorValue)
        }
    }
    
}

// MARK: - String literal support

extension Identifier: ExpressibleByUnicodeScalarLiteral {
    public init(unicodeScalarLiteral value: String.UnicodeScalarLiteralType) {
        self.idValue = .init(unicodeScalarLiteral: value)
        self.vendorValue = UUID()
    }
}

extension Identifier: ExpressibleByExtendedGraphemeClusterLiteral {
    public init(extendedGraphemeClusterLiteral value: String.ExtendedGraphemeClusterLiteralType) {
        self.idValue = .init(extendedGraphemeClusterLiteral: value)
        self.vendorValue = UUID()
    }
}

extension Identifier: ExpressibleByStringLiteral {
    public init(stringLiteral value: String.StringLiteralType) {
        self.idValue = .init(stringLiteral: value)
        self.vendorValue = UUID()
    }
}

// MARK: - Compiler-generated protocol support

extension Identifier: Equatable {
    public static func == (lhs: Identifier, rhs: Identifier) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}

// MARK: - Codable support

extension Identifier: Codable {
    
    public init(from decoder: Decoder) throws {
        self.vendorValue = UUID()
        if let container = try? decoder.singleValueContainer() {
            self.idValue = try? container.decode(String.self)
        } else {
            self.idValue = nil
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }
    
}

extension Identifier: Argument {
    public var rawValue: String {
        if let idValue = self.idValue {
            return "\(idValue)"
        } else {
            return "null"
        }
    }
}

extension Identifier: Variable {
    public var json: Any? {
        return self.idValue
    }
}

extension Identifier: SchemaType {
    public static var schemaType: String {
        return "IDInt"
    }
}

extension Identifier: CustomStringConvertible {
    public var description: String {
        if let idValue = self.idValue {
            return idValue
        } else {
            return "\(self.vendorValue.uuidString) (Vendor)"
        }
    }
}
