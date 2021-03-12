//
//  SomeChangeSet.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 12.03.2021.
//

import Foundation

public protocol SomeChangeSet {
    var changes: [Change] { get }
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
    
    public func contains(where key: AnyHashable) -> Bool {
        return self.changes.contains(where: { $0.key == key })
    }
    
    public func first(where key: AnyHashable) -> Change? {
        return self.changes.first(where: { $0.key == key })
    }
    
}
