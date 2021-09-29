//
//  Client+Subscribe.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 21.09.2021.
//  Copyright © 2021 RetailDriver LLC. All rights reserved.
//

import Foundation
import Alamofire

extension Client {
    
    public func execute<O: GraphQLOperation>(_ operation: O,
                                             queue: DispatchQueue = .main) -> SubscribeRequest<O> where O.RootSchema: SubscriptionSchema {
        return self.executeSubscription(operation, queue: queue)
    }
    
    private func executeSubscription<O: GraphQLOperation>(_ operation: O, queue: DispatchQueue = .main) -> SubscribeRequest<O> {
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
