//
//  EditOrderInput.swift
//  GrapheneTests
//
//  Created by Ilya Kharlamov on 01.02.2021.
//

import Foundation
@testable import Graphene

struct EditOrderInput: EncodableVariable, SchemaType {
    
    let order: Order
    let changeSet: ChangeSet<Order>?
    
    func encode(to encoder: VariableEncoder) {
        let container = encoder.container()
        container.encode(self.order.id, forKey: "id")
        container.encode(self.order.updateStateDate, forKey: "updateStateDate")
        self.order.encode(to: encoder, with: self.changeSet)
    }
    
}
