//
//  GrapheneSubscriptionEventMonitor.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 21.09.2021.
//  Copyright © 2021 RetailDriver LLC. All rights reserved.
//

import Foundation

import Alamofire
import os.log

public protocol GrapheneSubscriptionEventMonitor {
    
    var queue: DispatchQueue { get }

    func connectionWillInitiate(_ connection: SubscriptionConnection)
    //func connection(_ connection: SubscriptionConnection, didInitiateWithError error: Error?)

    //func connectionKeepAlive(_ connection: SubscriptionConnection)

    //func connection(_ connection: SubscriptionConnection, willRegisterSubscription context: OperationContext)
    //func connection(_ connection: SubscriptionConnection, didRegisterSubscription context: OperationContext, with error: Error?)

    //func connection(_ connection: SubscriptionConnection, recievedData size: Int, for context: OperationContext)
    //func connection(_ connection: SubscriptionConnection, recievedError Error?, for context: OperationContext)

    //func connection(_ connection: SubscriptionConnection, willDeregisterSubscription context: OperationContext)
    //func connection(_ connection: SubscriptionConnection, didDeregisterSubscription context: OperationContext, with error: Error?)

    //func connection(_ connection: SubscriptionConnection, terminatedWith reason: Int)
}

extension GrapheneSubscriptionEventMonitor {
    
    public var queue: DispatchQueue { .main }

    func connectionWillInitiate(_ connection: SubscriptionConnection) {
        os_log("[GrapheneSubscriptionEventMonitor] Connection will initiate")
    }

}

public class GrapheneSubscriptionClosureEventMonitor: GrapheneSubscriptionEventMonitor {

    open var connectionWillInitiate: ((SubscriptionConnection) -> Void)?

    public func connectionWillInitiate(_ connection: SubscriptionConnection) {
        self.connectionWillInitiate?(connection)
    }

}

final internal class CompositeGrapheneSubscriptionMonitor: GrapheneSubscriptionEventMonitor {

    public let queue = DispatchQueue(label: "com.retaildriver.Graphene.CompositeGrapheneSubscriptionMonitor", qos: .utility)

    let monitors: [GrapheneSubscriptionEventMonitor]

    init(monitors: [GrapheneSubscriptionEventMonitor]) {
        self.monitors = monitors
    }

    func performEvent(_ event: @escaping (GrapheneSubscriptionEventMonitor) -> Void) {
        self.queue.async {
            for monitor in self.monitors {
                monitor.queue.async { event(monitor) }
            }
        }
    }

    public func connectionWillInitiate(_ connection: SubscriptionConnection) {
        performEvent { $0.connectionWillInitiate(connection) }
    }

}
