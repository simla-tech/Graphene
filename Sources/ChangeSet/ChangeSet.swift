//
//  ChangeSet.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 28.01.2021.
//

import Foundation

public struct ChangeSet<T: EncodableVariable>: SomeChangeSet {

    public typealias SubSequence = ArraySlice<Change>

    public let changes: [Change]

    internal init(changes: [Change]) {
        self.changes = changes
    }

    public init(source: T, target: T) {

        // Get new fields
        let newEncoder = VariableEncoder()
        target.encode(to: newEncoder)
        let newFields = newEncoder.variables

        // Get old fields
        let oldEncoder = VariableEncoder()
        source.encode(to: oldEncoder)
        let oldFields = oldEncoder.variables

        let changes = Self.searchChanges(oldFields: oldFields, newFields: newFields)
        self.init(changes: changes)

    }

}

extension ChangeSet: Codable {
    public init(from decoder: Decoder) throws {
        self.changes = []
    }

    public func encode(to encoder: Encoder) throws {}
}
