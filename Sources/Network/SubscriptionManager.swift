//
//  SubscriptionManager.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 22.09.2021.
//  Copyright © 2021 RetailDriver LLC. All rights reserved.
//

import Foundation
import Alamofire

public enum SubscriptionState {
    case connected
    case connecting
    case disconnected
}

internal protocol SubscriptionOperation: AnyObject {

    var uuid: UUID { get }
    var context: OperationContext { get }
    var state: SubscriptionState { get }

    func updateState(_ state: SubscriptionState)
    func handleFailure(_ error: Error)
    func handleRawValue(_ rawValue: Data)

}

public class SubscriptionManager: NSObject {

    let url: URL
    let websockerRequest: WebSocketRequest
    let monitor: CompositeGrapheneSubscriptionMonitor
    let encoder: JSONEncoder
    let systemDecoder: JSONDecoder
    var subscribeOperations: [SubscriptionOperation] = []
    var state: SubscriptionState = .disconnected

    init(configuration: Client.SubscriptionConfiguration, alamofireSession: Alamofire.Session) {
        self.url = configuration.url
        let request = URLRequest(url: configuration.url)
        self.websockerRequest = alamofireSession.websocketRequest(request, protocol: configuration.socketProtocol)
        self.monitor = CompositeGrapheneSubscriptionMonitor(monitors: configuration.eventMonitors)
        self.encoder = JSONEncoder()
        self.systemDecoder = JSONDecoder()
        super.init()
    }

    public func connect() {
        guard self.state == .disconnected else { return }
        self.monitor.manager(self, willConnectTo: self.url)
        self.state = .connecting
        self.websockerRequest.responseMessage(handler: self.eventHandler(_:))
    }

    public func terminate() {
        guard self.state != .disconnected else { return }
        self.monitor.managerWillTerminateConnection(self)
        do {
            let message = ClientSystemMessage(type: .connectionTerminate, id: nil)
            let messageData = try self.encoder.encode(message)
            let webSocketMessage = URLSessionWebSocketTask.Message.data(messageData)
            self.websockerRequest.send(webSocketMessage, completionHandler: { response in
                if case .failure(let error) = response {
                    self.monitor.manager(self, recievedError: error, for: nil)
                }
            })
        } catch {
            fatalError(String(describing: error))
        }
    }

    internal func register(_ subscriptionOperation: SubscriptionOperation) {
        guard !self.subscribeOperations.contains(where: { $0.uuid == subscriptionOperation.uuid }) else {
            return
        }
        self.subscribeOperations.append(subscriptionOperation)
        if self.state == .connected {
            self.registerDisconnectedOperations()
        }
    }

    internal func deregister(_ subscriptionOperation: SubscriptionOperation) {
        guard !self.subscribeOperations.contains(where: { $0.uuid == subscriptionOperation.uuid }) else {
            return
        }
        self.monitor.manager(self, willDeregisterSubscription: subscriptionOperation.context)
        self.subscribeOperations.removeAll(where: { $0.uuid == subscriptionOperation.uuid })
        if subscriptionOperation.state != .disconnected {
            do {
                let message = ClientSystemMessage(type: .stop, id: subscriptionOperation.uuid)
                let messageData = try self.encoder.encode(message)
                let webSocketMessage = URLSessionWebSocketTask.Message.data(messageData)
                self.websockerRequest.send(webSocketMessage, completionHandler: { _ in
                    self.monitor.manager(self, didDeregisterSubscription: subscriptionOperation.context)
                })
            } catch {
                fatalError(String(describing: error))
            }

        } else {
            self.monitor.manager(self, didDeregisterSubscription: subscriptionOperation.context)
        }
    }

    private func registerDisconnectedOperations() {
        for subscriptionOperation in self.subscribeOperations where subscriptionOperation.state == .disconnected {
            self.monitor.manager(self, willRegisterSubscription: subscriptionOperation.context)
            subscriptionOperation.updateState(.connecting)

            let payload = ClientSubscriptionMessage.OperationPayload(query: subscriptionOperation.context.query,
                                                                     operationName: subscriptionOperation.context.operationName)
            let message = ClientSubscriptionMessage(type: .start,
                                                    id: subscriptionOperation.uuid,
                                                    payload: payload)
            do {
                let messageData = try self.encoder.encode(message)
                let webSocketMessage = URLSessionWebSocketTask.Message.data(messageData)
                self.websockerRequest.send(webSocketMessage, completionHandler: { result in
                    switch result {
                    case .success:
                        self.monitor.manager(self, didRegisterSubscription: subscriptionOperation.context)
                        subscriptionOperation.updateState(.connected)

                    case .failure(let error):
                        self.monitor.manager(self, recievedError: error, for: subscriptionOperation.context)
                        subscriptionOperation.handleFailure(error)
                        subscriptionOperation.updateState(.disconnected)

                    }
                })
            } catch {
                self.monitor.manager(self, recievedError: error, for: subscriptionOperation.context)
                subscriptionOperation.handleFailure(error)
                subscriptionOperation.updateState(.disconnected)
            }
        }
    }

    private func handleMessageData(_ data: Data) {
        do {
            let serverMessage = try self.systemDecoder.decode(ServerMessage.self, from: data)
            switch serverMessage.type {
            case .connectionAck:
                self.monitor.managerDidEstablishConnection(self)
                self.state = .connected
                self.registerDisconnectedOperations()

            case .keepAlive:
                self.monitor.managerKeepAlive(self)

            case .data:
                if let serverId = serverMessage.id, let operation = self.subscribeOperations.first(where: { $0.uuid == serverId }) {
                    self.monitor.manager(self, recievedData: data.count, for: operation.context)
                    operation.handleRawValue(data)
                } else {
                    assertionFailure("Can't find operation for data message \"\(String(data: data, encoding: .utf8) ?? String(describing: data))\"")
                }

            case .error:
                do {
                    let errors = try self.systemDecoder.decode([GraphQLError].self, from: data, keyPath: "payload")
                    if errors.count == 1, let first = errors.first {
                        throw first
                    } else {
                        throw GraphQLErrors(errors)
                    }
                } catch {
                    let operation = self.subscribeOperations.first(where: { $0.uuid == serverMessage.id })
                    self.monitor.manager(self, recievedError: error, for: operation?.context)
                    operation?.handleFailure(error)
                }

            case .complete:
                if let operation = self.subscribeOperations.first(where: { $0.uuid == serverMessage.id }) {
                    self.deregister(operation)
                }

            case .connectionError:
                do {
                    let connectionError = try self.systemDecoder.decode(ConnectionError.self, from: data, keyPath: "payload")
                    throw GrapheneError.connection(connectionError.message)
                } catch {
                    let operation = self.subscribeOperations.first(where: { $0.uuid == serverMessage.id })
                    self.monitor.manager(self, recievedError: error, for: operation?.context)
                    operation?.handleFailure(error)
                }

            }
        } catch {
            var context: OperationContext?
            if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let idRaw = json["id"] as? String, let serverId = UUID(uuidString: idRaw) {
                context = self.subscribeOperations.first(where: { $0.uuid == serverId })?.context
            }
            self.monitor.manager(self, recievedError: error, for: context)
        }
    }

    private func eventHandler(_ event: WebSocketRequest.Event<URLSessionWebSocketTask.Message, Never>) {
        switch event.kind {
        case .connected:
            self.monitor.manager(self, didConnectTo: self.url)
            self.monitor.managerWillEstablishConnection(self)
            let message = ClientSystemMessage(type: .connectionInit, id: nil)
            do {
                let messageData = try self.encoder.encode(message)
                let webSocketMessage = URLSessionWebSocketTask.Message.data(messageData)
                self.websockerRequest.send(webSocketMessage, completionHandler: { result in
                    if case .failure(let error) = result {
                        self.monitor.manager(self, recievedError: error, for: nil)
                    }
                })
            } catch {
                fatalError(String(describing: error))
            }

        case .receivedMessage(let message):
            switch message {
            case .data(let data):
                self.handleMessageData(data)

            case .string(let string):
                guard let data = string.data(using: .utf8) else {
                    fatalError("Can't handle income message \"\(string)\"")
                }
                self.handleMessageData(data)

            @unknown default:
                fatalError("Unknown message type \"\(message)\"")
            }

        case .disconnected(let closeCode, let reasonData):
            var reason: DisconnectReason?
            if let data = reasonData, let str = String(data: data, encoding: .utf8) {
                reason = DisconnectReason(rawValue: str)
            }
            self.monitor.manager(self, didDisconnectWithCode: closeCode, reason: reason)
            self.state = .disconnected

        case .completed:
            self.monitor.managerDidCloseConnection(self)

        }

    }

}

extension SubscriptionManager {

    enum ClientMessageType: String, Encodable {
        case connectionInit = "connection_init"
        case connectionTerminate = "connection_terminate"
        case start = "start"
        case stop = "stop"
    }

    enum ServerMessageType: String, Decodable {
        case connectionError = "connection_error"
        case connectionAck = "connection_ack"
        case keepAlive = "ka"
        case data = "data"
        case error = "error"
        case complete = "complete"
    }

    public enum DisconnectReason: RawRepresentable {

        case decodingError
        case terminated
        case unexpectedMessage
        case unexpectedClosure
        case unknown(String)

        public init(rawValue: String) {
            switch rawValue {
            case "decoding error":
                self = .decodingError
            case "terminated":
                self = .terminated
            case "unexpected message":
                self = .unexpectedMessage
            case "unexpected closure":
                self = .unexpectedClosure
            default:
                self = .unknown(rawValue)
            }
        }

        public var rawValue: String {
            switch self {
            case .decodingError:
                return "decoding error"
            case .terminated:
                return "terminated"
            case .unexpectedMessage:
                return "unexpected message"
            case .unexpectedClosure:
                return "unexpected closure"
            case .unknown(let unknownValue):
                return unknownValue
            }
        }

    }

    struct ConnectionError: Decodable {
        let message: String
    }

    struct ClientSystemMessage: Encodable {
        let type: ClientMessageType
        let id: UUID?

        // swiftlint:disable:next nesting
        private enum CodingKeys: String, CodingKey {
            case type
            case id
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(self.type, forKey: .type)
            try container.encodeIfPresent(self.id, forKey: .id)
        }
    }

    struct ClientSubscriptionMessage: Encodable {
        let type: ClientMessageType
        let id: UUID
        let payload: OperationPayload
    }

    struct ServerMessage: Decodable {
        let type: ServerMessageType
        let id: UUID?
    }

}

extension SubscriptionManager.ClientSubscriptionMessage {

    struct OperationPayload: Codable {
        let query: String
        let operationName: String
    }

}

/*
 
 // Subscribe
 
 self.client.execute(ChatsList()) // ExecuteRequest<ChatsList>
    .onSuccess({
 
    }) // FailurableExecuteRequest
    .onFailure({
 
    }) // FinishableExecuteRequest
    .onFinish({
 
    })// CancallableExecuteRequest
 
 let subscribeRequest = self.client.subscribe(to: Chats()) // SubscribeRequest<Chats>
    .onValue({ (chat: Chat) in
 
    }) // FailurableSubscribeRequest
    .onFailure({ (error: Error) in
 
    }) // ConnectableSubscribeRequest
    .onConnectionState({ (connectionState: ConnectionState) in
        switch connectionState {
        case .connected: break
        case .disconnected: break
        case .inProgress: break
        }
    })

 subscribeRequest.cancel()
 subscribeRequest.cancel(with: Reason)
 
 */

// Connection will initiate ( -> connection_init)
// Connection initiate did failure with error
// Connection did initiate ( <- connection_ack )

// Keep alive ( <- ka )

// Subscription XXX will register ( -> start )
// Subscription XXX register did failure with error
// Subscription XXX did register ( <- ??? )

// Subscription XXX will deregister ( -> stop )
// Subscription XXX register did failure with error
// Subscription XXX did deregister ( <- ??? )

// Connection did deinitiate with reason ( <- ??? )
