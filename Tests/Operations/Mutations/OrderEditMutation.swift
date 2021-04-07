//
//  OrderEditMutation.swift
//  GrapheneTests
//
//  Created by Ilya Kharlamov on 03.02.2021.
//

import Foundation
@testable import Graphene

final class OrderEditMutation: MutationOperation {
     
    let editOrderInput: EditOrderInput
    
    init(order: Order, changeSet: ChangeSet<Order>?) {
        self.editOrderInput = EditOrderInput(order: order, changeSet: changeSet)
    }

    lazy var query = Query<EditOrderPayload>("editOrder", args: ["input": InputVariable(self.editOrderInput)]) { builder in
        builder += .order({ builder in
            builder += OrderDetailFragment()
        })
    }
        
}
