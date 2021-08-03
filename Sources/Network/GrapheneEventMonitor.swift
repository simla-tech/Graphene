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
    func client(_ client: Client, willExecute request: OperationRequest)
    func operation(_ context: OperationContext, didFinishWith statusCode: Int, interval: DateInterval)
    func operation(_ context: OperationContext, didFailWith error: Error)
}

extension GrapheneEventMonitor {

    public func client(_ client: Client, willExecute request: OperationRequest) {
        if let variables = request.context.jsonVariablesString(prettyPrinted: true) {
            os_log("[GrapheneEventMonitor] Will send request \"%@\":\n%@\nvariables: %@", request.context.operationName, request.context.query, variables)
        } else {
            os_log("[GrapheneEventMonitor] Will send request \"%@\":\n%@", request.context.operationName, request.context.query)
        }
    }

    public func operation(_ context: OperationContext, didFinishWith statusCode: Int, interval: DateInterval) {
        os_log("[GrapheneEventMonitor] Response \"%@\" recived. Code: %d. Duration: %.3f", context.operationName, statusCode, interval.duration)
    }

    public func operation(_ context: OperationContext, didFailWith error: Error) {
        os_log("[GrapheneEventMonitor] Catched error for \"%@\" operation: %@", context.operationName, error.localizedDescription)
    }

}

public class GrapheneClosureEventMonitor: ClosureEventMonitor, GrapheneEventMonitor {

    open var clientWillExecute: ((Client, OperationRequest) -> Void)?
    open var operationDidFinish: ((OperationContext, Int, DateInterval) -> Void)?
    open var operationDidFail: ((OperationContext, Error) -> Void)?

    public func client(_ client: Client, willExecute request: OperationRequest) {
        self.clientWillExecute?(client, request)
    }

    public func operation(_ context: OperationContext, didFinishWith statusCode: Int, interval: DateInterval) {
        self.operationDidFinish?(context, statusCode, interval)
    }

    public func operation(_ context: OperationContext, didFailWith error: Error) {
        self.operationDidFail?(context, error)
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

    public func client(_ client: Client, willExecute request: OperationRequest) {
        performEvent { $0.client(client, willExecute: request) }
    }

    public func operation(_ context: OperationContext, didFinishWith statusCode: Int, interval: DateInterval) {
        performEvent { $0.operation(context, didFinishWith: statusCode, interval: interval) }
    }

    public func operation(_ context: OperationContext, didFailWith error: Error) {
        performEvent { $0.operation(context, didFailWith: error) }
    }

}
