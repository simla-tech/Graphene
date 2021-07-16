//
//  AnyChangeSet.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 12.03.2021.
//

import Foundation

internal struct AnyChangeSet: SomeChangeSet {

    typealias SubSequence = ArraySlice<Change>

    let changes: [Change]

    init(changes: [Change]) {
        self.changes = changes
    }

    init?<C: SomeChangeSet>(_ anotherChangeSet: C?) {
        guard let anotherChangeSet = anotherChangeSet else { return nil }
        self.changes = anotherChangeSet.changes
    }

    init(source: EncodableVariable, target: EncodableVariable) {

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
