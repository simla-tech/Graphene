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
    func client(willExecute request: GrapheneRequest)
    func client(didExecute request: GrapheneRequest, response: HTTPURLResponse?, error: Error?, data: Data?, metrics: URLSessionTaskMetrics?)
}

public class GrapheneClosureEventMonitor: ClosureEventMonitor, GrapheneEventMonitor {
    
    open var clientWillExecute: ((GrapheneRequest) -> Void)?
    open var clientDidExecute: ((GrapheneRequest, HTTPURLResponse?, Error?, Data?, URLSessionTaskMetrics?) -> Void)?
    
    public func client(willExecute request: GrapheneRequest) {
        self.clientWillExecute?(request)
    }
    
    public func client(didExecute request: GrapheneRequest, response: HTTPURLResponse?, error: Error?, data: Data?, metrics: URLSessionTaskMetrics?) {
        self.clientDidExecute?(request, response, error, data, metrics)
    }
    
}

final internal class CompositeGrapheneEventMonitor: GrapheneEventMonitor {

    public let queue = DispatchQueue(label: "com.retaildriver.Graphene.CompositeGrapheneEventMonitor", qos: .utility)

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
    
    public func client(willExecute request: GrapheneRequest) {
        performEvent { $0.client(willExecute: request) }
    }
    
    public func client(didExecute request: GrapheneRequest, response: HTTPURLResponse?, error: Error?, data: Data?, metrics: URLSessionTaskMetrics?) {
        performEvent { $0.client(didExecute: request, response: response, error: error, data: data, metrics: metrics) }
    }

}
