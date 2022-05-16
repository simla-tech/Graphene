//
//  Logger.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 28.01.2021.
//

import Foundation
import Alamofire
import os.log

public protocol GrapheneEventMonitor: EventMonitor {
    func client(_ client: Client, willSend request: GrapheneRequest)
    func client(_ client: Client, didRecieve response: GrapheneResponse)
}

public class GrapheneClosureEventMonitor: ClosureEventMonitor, GrapheneEventMonitor {

    open var clientWillSendRequest: ((Client, GrapheneRequest) -> Void)?
    open var clientDidRecieveResponse: ((Client, GrapheneResponse) -> Void)?

    public func client(_ client: Client, willSend request: GrapheneRequest) {
        self.clientWillSendRequest?(client, request)
    }

    public func client(_ client: Client, didRecieve response: GrapheneResponse) {
        self.clientDidRecieveResponse?(client, response)
    }

}

final internal class CompositeGrapheneEventMonitor: GrapheneEventMonitor {

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
        performEvent { $0.client(client, willSend: request) }
    }

    public func client(_ client: Client, didRecieve response: GrapheneResponse) {
        performEvent { $0.client(client, didRecieve: response) }
    }

}
