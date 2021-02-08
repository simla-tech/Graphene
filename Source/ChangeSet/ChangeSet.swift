//
//  ChangeSet.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 28.01.2021.
//

import Foundation

public struct ChangeSet: Codable, Collection {
    
    private let changes: [Change]
    
    public init(from decoder: Decoder) throws {
        try self.init(from: decoder)
    }
    
    public func encode(to encoder: Encoder) throws {}

    internal init(changes: [Change]) {
        self.changes = changes
    }
    
    public init(source: EncodableVariable, target: EncodableVariable) {
        
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
    
    private static func searchChanges(oldFields: Variables, newFields: Variables) -> [Change] {
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
                let childChangeSet = ChangeSet(source: oldValue, target: newValue)
                if !childChangeSet.isEmpty {
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
                let childChangeSet = ChangeSet(changes: childChanges)
                if !childChangeSet.isEmpty {
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
    
    // MARK: - Collection

    // The upper and lower bounds of the collection, used in iterations
    public var startIndex: Int { return self.changes.startIndex }
    public var endIndex: Int { return self.changes.endIndex }
    
    // Required subscript, based on a dictionary index
    public subscript(index: Int) -> Change {
        return self.changes[index]
    }
    
    // Method that returns the next index when iterating
    public func index(after i: Int) -> Int {
        return self.changes.index(after: i)
    }
    
}

extension ChangeSet: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        let changesDesc = self.changes.enumerated().map({
            $1.description(padding: 1, isLast: $0 == self.changes.endIndex - 1)
        })
        return "{\n\(changesDesc.joined(separator: "\n"))\n}"
    }
    
}



