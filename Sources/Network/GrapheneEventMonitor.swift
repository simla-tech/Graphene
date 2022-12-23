//
//  Logger.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 28.01.2021.
//

import Alamofire
import Foundation
import os.log

public protocol GrapheneEventMonitor: EventMonitor {
    func client(_ client: Client, willSend request: GrapheneRequest)
    func client(_ client: Client, didReceive response: GrapheneResponse)
}

public class GrapheneClosureEventMonitor: ClosureEventMonitor, GrapheneEventMonitor {

    open var clientWillSendRequest: ((Client, GrapheneRequest) -> Void)?
    open var clientDidReceiveResponse: ((Client, GrapheneResponse) -> Void)?

    public func client(_ client: Client, willSend request: GrapheneRequest) {
        self.clientWillSendRequest?(client, request)
    }

    public func client(_ client: Client, didReceive response: GrapheneResponse) {
        self.clientDidReceiveResponse?(client, response)
    }

}

internal final class CompositeGrapheneEventMonitor: GrapheneEventMonitor {

    public let queue = DispatchQueue(label: "com.simla.Graphene.CompositeGrapheneEventMonitor", qos: .utility)

    let monitors: [GrapheneEventMonitor]

    init(monitors: [GrapheneEventMonitor]) {
        self.monitors = monitors
    }

    func performEvent(_ event: @escaping (GrapheneEventMonitor) -> Void) {
        self.queue.async {
            for monitor in self.monitors {
                monitor.queue.async { event(monitor) }
            }
        }
    }

    public func client(_ client: Client, willSend request: GrapheneRequest) {
        self.performEvent { $0.client(client, willSend: request) }
    }

    public func client(_ client: Client, didReceive response: GrapheneResponse) {
        self.performEvent { $0.client(client, didReceive: response) }
    }

}
