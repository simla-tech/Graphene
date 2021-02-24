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
    
    public func encode(to encoder: VariableEncoder, with changeSet: ChangeSet?) {
        encoder.apply(changeSet: changeSet)
        self.encode(to: encoder)
    }
    
}
