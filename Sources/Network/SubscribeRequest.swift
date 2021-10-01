//
//  SubscribeRequest.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 23.09.2021.
//  Copyright © 2021 RetailDriver LLC. All rights reserved.
//

import Foundation
import Alamofire

public class SubscribeRequest<O: GraphQLOperation> {

    public let context: OperationContext
    public var state: SubscriptionState = .disconnected

    internal let uuid = UUID()
    internal var isDisconnected: Bool = true
    internal var closureStorage = SubscribeClosureStorage<O.Value>()

    internal let queue: DispatchQueue
    private var isRegisted: Bool = false
    internal let deregisterClosure: (SubscriptionOperation) -> Void
    internal let registerClosure: (SubscriptionOperation) -> Void
    internal let decoder: JSONDecoder
    internal let monitor: CompositeGrapheneEventMonitor

    init(context: OperationContext,
         queue: DispatchQueue,
         config: Client.Configuration,
         registerClosure: @escaping (SubscriptionOperation) -> Void,
         deregisterClosure: @escaping (SubscriptionOperation) -> Void) {
        self.context = context
        self.queue = queue
        self.registerClosure = registerClosure
        self.deregisterClosure = deregisterClosure
        self.monitor = CompositeGrapheneEventMonitor(monitors: config.eventMonitors)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = config.keyDecodingStrategy
        decoder.dateDecodingStrategy = config.dateDecodingStrategy
        self.decoder = decoder
    }

    private func registerIfNeeded() {
        guard !self.isRegisted else { return }
        self.isRegisted = true
        self.registerClosure(self as! SubscriptionOperation)
    }

}

extension SubscribeRequest: SubscribeValueableRequest {

    public typealias ResultValue = O.Value

    @discardableResult
    public func onValue(_ closure: @escaping ValueClosure) -> SubscribeStatableRequest {
        self.closureStorage.valueClosure = closure
        self.registerIfNeeded()
        return self
    }

}

extension SubscribeRequest: SubscribeStatableRequest {
    @discardableResult
    public func onStateUpdate(_ closure: @escaping StateClosure) -> SubscribeCancellableRequest {
        self.closureStorage.stateClosure = closure
        self.registerIfNeeded()
        return self
    }
}

extension SubscribeRequest: SubscribeCancellableRequest {
    public func cancel() {
        self.deregisterClosure(self as! SubscriptionOperation)
    }
}

internal class InternalSubscribeRequest<O: GraphQLOperation>: SubscribeRequest<O> {}

extension InternalSubscribeRequest: SubscriptionOperation {

    func updateState(_ state: SubscriptionState, silent: Bool) {
        self.isDisconnected = state == .disconnected || state == .suspended || state == .pending
        if state != self.state, !silent {
            self.state = state
            self.queue.async {
                self.closureStorage.stateClosure?(state)
            }
        }
    }

    func handleRawValue(_ rawValue: Data) {
        var responseResult: Result<O.ResponseValue, Error>
        do {
            let keyPath = "payload." + O.decodePath
            responseResult = .success(try self.decoder.decode(O.ResponseValue.self, from: rawValue, keyPath: keyPath, keyPathSeparator: "."))
        } catch {
            responseResult = .failure(error)
        }
        switch O.mapResponse(responseResult) {
        case .success(let value):
            self.queue.async {
                self.closureStorage.valueClosure?(value)
            }
        case .failure(let error):
            self.monitor.operation(with: self.context, didFailWith: error)
        }
    }

}
