//
//  SomeChangeSet.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 12.03.2021.
//

import Foundation

public protocol SomeChangeSet: CustomDebugStringConvertible, RandomAccessCollection where Indices == Range<Int>, SubSequence == Array<Change>.SubSequence {
    var changes: [Change] { get }
}

extension SomeChangeSet {

    public var startIndex: Index { return self.changes.startIndex }
    public var endIndex: Index { return self.changes.endIndex }

    public subscript(bounds: Range<Index>) -> SubSequence {
        return self.changes[bounds]
    }

    public subscript(position: Index) -> Element {
        return self.changes[position]
    }

    public func index(after i: Index) -> Index {
        return self.changes.index(after: i)
    }

    public func index(before i: Index) -> Index {
        return self.changes.index(before: i)
    }

    public func contains(where key: String) -> Bool {
        return self.contains(where: { $0.key == key })
    }

    public func first(where key: String) -> Change? {
        return self.first(where: { $0.key == key })
    }

}

extension SomeChangeSet {
    public var debugDescription: String {
        let changesDesc = self.enumerated().map({
            $1.description(padding: 1, isLast: $0 == self.changes.endIndex - 1)
        })
        return "{\n\(changesDesc.joined(separator: "\n"))\n}"
    }
}

extension SomeChangeSet {
    internal static func searchChanges(oldFields: Variables, newFields: Variables) -> [Change] {
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
            if let oldValues = (oldValue as Any) as? [AnyIdentifiableVariable], let newValues = (newValue as Any) as? [AnyIdentifiableVariable] {
                let oldDict = oldValues.reduce(into: Variables()) { $0["\($1.anyIdentifier)"] = $1 }
                let newDict = newValues.reduce(into: Variables()) { $0["\($1.anyIdentifier)"] = $1 }
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
