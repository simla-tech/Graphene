//
//  VariableEncoder.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 28.01.2021.
//

import Foundation

public class VariableEncoder {
    
    public var variables = Variables()
    public var dateFormatter = DateFormatter()
    private(set) internal var changeSet: ChangeSet?

    internal init() {}
    
    public func apply(changeSet: ChangeSet?) {
        self.changeSet = changeSet
    }
    
    public func container() -> VariableEncoderContainer {
        return VariableEncoderContainer(self)
    }
    
    public func container<Key>(keyedBy type: Key.Type) -> VariableEncoderKeyedContainer<Key> where Key: CodingKey {
        return VariableEncoderKeyedContainer<Key>(self)
    }
    
}
