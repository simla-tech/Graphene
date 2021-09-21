//
//  Session.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 28.01.2021.
//

import Foundation
import Alamofire

public class Client: NSObject {

    internal let alamofireSession: Alamofire.Session

    public let configuration: Configuration
    public let url: URLConvertible
    public let batchUrl: URLConvertible?
    public let subscriptionConnection: SubscriptionConnection?

    /// Create graphus client
    public init(url: URLConvertible,
                batchUrl: URLConvertible? = nil,
                subscriptionConfiguration: SubscriptionConfiguration? = nil,
                configuration: Configuration = .default) {
        self.url = url
        self.batchUrl = batchUrl
        self.configuration = configuration
        let session = Alamofire.Session(rootQueue: DispatchQueue(label: "com.graphene.client.rootQueue"),
                                        interceptor: configuration.interceptor,
                                        serverTrustManager: configuration.serverTrustManager,
                                        redirectHandler: configuration.redirectHandler,
                                        cachedResponseHandler: configuration.cachedResponseHandler,
                                        eventMonitors: configuration.eventMonitors)
        self.alamofireSession = session
        if let subscriptionConfiguration = subscriptionConfiguration {
            self.subscriptionConnection = SubscriptionConnection(configuration: subscriptionConfiguration, alamofireSession: session)
        } else {
            self.subscriptionConnection = nil
        }
    }

}

extension Client {
    public struct Configuration {
        public static var `default`: Configuration { Configuration() }
        public var eventMonitors: [GrapheneEventMonitor] = []
        public var serverTrustManager: ServerTrustManager?
        public var cachedResponseHandler: CachedResponseHandler?
        public var redirectHandler: RedirectHandler?
        public var interceptor: RequestInterceptor?
        public var requestModifier: Alamofire.Session.RequestModifier?
        public var requestTimeout: TimeInterval = 60
        public var httpHeaders: HTTPHeaders?
        public var validation: DataRequest.Validation?
        public var muteCanceledRequests: Bool = true
        public var keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .convertFromSnakeCase
        public var dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .deferredToDate
        public var useOperationNameAsReferer: Bool = true
    }
}

extension Client {
    public struct SubscriptionConfiguration {
        public let url: URLConvertible
        public let `protocol`: String?
        public var eventMonitors: [GrapheneSubscriptionEventMonitor] = []
    }
}

public class SubscriptionConnection: NSObject {
    
    let websockerRequest: WebSocketRequest
    let monitor: CompositeGrapheneSubscriptionMonitor

    init(configuration: Client.SubscriptionConfiguration, alamofireSession: Alamofire.Session) {
        do {
            let request = URLRequest(url: try configuration.url.asURL())
            self.websockerRequest = alamofireSession.websocketRequest(request, protocol: configuration.protocol)
            self.monitor = CompositeGrapheneSubscriptionMonitor(monitors: configuration.eventMonitors)
        } catch {
            fatalError(error.localizedDescription)
        }
        super.init()
        self.websockerRequest.responseMessage(handler: self.eventHandler(_:))
        //let asdsd = URLRequest(url: try! self.subscriptionUrl.asURL())
        //return self.alamofireSession.websocketRequest(asdsd, protocol: "graphql-ws")
    }
    
    private func eventHandler(_ event: WebSocketRequest.Event<URLSessionWebSocketTask.Message, Never>) {
        //switch event.kind {
        //case .connected:
            
        //}
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
    .onConnect({
 
    }) // DisconnactableSubscribeRequest
    .onDisconnect({ (reason: DisconnectReason) in
 
    }) // CancallableSubscribeRequest

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
