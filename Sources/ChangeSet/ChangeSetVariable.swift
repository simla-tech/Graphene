//
//  ChangeSetVariable.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 05.02.2021.
//

import Foundation

internal struct ChangeSetVariable: EncodableVariable {
    
    let variable: EncodableVariable
    let changeSet: AnyChangeSet
    
    func encode(to encoder: VariableEncoder) {
        encoder.apply(changeSet: self.changeSet)
        self.variable.encode(to: encoder)
    }
    
}
