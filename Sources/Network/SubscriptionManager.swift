//
//  SubscriptionManager.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 22.09.2021.
//  Copyright © 2021 DIGITAL RETAIL TECHNOLOGIES, S.L. All rights reserved.
//

import Alamofire
import Combine
import Foundation

public enum SubscriptionState: Hashable {
    case disconnected(SocketDisconnectReason)
    case connecting
    case connected

    public var isDisconnected: Bool {
        if case .disconnected = self {
            return true
        } else {
            return false
        }
    }

}

public typealias ConnectionState = SubscriptionState

internal protocol SubscriptionOperation: AnyObject {

    var uuid: UUID { get }
    var context: OperationContext { get }
    var needsToRegister: Bool { get }
    var isRegistered: Bool { get }

    func updateState(_ state: SubscriptionState, needsToRegister: Bool, isRegistered: Bool)
    func handleRawValue(_ rawValue: Data)
    func handleDeregisterComplete()

}

public class SubscriptionManager: NSObject {

    let url: URL
    let socketProtocol: String?
    let timeoutInterval: TimeInterval
    let monitor: CompositeGrapheneSubscriptionMonitor
    let encoder: JSONEncoder
    let systemDecoder: JSONDecoder
    var alamofireSession: Alamofire.Session!
    var headers: HTTPHeaders!
    var webSocketRequest: WebSocketRequest?

    @Published public private(set) var state: ConnectionState = .disconnected(.code(.invalid))
    private var subscribeOperations: [SubscriptionOperation] = []
    private var currentReconnectAttempt = 0
    private var reconnectDispatchWorkItem: DispatchWorkItem?
    private var pingDispatchWorkItem: DispatchWorkItem?
    private let pingQueue = DispatchQueue(label: "com.graphene.pingQueue", qos: .background)
    private let eventQueue = DispatchQueue(label: "com.graphene.eventQueue", qos: .background)
    public var request: URLRequest? { self.webSocketRequest?.request }
    public var task: URLSessionTask? { self.webSocketRequest?.task }
    public var session: URLSession { self.alamofireSession.session }

    public init(configuration: Client.SubscriptionConfiguration) {
        self.url = configuration.url
        self.socketProtocol = configuration.socketProtocol
        self.timeoutInterval = configuration.timeoutInterval
        self.monitor = CompositeGrapheneSubscriptionMonitor(monitors: configuration.eventMonitors)
        self.encoder = JSONEncoder()
        self.systemDecoder = JSONDecoder()
        super.init()
    }

    @objc
    private func ping() {
        guard self.state == .connected,
              let task = self.webSocketRequest?.lastTask as? URLSessionWebSocketTask else { return }

        let semaphore = DispatchSemaphore(value: 0)
        task.sendPing { error in
            semaphore.signal()
            if let error {
                self.monitor.manager(self, receivedError: error, for: nil)
                self.disconnect(with: .tlsHandshakeFailure)
            }
            self.pingDispatchWorkItem = DispatchWorkItem(block: self.ping)
            self.pingQueue.asyncAfter(deadline: .now() + 5, execute: self.pingDispatchWorkItem!)
        }
        if semaphore.wait(timeout: .now() + 3) == .timedOut {
            self.disconnect(with: .goingAway)
        }
    }

    public func resume() {
        if self.alamofireSession == nil {
            fatalError("You have to init Client(subscriptionManager:) firstly")
        }
        self.connect(isReconnect: false)
    }

    public func suspend() {
        self.disconnect(with: .normalClosure)
    }

    private func reconnect() {
        self.currentReconnectAttempt += 1
        var reconnectDispatchTime: TimeInterval = 0.5
        if self.currentReconnectAttempt > 2 {
            reconnectDispatchTime = 4
        }
        self.reconnectDispatchWorkItem = DispatchWorkItem {
            self.monitor.manager(self, triesToReconnectWith: self.currentReconnectAttempt)
            self.connect(isReconnect: true)
        }
        DispatchQueue.global(qos: .utility).asyncAfter(
            deadline: .now() + reconnectDispatchTime,
            execute: self.reconnectDispatchWorkItem!
        )
    }

    private func connect(isReconnect: Bool) {
        guard self.state.isDisconnected else { return }
        self.reconnectDispatchWorkItem?.cancel()
        if !isReconnect {
            for operation in self.subscribeOperations {
                operation.updateState(.connecting, needsToRegister: true, isRegistered: false)
            }
        }
        self.state = .connecting
        self.monitor.manager(self, willConnectTo: self.url)
        if self.webSocketRequest == nil || self.webSocketRequest?.state == .finished || self.webSocketRequest?.state == .cancelled {
            var request = URLRequest(url: self.url)
            request.headers = self.headers
            self.webSocketRequest = self.alamofireSession
                .websocketRequest(to: request, protocol: self.socketProtocol)
                .responseMessage(on: self.eventQueue, handler: self.eventHandler(_:))
        }
        self.webSocketRequest?.resume()
    }

    private func disconnect(with code: URLSessionWebSocketTask.CloseCode) {
        guard !self.state.isDisconnected else { return }
        self.monitor.manager(self, willDisconnectWithCode: code)
        self.webSocketRequest?.cancel(with: code, reason: nil)
    }

    internal func register(_ subscriptionOperation: SubscriptionOperation) {
        guard !self.subscribeOperations.contains(where: { $0.uuid == subscriptionOperation.uuid }) else {
            return
        }
        self.subscribeOperations.append(subscriptionOperation)
        if self.state == .connected {
            self.registerDisconnectedOperations()
        } else {
            subscriptionOperation.updateState(self.state, needsToRegister: true, isRegistered: false)
        }
    }

    internal func deregister(_ subscriptionOperation: SubscriptionOperation) {
        guard self.subscribeOperations.contains(where: { $0.uuid == subscriptionOperation.uuid }) else {
            return
        }
        self.monitor.manager(self, willDeregisterSubscription: subscriptionOperation.context)
        self.subscribeOperations.removeAll(where: { $0.uuid == subscriptionOperation.uuid })
        if subscriptionOperation.isRegistered {
            do {
                let message = ClientSystemMessage(type: .stop, id: subscriptionOperation.uuid)
                let messageData = try self.encoder.encode(message)
                let webSocketMessage = URLSessionWebSocketTask.Message.data(messageData)
                self.webSocketRequest?.send(webSocketMessage, completionHandler: { _ in
                    self.monitor.manager(self, didDeregisterSubscription: subscriptionOperation.context)
                    subscriptionOperation.handleDeregisterComplete()
                })
            } catch {
                fatalError(String(describing: error))
            }

        } else {
            self.monitor.manager(self, didDeregisterSubscription: subscriptionOperation.context)
            subscriptionOperation.handleDeregisterComplete()
        }
    }

    private func registerDisconnectedOperations() {
        for subscriptionOperation in self.subscribeOperations where subscriptionOperation.needsToRegister {
            self.monitor.manager(self, willRegisterSubscription: subscriptionOperation.context)
            subscriptionOperation.updateState(.connecting, needsToRegister: false, isRegistered: false)

            let payload = ClientSubscriptionMessage.OperationPayload(
                query: subscriptionOperation.context.query,
                operationName: subscriptionOperation.context.operationName
            )
            let message = ClientSubscriptionMessage(
                type: .start,
                id: subscriptionOperation.uuid,
                payload: payload
            )
            do {
                let messageData = try self.encoder.encode(message)
                let webSocketMessage = URLSessionWebSocketTask.Message.data(messageData)
                self.webSocketRequest?.send(webSocketMessage, completionHandler: { result in
                    switch result {
                    case .success:
                        self.monitor.manager(self, didRegisterSubscription: subscriptionOperation.context)
                        subscriptionOperation.updateState(.connected, needsToRegister: false, isRegistered: true)

                    case .failure(let error):
                        self.monitor.manager(self, receivedError: error, for: subscriptionOperation.context)
                        subscriptionOperation.updateState(
                            .disconnected(.error(error, willReconnect: false)),
                            needsToRegister: false,
                            isRegistered: false
                        )

                    }
                })
            } catch {
                self.monitor.manager(self, receivedError: error, for: subscriptionOperation.context)
                subscriptionOperation.updateState(
                    .disconnected(.error(error, willReconnect: false)),
                    needsToRegister: false,
                    isRegistered: false
                )
            }
        }
    }

    private func handleMessageData(_ data: Data) {
        do {
            let serverMessage = try self.systemDecoder.decode(ServerMessage.self, from: data)
            switch serverMessage.type {
            case .connectionAck:
                self.state = .connected
                self.monitor.managerDidEstablishConnection(self)
                self.registerDisconnectedOperations()
                self.pingDispatchWorkItem = DispatchWorkItem(block: self.ping)
                self.pingQueue.asyncAfter(deadline: .now() + 5, execute: self.pingDispatchWorkItem!)

            case .keepAlive:
                self.monitor.managerKeepAlive(self)

            case .data:
                if let serverId = serverMessage.id, let operation = self.subscribeOperations.first(where: { $0.uuid == serverId }) {
                    operation.handleRawValue(data)
                } else {
                    assertionFailure(
                        "Can't find operation for data message \"\(String(data: data, encoding: .utf8) ?? String(describing: data))\""
                    )
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
                    self.monitor.manager(self, receivedError: error, for: operation?.context)
                    operation?.updateState(.disconnected(.error(error, willReconnect: false)), needsToRegister: false, isRegistered: false)
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
                    self.monitor.manager(self, receivedError: error, for: operation?.context)
                    operation?.updateState(.disconnected(.error(error, willReconnect: false)), needsToRegister: false, isRegistered: false)
                }

            }
        } catch {
            var context: OperationContext?
            if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let idRaw = json["id"] as? String, let serverId = UUID(uuidString: idRaw)
            {
                context = self.subscribeOperations.first(where: { $0.uuid == serverId })?.context
            }
            self.monitor.manager(self, receivedError: error, for: context)
        }
    }

    private func eventHandler(_ event: WebSocketRequest.Event<URLSessionWebSocketTask.Message, Never>) {
        switch event.kind {
        case .connected:
            self.currentReconnectAttempt = 0
            self.monitor.manager(self, didConnectTo: self.url)
            for operation in self.subscribeOperations {
                operation.updateState(.connecting, needsToRegister: true, isRegistered: false)
            }

            do {
                self.monitor.managerWillEstablishConnection(self)
                let message = ClientSystemMessage(type: .connectionInit, id: nil)
                let messageData = try self.encoder.encode(message)
                let webSocketMessage = URLSessionWebSocketTask.Message.data(messageData)
                self.webSocketRequest?.send(webSocketMessage, completionHandler: { result in
                    if case .failure(let error) = result {
                        self.monitor.manager(self, receivedError: error, for: nil)
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

        case .disconnected:
            break

        case .completed:
            self.pingDispatchWorkItem?.cancel()
            let closeCode = (self.webSocketRequest?.lastTask as? URLSessionWebSocketTask)?.closeCode ?? .invalid
            let error = self.webSocketRequest?.error?.underlyingError ?? self.webSocketRequest?.error
            var reason: SocketDisconnectReason = .code(closeCode)

            var willReconnect: Bool
            if let error = self.webSocketRequest?.error {
                willReconnect = error.isSessionTaskError
            } else {
                willReconnect = closeCode != .normalClosure && closeCode != .invalid
            }
            if let error {
                reason = .error(error, willReconnect: willReconnect)
            }
            self.state = .disconnected(reason)
            self.monitor.manager(self, didDisconnectWithCode: closeCode, error: error)

            for operation in self.subscribeOperations {
                operation.updateState(.disconnected(reason), needsToRegister: true, isRegistered: false)
            }
            if willReconnect {
                self.reconnect()
            }
        }

    }

}

public enum SocketDisconnectReason: Hashable {

    case error(Error, willReconnect: Bool)
    case code(URLSessionWebSocketTask.CloseCode)

    public func hash(into hasher: inout Hasher) {
        switch self {
        case .code(let code):
            hasher.combine(code)
        case .error(let error, _):
            hasher.combine((error as NSError).code)
        }
    }

    public static func == (lhs: SocketDisconnectReason, rhs: SocketDisconnectReason) -> Bool {
        lhs.hashValue == rhs.hashValue
    }

}

extension SubscriptionManager {

    enum ClientMessageType: String, Encodable {
        case connectionInit = "connection_init"
        case connectionTerminate = "connection_terminate"
        case start
        case stop
    }

    enum ServerMessageType: String, Decodable {
        case connectionError = "connection_error"
        case connectionAck = "connection_ack"
        case keepAlive = "ka"
        case data
        case error
        case complete
    }

    public enum DisconnectReasonData: RawRepresentable {

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
