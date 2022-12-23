//
//  VariableEncoder.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 28.01.2021.
//

import Foundation

public class VariableEncoder {

    internal var variables = Variables()
    internal private(set) var changeSet: AnyChangeSet?

    internal init() { }

    public func apply<C: SomeChangeSet>(changeSet: C?) {
        if self.changeSet == nil {
            self.changeSet = AnyChangeSet(changeSet)
        }
    }

    public func container() -> VariableEncoderContainer {
        VariableEncoderContainer(self)
    }

    public func container<Key>(keyedBy type: Key.Type) -> VariableEncoderKeyedContainer<Key> where Key: CodingKey {
        VariableEncoderKeyedContainer<Key>(self)
    }

}
