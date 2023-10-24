//
//  Session.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 28.01.2021.
//

import Alamofire
import Foundation

public class Client: NSObject {

    public let session: Session
    public let configuration: Configuration
    public var url: URLConvertible
    public var batchUrl: URLConvertible?
    public let subscriptionManager: SubscriptionManager?

    /// Create Graphene client
    public init(
        url: URLConvertible,
        batchUrl: URLConvertible? = nil,
        subscriptionManager: SubscriptionManager? = nil,
        configuration: Configuration = .default
    ) {
        self.url = url
        self.batchUrl = batchUrl
        self.configuration = configuration
        let session = Alamofire.Session(
            configuration: configuration.session,
            rootQueue: DispatchQueue(label: "com.graphene.client.rootQueue"),
            startRequestsImmediately: false,
            interceptor: configuration.interceptor,
            serverTrustManager: configuration.serverTrustManager,
            redirectHandler: configuration.redirectHandler,
            cachedResponseHandler: configuration.cachedResponseHandler,
            eventMonitors: configuration.eventMonitors
        )
        self.session = session
        self.subscriptionManager = subscriptionManager
        self.subscriptionManager?.session = session
    }

}

public extension Client {
    struct Configuration {
        public typealias ErrorModifier = (Error) -> Error
        public static var `default`: Configuration { Configuration() }
        public var eventMonitors: [GrapheneEventMonitor] = []
        public var serverTrustManager: ServerTrustManager?
        public var cachedResponseHandler: CachedResponseHandler?
        public var redirectHandler: RedirectHandler?
        public var interceptor: RequestInterceptor?
        public var requestModifier: Alamofire.Session.RequestModifier?
        public var errorModifier: ErrorModifier?
        public var validation: DataRequest.Validation?
        public var muteCanceledRequests = true
        public var keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .convertFromSnakeCase
        public var dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .deferredToDate
        public var session: URLSessionConfiguration = {
            let config = URLSessionConfiguration.af.default
            if let version = Bundle(for: Session.self).infoDictionary?["CFBundleShortVersionString"] as? String {
                config.headers.add(.userAgent("Graphene/\(version)"))
            }
            return config
        }()
    }
}

public extension Client {
    struct SubscriptionConfiguration {
        public let url: URL
        public let socketProtocol: String
        public let eventMonitors: [GrapheneSubscriptionEventMonitor]
        public let timeoutInterval: TimeInterval

        public init(
            url: URL,
            socketProtocol: String = "graphql-ws",
            eventMonitors: [GrapheneSubscriptionEventMonitor] = [],
            timeoutInterval: TimeInterval = 5
        ) {
            self.url = url
            self.socketProtocol = socketProtocol
            self.eventMonitors = eventMonitors
            self.timeoutInterval = timeoutInterval
        }
    }
}
