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
    public let subscriptionManager: SubscriptionManager?

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
            self.subscriptionManager = SubscriptionManager(configuration: subscriptionConfiguration, alamofireSession: session)
        } else {
            self.subscriptionManager = nil
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
        public let url: URL
        public let socketProtocol: String?
        public let eventMonitors: [GrapheneSubscriptionEventMonitor]
        
        public init(url: URL, socketProtocol: String? = nil, eventMonitors: [GrapheneSubscriptionEventMonitor] = []) {
            self.url = url
            self.socketProtocol = socketProtocol
            self.eventMonitors = eventMonitors
        }
    }
}
