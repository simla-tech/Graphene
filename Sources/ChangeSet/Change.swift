//
//  Change.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 28.01.2021.
//

import Foundation

public protocol Change: CustomDebugStringConvertible {
    var key: String { get }
    func description(padding: Int, isLast: Bool) -> String
}

public extension Change {
    var debugDescription: String {
        self.description(padding: 0, isLast: true)
    }
}

public struct FieldChange: Change, Hashable, Equatable {

    public var key: String
    public let oldValue: Variable?
    public let newValue: Variable?

    public static func == (lhs: FieldChange, rhs: FieldChange) -> Bool {
        lhs.key == rhs.key
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.key)
    }

    public func description(padding: Int, isLast: Bool) -> String {
        var paddingStr = ""
        for _ in 0 ..< padding { paddingStr += "  " }
        let oldValue = self.oldValue?.json ?? "nil"
        let newValue = self.newValue?.json ?? "nil"
        return [
            paddingStr, "\(self.key):", "\(oldValue)", "→", "\(newValue)\(isLast ? "" : ",")"
        ].joined(separator: " ")
    }

}

public struct RootChange: Change, Hashable, Equatable {

    public var key: String
    public let childChanges: [Change]

    public static func == (lhs: RootChange, rhs: RootChange) -> Bool {
        lhs.key == rhs.key
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.key)
    }

    public func description(padding: Int, isLast: Bool) -> String {
        var paddingStr = ""
        for _ in 0 ..< padding { paddingStr += "  " }
        var result = ["\(paddingStr) \"\(self.key)\" : {"]
        for (index, childChange) in self.childChanges.enumerated() {
            result.append(childChange.description(padding: padding + 1, isLast: index == self.childChanges.endIndex - 1))
        }
        result.append("\(paddingStr) }\(isLast ? "" : ",")")
        return result.joined(separator: "\n")
    }

}
