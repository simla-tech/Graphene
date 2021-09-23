//
//  Client+Subscribe.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 21.09.2021.
//  Copyright © 2021 RetailDriver LLC. All rights reserved.
//

import Foundation
import Alamofire

public extension Client {
    
    func subscribe<O: GraphQLOperation>(to operation: O, queue: DispatchQueue = .main) -> SubscribeRequest<O> {
        if O.RootSchema.mode != .subscription {
            assertionFailure("You can't subsribe to \"\(O.operationName)\" operation. \"\(String(describing: O.RootSchema.self))\" must have .subscription mode")
        }
        
        guard let subscriptionManager = self.subscriptionManager else {
            fatalError("Provide SubscriptionConfiguration in Client.init method")
        }
        
        let operationContext = OperationContextData(operation: operation)
        return InternalSubscribeRequest(context: operationContext,
                                        queue: queue,
                                        config: self.configuration,
                                        registerClosure: subscriptionManager.register(_:),
                                        deregisterClosure: subscriptionManager.deregister(_:))
    }
    
}
