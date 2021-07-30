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
    func operation(_ operationContext: OperationContext, willExecuteWith request: DataRequest)
    func operation(_ operationContext: OperationContext, didExecuteWith statusCode: Int, interval: DateInterval)
    func operation(_ operationContext: OperationContext, didFailWith error: Error)
}

extension GrapheneEventMonitor {

    public func operation(_ operationContext: OperationContext, willExecuteWith request: DataRequest) {
        if let variables = operationContext.jsonVariablesString(prettyPrinted: true) {
            os_log("[GrapheneEventMonitor] Will send request \"%@\":\n%@\nvariables: %@", operationContext.operationName, operationContext.query, variables)
        } else {
            os_log("[GrapheneEventMonitor] Will send request \"%@\":\n%@", operationContext.operationName, operationContext.query)
        }
    }

    public func operation(_ operationContext: OperationContext, didExecuteWith statusCode: Int, interval: DateInterval) {
        os_log("[GrapheneEventMonitor] Response \"%@\" recived. Code: %d. Duration: %.3f", operationContext.operationName, statusCode, interval.duration)
    }

    public func operation(_ operationContext: OperationContext, didFailWith error: Error) {
        os_log("[GrapheneEventMonitor] Catched error for \"%@\" operation: %@", operationContext.operationName, error.localizedDescription)
    }

}

public class GrapheneClosureEventMonitor: ClosureEventMonitor, GrapheneEventMonitor {

    open var operationWillExecute: ((OperationContext) -> Void)?
    open var operationDidExecute: ((OperationContext, Int, DateInterval) -> Void)?
    open var operationDidFail: ((OperationContext, Error) -> Void)?

    public func operation(_ operationContext: OperationContext, willExecuteWith request: DataRequest) {
        self.operationWillExecute?(operationContext)
    }

    public func operation(_ operationContext: OperationContext, didExecuteWith statusCode: Int, interval: DateInterval) {
        self.operationDidExecute?(operationContext, statusCode, interval)
    }

    public func operation(_ operationContext: OperationContext, didFailWith error: Error) {
        self.operationDidFail?(operationContext, error)
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

    public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        performEvent { $0.urlSession(session, didBecomeInvalidWithError: error) }
    }

    public func operation(_ operationContext: OperationContext, willExecuteWith request: DataRequest) {
        performEvent { $0.operation(operationContext, willExecuteWith: request) }
    }

    public func operation(_ operationContext: OperationContext, didExecuteWith statusCode: Int, interval: DateInterval) {
        performEvent { $0.operation(operationContext, didExecuteWith: statusCode, interval: interval) }
    }

    public func operation(_ operationContext: OperationContext, didFailWith error: Error) {
        performEvent { $0.operation(operationContext, didFailWith: error) }
    }

}
