//
//  SomeChangeSet.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 12.03.2021.
//

import Foundation

public protocol SomeChangeSet: CustomDebugStringConvertible, RandomAccessCollection where Indices == Range<Int>,
    SubSequence == Array<Change>.SubSequence
{
    var changes: [Change] { get }
}

public extension SomeChangeSet {

    var startIndex: Index { self.changes.startIndex }
    var endIndex: Index { self.changes.endIndex }

    subscript(bounds: Range<Index>) -> SubSequence {
        self.changes[bounds]
    }

    subscript(position: Index) -> Element {
        self.changes[position]
    }

    func index(after i: Index) -> Index {
        self.changes.index(after: i)
    }

    func index(before i: Index) -> Index {
        self.changes.index(before: i)
    }

    func first(where key: String) -> Change? {
        self.first(where: { $0.key == key })
    }

}

public extension SomeChangeSet {
    var debugDescription: String {
        let changesDesc = self.enumerated().map({
            $1.description(padding: 1, isLast: $0 == self.changes.endIndex - 1)
        })
        return String(describing: Self.self) + (changesDesc.isEmpty ? "()" : "(\n\(changesDesc.joined(separator: "\n"))\n)")
    }
}

extension SomeChangeSet {
    static func searchChanges(oldFields: Variables, newFields: Variables) -> [Change] {
        var changes: [Change] = []
        // Compare earch new field with old field
        for newField in newFields {

            // If old fields doesnt exists, add FieldChange[ null -> newValue ]
            guard let oldField = oldFields.first(where: { $0.key == newField.key }) else {
                changes.append(FieldChange(key: newField.key, oldValue: nil, newValue: newField.value))
                continue
            }

            // If old or new value is null
            guard let oldValue = oldField.value, let newValue = newField.value else {
                if (oldField.value == nil && newField.value != nil) || (oldField.value != nil && newField.value == nil) {
                    changes.append(FieldChange(key: newField.key, oldValue: oldField.value, newValue: newField.value))
                }
                continue
            }

            // Compare comparable object
            if let oldValue = oldValue as? EncodableVariable, let newValue = newValue as? EncodableVariable {
                let childChangeSet = AnyChangeSet(source: oldValue, target: newValue)
                if !childChangeSet.changes.isEmpty {
                    let rootChange = RootChange(key: newField.key, childChanges: childChangeSet.changes)
                    changes.append(rootChange)
                }
                continue
            }

            // Compare identifiable arrays
            if let oldValues = (oldValue as Any) as? [AnyChangeSetIdentifiableVariable],
               let newValues = (newValue as Any) as? [AnyChangeSetIdentifiableVariable]
            {
                let oldDict = oldValues.reduce(into: Variables()) { $0["\($1.anyChangeSetIdentifier)"] = $1 }
                var newDict = newValues.reduce(into: Variables()) { $0["\($1.anyChangeSetIdentifier)"] = $1 }
                let oldIdentifiers = Set(oldValues.map(\.anyChangeSetIdentifier))
                let newIdentifiers = Set(newValues.map(\.anyChangeSetIdentifier))
                for removedIdentifier in oldIdentifiers.subtracting(newIdentifiers) {
                    newDict["\(removedIdentifier)"] = Variable?.none
                }
                let childChanges = self.searchChanges(oldFields: oldDict, newFields: newDict)
                let childChangeSet = AnyChangeSet(changes: childChanges)
                if !childChangeSet.changes.isEmpty {
                    let rootChange = RootChange(key: newField.key, childChanges: childChangeSet.changes)
                    changes.append(rootChange)
                }
                continue
            }

            // Compare hashable object
            if let oldValue = (oldValue as Any) as? AnyHashable, let newValue = (newValue as Any) as? AnyHashable {
                if oldValue != newValue {
                    let fieldChange = FieldChange(key: newField.key, oldValue: oldField.value, newValue: newField.value)
                    changes.append(fieldChange)
                }
                continue
            }

            // Any other cases
            let fieldChange = FieldChange(key: newField.key, oldValue: oldField.value, newValue: newField.value)
            changes.append(fieldChange)

        }
        return changes
    }

}
