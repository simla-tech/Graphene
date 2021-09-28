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

    func manager(_ manager: SubscriptionManager, willConnectTo url: URL)
    func manager(_ manager: SubscriptionManager, didConnectTo url: URL)

    func managerWillEstablishConnection(_ manager: SubscriptionManager)
    func managerDidEstablishConnection(_ manager: SubscriptionManager)

    func managerKeepAlive(_ manager: SubscriptionManager)

    func manager(_ manager: SubscriptionManager, willRegisterSubscription context: OperationContext)
    func manager(_ manager: SubscriptionManager, didRegisterSubscription context: OperationContext)

    func manager(_ manager: SubscriptionManager, recievedData size: Int, for context: OperationContext)
    func manager(_ manager: SubscriptionManager, recievedError error: Error, for context: OperationContext?)

    func manager(_ manager: SubscriptionManager, willDeregisterSubscription context: OperationContext)
    func manager(_ manager: SubscriptionManager, didDeregisterSubscription context: OperationContext)

    func manager(_ manager: SubscriptionManager, triesToReconnectWith attempt: Int)
    
    func managerWillTerminateConnection(_ manager: SubscriptionManager)
    func manager(_ manager: SubscriptionManager, didDisconnectWithCode code: URLSessionWebSocketTask.CloseCode, reason: SubscriptionManager.DisconnectReason?)
    func managerDidCloseConnection(_ manager: SubscriptionManager)

}

extension GrapheneSubscriptionEventMonitor {

    public var queue: DispatchQueue { .main }

    public func manager(_ manager: SubscriptionManager, willConnectTo url: URL) {
        os_log("[GrapheneSubscriptionEventMonitor] Manager will connect to %@", url.absoluteString)
    }

    public func manager(_ manager: SubscriptionManager, didConnectTo url: URL) {
        os_log("[GrapheneSubscriptionEventMonitor] Manager successfully connect to %@", url.absoluteString)
    }

    public func managerWillEstablishConnection(_ manager: SubscriptionManager) {
        os_log("[GrapheneSubscriptionEventMonitor] Manager will establish connection")
    }

    public func managerDidEstablishConnection(_ manager: SubscriptionManager) {
        os_log("[GrapheneSubscriptionEventMonitor] Manager successfully establish connection")
    }

    public func manager(_ manager: SubscriptionManager, recievedError error: Error, for context: OperationContext?) {
        os_log("[GrapheneSubscriptionEventMonitor] Manager recieved error: %@", error.localizedDescription)
    }

    public func managerKeepAlive(_ manager: SubscriptionManager) {
        os_log("[GrapheneSubscriptionEventMonitor] Manager keep alive")
    }

    public func manager(_ manager: SubscriptionManager, didDisconnectWithCode code: URLSessionWebSocketTask.CloseCode, reason: SubscriptionManager.DisconnectReason?) {
        os_log("[GrapheneSubscriptionEventMonitor] Manager did disconnect with code \"%d\", reason \"%@\"", code.rawValue, reason?.rawValue ?? "none")
    }

    public func managerDidCloseConnection(_ manager: SubscriptionManager) {
        os_log("[GrapheneSubscriptionEventMonitor] Manager did close connection")
    }

    public func manager(_ manager: SubscriptionManager, willRegisterSubscription context: OperationContext) {
        os_log("[GrapheneSubscriptionEventMonitor] Manager will register subscription \"%@\"", context.operationName)
    }

    public func manager(_ manager: SubscriptionManager, didRegisterSubscription context: OperationContext) {
        os_log("[GrapheneSubscriptionEventMonitor] Manager successfully register subscription \"%@\"", context.operationName)
    }

    public func manager(_ manager: SubscriptionManager, recievedData size: Int, for context: OperationContext) {
        os_log("[GrapheneSubscriptionEventMonitor] Manager recieved data (%d bytes) for subscription %@", size, context.operationName)
    }

    public func manager(_ manager: SubscriptionManager, willDeregisterSubscription context: OperationContext) {
        os_log("[GrapheneSubscriptionEventMonitor] Manager will deregister subscription \"%@\"", context.operationName)
    }

    public func manager(_ manager: SubscriptionManager, didDeregisterSubscription context: OperationContext) {
        os_log("[GrapheneSubscriptionEventMonitor] Manager successfully deregister subscription \"%@\"", context.operationName)
    }

    public func managerWillTerminateConnection(_ manager: SubscriptionManager) {
        os_log("[GrapheneSubscriptionEventMonitor] Manager will terminate connection")
    }
    
    public func manager(_ manager: SubscriptionManager, triesToReconnectWith attempt: Int) {
        os_log("[GrapheneSubscriptionEventMonitor] Manager tries to reconnect: %d attempt", attempt)
    }

}

public class GrapheneSubscriptionClosureEventMonitor: GrapheneSubscriptionEventMonitor {

    open var managerWillConnect: ((SubscriptionManager, URL) -> Void)?
    open var managerDidConnect: ((SubscriptionManager, URL) -> Void)?

    open var managerWillEstablishConnection: ((SubscriptionManager) -> Void)?
    open var managerDidEstablishConnection: ((SubscriptionManager) -> Void)?

    open var managerRecievedError: ((SubscriptionManager, Error, OperationContext?) -> Void)?
    open var managerKeepAlive: ((SubscriptionManager) -> Void)?

    open var managerDidDisconnect: ((SubscriptionManager, URLSessionWebSocketTask.CloseCode, SubscriptionManager.DisconnectReason?) -> Void)?
    open var managerDidCloseConnection: ((SubscriptionManager) -> Void)?

    open var managerWillRegisterSubscription: ((SubscriptionManager, OperationContext) -> Void)?
    open var managerDidRegisterSubscription: ((SubscriptionManager, OperationContext) -> Void)?

    open var managerWillDeregisterSubscription: ((SubscriptionManager, OperationContext) -> Void)?
    open var managerDidDeregisterSubscription: ((SubscriptionManager, OperationContext) -> Void)?

    open var managerRecievedData: ((SubscriptionManager, Int, OperationContext) -> Void)?
    open var managerWillTerminateConnection: ((SubscriptionManager) -> Void)?

    open var managerTriesToReconnect: ((SubscriptionManager, Int) -> Void)?

    public func manager(_ manager: SubscriptionManager, willConnectTo url: URL) {
        self.managerWillConnect?(manager, url)
    }

    public func manager(_ manager: SubscriptionManager, didConnectTo url: URL) {
        self.managerDidConnect?(manager, url)
    }

    public func managerWillEstablishConnection(_ manager: SubscriptionManager) {
        self.managerWillEstablishConnection?(manager)
    }

    public func managerDidEstablishConnection(_ manager: SubscriptionManager) {
        self.managerDidEstablishConnection?(manager)
    }

    public func manager(_ manager: SubscriptionManager, recievedError error: Error, for context: OperationContext?) {
        self.managerRecievedError?(manager, error, context)
    }

    public func managerKeepAlive(_ manager: SubscriptionManager) {
        self.managerKeepAlive?(manager)
    }

    public func manager(_ manager: SubscriptionManager, didDisconnectWithCode code: URLSessionWebSocketTask.CloseCode, reason: SubscriptionManager.DisconnectReason?) {
        self.managerDidDisconnect?(manager, code, reason)
    }

    public func managerDidCloseConnection(_ manager: SubscriptionManager) {
        self.managerDidCloseConnection?(manager)
    }

    public func manager(_ manager: SubscriptionManager, willRegisterSubscription context: OperationContext) {
        self.managerWillRegisterSubscription?(manager, context)
    }

    public func manager(_ manager: SubscriptionManager, didRegisterSubscription context: OperationContext) {
        self.managerDidRegisterSubscription?(manager, context)
    }

    public func manager(_ manager: SubscriptionManager, willDeregisterSubscription context: OperationContext) {
        self.managerWillDeregisterSubscription?(manager, context)
    }

    public func manager(_ manager: SubscriptionManager, didDeregisterSubscription context: OperationContext) {
        self.managerDidDeregisterSubscription?(manager, context)
    }

    public func manager(_ manager: SubscriptionManager, recievedData size: Int, for context: OperationContext) {
        self.managerRecievedData?(manager, size, context)
    }

    public func managerWillTerminateConnection(_ manager: SubscriptionManager) {
        self.managerWillTerminateConnection?(manager)
    }
    
    public func manager(_ manager: SubscriptionManager, triesToReconnectWith attempt: Int) {
        self.managerTriesToReconnect?(manager, attempt)
    }

}

final internal class CompositeGrapheneSubscriptionMonitor: GrapheneSubscriptionEventMonitor {

    let queue = DispatchQueue(label: "com.retaildriver.Graphene.CompositeGrapheneSubscriptionMonitor", qos: .utility)

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

    func manager(_ manager: SubscriptionManager, willConnectTo url: URL) {
        performEvent { $0.manager(manager, willConnectTo: url) }
    }

    func manager(_ manager: SubscriptionManager, didConnectTo url: URL) {
        performEvent { $0.manager(manager, didConnectTo: url) }
    }

    func managerWillEstablishConnection(_ manager: SubscriptionManager) {
        performEvent { $0.managerWillEstablishConnection(manager) }
    }

    func managerDidEstablishConnection(_ manager: SubscriptionManager) {
        performEvent { $0.managerDidEstablishConnection(manager) }
    }

    func manager(_ manager: SubscriptionManager, recievedError error: Error, for context: OperationContext?) {
        performEvent { $0.manager(manager, recievedError: error, for: context) }
    }

    func managerKeepAlive(_ manager: SubscriptionManager) {
        performEvent { $0.managerKeepAlive(manager) }
    }

    func manager(_ manager: SubscriptionManager, didDisconnectWithCode code: URLSessionWebSocketTask.CloseCode, reason: SubscriptionManager.DisconnectReason?) {
        performEvent { $0.manager(manager, didDisconnectWithCode: code, reason: reason) }
    }

    func managerDidCloseConnection(_ manager: SubscriptionManager) {
        performEvent { $0.managerDidCloseConnection(manager) }
    }

    func manager(_ manager: SubscriptionManager, willRegisterSubscription context: OperationContext) {
        performEvent { $0.manager(manager, willRegisterSubscription: context) }
    }

    func manager(_ manager: SubscriptionManager, didRegisterSubscription context: OperationContext) {
        performEvent { $0.manager(manager, didRegisterSubscription: context) }
    }

    func manager(_ manager: SubscriptionManager, willDeregisterSubscription context: OperationContext) {
        performEvent { $0.manager(manager, willDeregisterSubscription: context) }
    }

    func manager(_ manager: SubscriptionManager, didDeregisterSubscription context: OperationContext) {
        performEvent { $0.manager(manager, didDeregisterSubscription: context) }
    }

    func manager(_ manager: SubscriptionManager, recievedData size: Int, for context: OperationContext) {
        performEvent { $0.manager(manager, recievedData: size, for: context) }
    }

    func managerWillTerminateConnection(_ manager: SubscriptionManager) {
        performEvent { $0.managerWillTerminateConnection(manager) }
    }
    
    func manager(_ manager: SubscriptionManager, triesToReconnectWith attempt: Int) {
        performEvent { $0.manager(manager, triesToReconnectWith: attempt) }
    }

}
