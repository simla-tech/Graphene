//
//  SubscribeRequest.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 23.09.2021.
//  Copyright © 2021 DIGITAL RETAIL TECHNOLOGIES, S.L. All rights reserved.
//

import Foundation
import Alamofire
import Combine
import CoreMedia

public class SubscribeRequest<O: GraphQLOperation> {

    public let context: OperationContext

    @Published internal(set) public var state: SubscriptionState = .disconnected(.code(.invalid))

    public let onValue = PassthroughSubject<O.Value, Never>()

    internal let uuid = UUID()
    internal var needsToRegister: Bool = true
    internal var isRegistered: Bool = false
    internal let errorModifier: Client.Configuration.ErrorModifier?

    internal let queue: DispatchQueue
    internal var isSendedToRegistration: Bool = false
    internal let deregisterClosure: (SubscriptionOperation) -> Void
    internal let registerClosure: (SubscriptionOperation) -> Void
    internal let decoder: JSONDecoder
    internal let monitor: CompositeGrapheneEventMonitor
    public var request: URLRequest? { nil }

    init(context: OperationContext,
         queue: DispatchQueue,
         config: Client.Configuration,
         registerClosure: @escaping (SubscriptionOperation) -> Void,
         deregisterClosure: @escaping (SubscriptionOperation) -> Void) {
        self.context = context
        self.queue = queue
        self.registerClosure = registerClosure
        self.deregisterClosure = deregisterClosure
        self.errorModifier = config.errorModifier
        self.monitor = CompositeGrapheneEventMonitor(monitors: config.eventMonitors)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = config.keyDecodingStrategy
        decoder.dateDecodingStrategy = config.dateDecodingStrategy
        decoder.userInfo[.operationName] = context.operationName
        self.decoder = decoder
    }

    public func resume() {
        guard !self.isSendedToRegistration else { return }
        self.isSendedToRegistration = true
        self.registerClosure(self as! SubscriptionOperation)
    }

}

extension SubscribeRequest: GrapheneRequest {
    public func cancel() {
        self.deregisterClosure(self as! SubscriptionOperation)
    }
}

internal class InternalSubscribeRequest<O: GraphQLOperation>: SubscribeRequest<O> {}

extension InternalSubscribeRequest: SubscriptionOperation {

    func updateState(_ state: SubscriptionState, needsToRegister: Bool, isRegistered: Bool) {
        self.needsToRegister = needsToRegister
        self.isRegistered = isRegistered
        if state != self.state {
            self.state = state
        }
    }

    func handleDeregisterComplete() {
        self.onValue.send(completion: .finished)
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
            self.onValue.send(value)
        case .failure(let error):
            let modifiedError = self.errorModifier?(error) ?? error
            self.monitor.client(didExecute: self, response: nil, error: modifiedError, data: rawValue, metrics: nil)
        }
    }

}
