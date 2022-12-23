//
//  SubscribeRequest.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 23.09.2021.
//  Copyright © 2021 DIGITAL RETAIL TECHNOLOGIES, S.L. All rights reserved.
//

import Alamofire
import Combine
import CoreMedia
import Foundation

public class SubscribeRequest<O: GraphQLOperation> {

    public let context: OperationContext

    @Published public internal(set) var state: SubscriptionState = .disconnected(.code(.invalid))

    public let onValue = PassthroughSubject<O.Value, Never>()
    public var request: URLRequest? { self.client?.subscriptionManager?.request }
    public var task: URLSessionTask? { self.client?.subscriptionManager?.task }

    internal weak var client: Client?
    internal let uuid = UUID()
    internal var needsToRegister = true
    internal var isRegistered = false
    internal let errorModifier: Client.Configuration.ErrorModifier?

    internal let queue: DispatchQueue
    internal var isSentToRegistration = false
    internal let deregisterClosure: (SubscriptionOperation) -> Void
    internal let registerClosure: (SubscriptionOperation) -> Void
    internal let decoder: JSONDecoder
    internal let monitor: CompositeGrapheneEventMonitor

    init(
        client: Client,
        context: OperationContext,
        queue: DispatchQueue,
        registerClosure: @escaping (SubscriptionOperation) -> Void,
        deregisterClosure: @escaping (SubscriptionOperation) -> Void
    ) {
        self.client = client
        self.context = context
        self.queue = queue
        self.registerClosure = registerClosure
        self.deregisterClosure = deregisterClosure
        self.errorModifier = client.configuration.errorModifier
        self.monitor = CompositeGrapheneEventMonitor(monitors: client.configuration.eventMonitors)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = client.configuration.keyDecodingStrategy
        decoder.dateDecodingStrategy = client.configuration.dateDecodingStrategy
        decoder.userInfo[.operationName] = context.operationName
        self.decoder = decoder
    }

    public func resume() {
        guard !self.isSentToRegistration else { return }
        self.isSentToRegistration = true
        self.registerClosure(self as! SubscriptionOperation)
    }

}

extension SubscribeRequest: GrapheneRequest {
    public func cancel() {
        self.deregisterClosure(self as! SubscriptionOperation)
    }
}

internal class InternalSubscribeRequest<O: GraphQLOperation>: SubscribeRequest<O> { }

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
            responseResult = .success(
                try self.decoder
                    .decode(O.ResponseValue.self, from: rawValue, keyPath: keyPath, keyPathSeparator: ".")
            )
        } catch {
            responseResult = .failure(error)
        }
        switch O.mapResponse(responseResult) {
        case .success(let value):
            if let client = self.client {
                let response = GrapheneResponse(
                    context: self.context,
                    request: self.request,
                    response: nil,
                    error: nil,
                    data: rawValue,
                    metrics: client.subscriptionManager?.webSocketRequest?.metrics
                )
                self.monitor.client(client, didReceive: response)
            }
            self.onValue.send(value)
        case .failure(let error):
            let modifiedError = self.errorModifier?(error) ?? error
            if let client = self.client {
                let response = GrapheneResponse(
                    context: self.context,
                    request: self.request,
                    response: nil,
                    error: modifiedError,
                    data: rawValue,
                    metrics: client.subscriptionManager?.webSocketRequest?.metrics
                )
                self.monitor.client(client, didReceive: response)
            }
        }
    }

}
