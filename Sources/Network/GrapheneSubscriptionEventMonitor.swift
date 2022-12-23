//
//  GrapheneSubscriptionEventMonitor.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 21.09.2021.
//  Copyright © 2021 DIGITAL RETAIL TECHNOLOGIES, S.L. All rights reserved.
//

import Alamofire
import Foundation
import os.log

public protocol GrapheneSubscriptionEventMonitor {

    var subscriptionMonitorQueue: DispatchQueue { get }

    func manager(_ manager: SubscriptionManager, willConnectTo url: URL)
    func manager(_ manager: SubscriptionManager, didConnectTo url: URL)

    func managerWillEstablishConnection(_ manager: SubscriptionManager)
    func managerDidEstablishConnection(_ manager: SubscriptionManager)

    func managerKeepAlive(_ manager: SubscriptionManager)

    func manager(_ manager: SubscriptionManager, willRegisterSubscription context: OperationContext)
    func manager(_ manager: SubscriptionManager, didRegisterSubscription context: OperationContext)

    func manager(_ manager: SubscriptionManager, receivedError error: Error, for context: OperationContext?)

    func manager(_ manager: SubscriptionManager, willDeregisterSubscription context: OperationContext)
    func manager(_ manager: SubscriptionManager, didDeregisterSubscription context: OperationContext)

    func manager(_ manager: SubscriptionManager, willDisconnectWithCode code: URLSessionWebSocketTask.CloseCode)
    func manager(_ manager: SubscriptionManager, didDisconnectWithCode code: URLSessionWebSocketTask.CloseCode, error: Error?)

    func manager(_ manager: SubscriptionManager, triesToReconnectWith attempt: Int)

}

public extension GrapheneSubscriptionEventMonitor {

    var subscriptionMonitorQueue: DispatchQueue { .main }

    func manager(_ manager: SubscriptionManager, willConnectTo url: URL) {
        os_log("[GrapheneSubscriptionEventMonitor] Manager will connect to %@", url.absoluteString)
    }

    func manager(_ manager: SubscriptionManager, didConnectTo url: URL) {
        os_log("[GrapheneSubscriptionEventMonitor] Manager successfully connect to %@", url.absoluteString)
    }

    func managerWillEstablishConnection(_ manager: SubscriptionManager) {
        os_log("[GrapheneSubscriptionEventMonitor] Manager will establish connection")
    }

    func managerDidEstablishConnection(_ manager: SubscriptionManager) {
        os_log("[GrapheneSubscriptionEventMonitor] Manager successfully establish connection")
    }

    func manager(_ manager: SubscriptionManager, receivedError error: Error, for context: OperationContext?) {
        os_log("[GrapheneSubscriptionEventMonitor] Manager received error: %@", error.localizedDescription)
    }

    func managerKeepAlive(_ manager: SubscriptionManager) {
        os_log("[GrapheneSubscriptionEventMonitor] Manager keep alive")
    }

    func manager(_ manager: SubscriptionManager, willRegisterSubscription context: OperationContext) {
        os_log("[GrapheneSubscriptionEventMonitor] Manager will register subscription \"%@\"", context.operationName)
    }

    func manager(_ manager: SubscriptionManager, didRegisterSubscription context: OperationContext) {
        os_log("[GrapheneSubscriptionEventMonitor] Manager successfully register subscription \"%@\"", context.operationName)
    }

    func manager(_ manager: SubscriptionManager, willDeregisterSubscription context: OperationContext) {
        os_log("[GrapheneSubscriptionEventMonitor] Manager will deregister subscription \"%@\"", context.operationName)
    }

    func manager(_ manager: SubscriptionManager, didDeregisterSubscription context: OperationContext) {
        os_log("[GrapheneSubscriptionEventMonitor] Manager successfully deregister subscription \"%@\"", context.operationName)
    }

    func manager(_ manager: SubscriptionManager, willDisconnectWithCode code: URLSessionWebSocketTask.CloseCode) {
        os_log("[GrapheneSubscriptionEventMonitor] Manager will disconnect with code %d (.%@)", code.rawValue, code.stringValue)
    }

    func manager(_ manager: SubscriptionManager, didDisconnectWithCode code: URLSessionWebSocketTask.CloseCode, error: Error?) {
        os_log(
            "[GrapheneSubscriptionEventMonitor] Manager did disconnect with code %d (.%@), error \"%@\"",
            code.rawValue,
            code.stringValue,
            error?.localizedDescription ?? "none"
        )
    }

    func manager(_ manager: SubscriptionManager, triesToReconnectWith attempt: Int) {
        os_log("[GrapheneSubscriptionEventMonitor] Manager tries to reconnect: %d attempt", attempt)
    }

}

public class GrapheneSubscriptionClosureEventMonitor: GrapheneSubscriptionEventMonitor {

    open var managerWillConnect: ((SubscriptionManager, URL) -> Void)?
    open var managerDidConnect: ((SubscriptionManager, URL) -> Void)?

    open var managerWillEstablishConnection: ((SubscriptionManager) -> Void)?
    open var managerDidEstablishConnection: ((SubscriptionManager) -> Void)?

    open var managerReceivedError: ((SubscriptionManager, Error, OperationContext?) -> Void)?
    open var managerKeepAlive: ((SubscriptionManager) -> Void)?

    open var managerWillRegisterSubscription: ((SubscriptionManager, OperationContext) -> Void)?
    open var managerDidRegisterSubscription: ((SubscriptionManager, OperationContext) -> Void)?

    open var managerWillDeregisterSubscription: ((SubscriptionManager, OperationContext) -> Void)?
    open var managerDidDeregisterSubscription: ((SubscriptionManager, OperationContext) -> Void)?

    open var managerReceivedData: ((SubscriptionManager, Data, OperationContext) -> Void)?

    open var managerWillDisconnect: ((SubscriptionManager, URLSessionWebSocketTask.CloseCode) -> Void)?
    open var managerDidDisconnect: ((SubscriptionManager, URLSessionWebSocketTask.CloseCode, Error?) -> Void)?

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

    public func manager(_ manager: SubscriptionManager, receivedError error: Error, for context: OperationContext?) {
        self.managerReceivedError?(manager, error, context)
    }

    public func managerKeepAlive(_ manager: SubscriptionManager) {
        self.managerKeepAlive?(manager)
    }

    public func manager(_ manager: SubscriptionManager, didDisconnectWithCode code: URLSessionWebSocketTask.CloseCode, error: Error?) {
        self.managerDidDisconnect?(manager, code, error)
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

    public func manager(_ manager: SubscriptionManager, willDisconnectWithCode code: URLSessionWebSocketTask.CloseCode) {
        self.managerWillDisconnect?(manager, code)
    }

    public func manager(_ manager: SubscriptionManager, triesToReconnectWith attempt: Int) {
        self.managerTriesToReconnect?(manager, attempt)
    }

}

internal final class CompositeGrapheneSubscriptionMonitor: GrapheneSubscriptionEventMonitor {

    let subscriptionMonitorQueue = DispatchQueue(label: "com.simla.Graphene.CompositeGrapheneSubscriptionMonitor", qos: .utility)

    let monitors: [GrapheneSubscriptionEventMonitor]

    init(monitors: [GrapheneSubscriptionEventMonitor]) {
        self.monitors = monitors
    }

    func performEvent(_ event: @escaping (GrapheneSubscriptionEventMonitor) -> Void) {
        self.subscriptionMonitorQueue.async {
            for monitor in self.monitors {
                event(monitor)
            }
        }
    }

    func manager(_ manager: SubscriptionManager, willConnectTo url: URL) {
        self.performEvent { $0.manager(manager, willConnectTo: url) }
    }

    func manager(_ manager: SubscriptionManager, didConnectTo url: URL) {
        self.performEvent { $0.manager(manager, didConnectTo: url) }
    }

    func managerWillEstablishConnection(_ manager: SubscriptionManager) {
        self.performEvent { $0.managerWillEstablishConnection(manager) }
    }

    func managerDidEstablishConnection(_ manager: SubscriptionManager) {
        self.performEvent { $0.managerDidEstablishConnection(manager) }
    }

    func manager(_ manager: SubscriptionManager, receivedError error: Error, for context: OperationContext?) {
        self.performEvent { $0.manager(manager, receivedError: error, for: context) }
    }

    func managerKeepAlive(_ manager: SubscriptionManager) {
        self.performEvent { $0.managerKeepAlive(manager) }
    }

    func manager(_ manager: SubscriptionManager, willRegisterSubscription context: OperationContext) {
        self.performEvent { $0.manager(manager, willRegisterSubscription: context) }
    }

    func manager(_ manager: SubscriptionManager, didRegisterSubscription context: OperationContext) {
        self.performEvent { $0.manager(manager, didRegisterSubscription: context) }
    }

    func manager(_ manager: SubscriptionManager, willDeregisterSubscription context: OperationContext) {
        self.performEvent { $0.manager(manager, willDeregisterSubscription: context) }
    }

    func manager(_ manager: SubscriptionManager, didDeregisterSubscription context: OperationContext) {
        self.performEvent { $0.manager(manager, didDeregisterSubscription: context) }
    }

    func manager(_ manager: SubscriptionManager, willDisconnectWithCode code: URLSessionWebSocketTask.CloseCode) {
        self.performEvent { $0.manager(manager, willDisconnectWithCode: code) }
    }

    func manager(_ manager: SubscriptionManager, didDisconnectWithCode code: URLSessionWebSocketTask.CloseCode, error: Error?) {
        self.performEvent { $0.manager(manager, didDisconnectWithCode: code, error: error) }
    }

    func manager(_ manager: SubscriptionManager, triesToReconnectWith attempt: Int) {
        self.performEvent { $0.manager(manager, triesToReconnectWith: attempt) }
    }

}
