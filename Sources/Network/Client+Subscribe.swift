//
//  Client+Subscribe.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 21.09.2021.
//  Copyright © 2021 DIGITAL RETAIL TECHNOLOGIES, S.L. All rights reserved.
//

import Alamofire
import Foundation

extension Client {

    public func execute<O: GraphQLOperation>(
        _ operation: O,
        queue: DispatchQueue = .main
    ) -> SubscribeRequest<O> where O.RootSchema: SubscriptionSchema {
        self.executeSubscription(operation, queue: queue)
    }

    private func executeSubscription<O: GraphQLOperation>(_ operation: O, queue: DispatchQueue = .main) -> SubscribeRequest<O> {
        if O.RootSchema.mode != .subscription {
            assertionFailure(
                "You can't subsribe to \"\(O.operationName)\" operation. \"\(String(describing: O.RootSchema.self))\" must have .subscription mode"
            )
        }

        guard let subscriptionManager = self.subscriptionManager else {
            fatalError("Provide SubscriptionManager in Client.init method")
        }

        let operationContext = OperationContextData(operation: operation)
        return InternalSubscribeRequest<O>(
            client: self,
            context: operationContext,
            queue: queue,
            registerClosure: subscriptionManager.register(_:),
            deregisterClosure: subscriptionManager.deregister(_:)
        )
    }

}
