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

public extension EncodableVariable {

    var json: Any? {
        self.variables.json
    }

    var variables: Variables {
        let encoder = VariableEncoder()
        self.encode(to: encoder)
        return encoder.variables
    }

    func encode(to encoder: VariableEncoder, with changeSet: ChangeSet<Self>?) {
        encoder.apply(changeSet: changeSet)
        self.encode(to: encoder)
    }

    func compare(with anotherInstance: Self) -> ChangeSet<Self> {
        ChangeSet(source: anotherInstance, target: self)
    }

    func equal(to anotherInstance: Self) -> Bool {
        self.compare(with: anotherInstance).isEmpty
    }

}
