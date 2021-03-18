//
//  EncodableVariable.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 28.01.2021.
//

import Foundation

public protocol EncodableVariable: Variable {
    func encode(to encoder: VariableEncoder)
}

extension EncodableVariable {
    
    public var json: Any? {
        return self.variables.json
    }
    
    public var variables: Variables {
        let encoder = VariableEncoder()
        self.encode(to: encoder)
        return encoder.variables
    }
    
    public func encode(to encoder: VariableEncoder, with changeSet: ChangeSet<Self>?) {
        encoder.apply(changeSet: changeSet)
        self.encode(to: encoder)
    }
    
    public func compare(with anotherInstance: Self) -> ChangeSet<Self> {
        return ChangeSet(source: anotherInstance, target: self)
    }
    
    public func equal(to anotherInstance: Self) -> Bool {
        return self.compare(with: anotherInstance).isEmpty
    }
    
}
