//
//  ChangeSet.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 28.01.2021.
//

import Foundation

public struct ChangeSet<T: EncodableVariable>: Codable, Collection, SomeChangeSet {
    
    public let changes: [Change]
    
    public init(from decoder: Decoder) throws {
        self.changes = []
    }
    
    public func encode(to encoder: Encoder) throws {}

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
