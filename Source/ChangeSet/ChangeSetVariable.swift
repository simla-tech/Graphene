//
//  ChangeSetVariable.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 05.02.2021.
//

import Foundation

public struct ChangeSetVariable: EncodableVariable {
    
    public let variable: EncodableVariable
    public let changeSet: ChangeSet
    
    public func encode(to encoder: VariableEncoder) {
        encoder.apply(changeSet: self.changeSet)
        self.variable.encode(to: encoder)
    }
    
}
