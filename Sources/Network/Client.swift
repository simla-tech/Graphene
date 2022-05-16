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

    public var session: URLSession { self.alamofireSession.session }
    public let configuration: Configuration
    public var url: URLConvertible
    public var batchUrl: URLConvertible?
    public let subscriptionManager: SubscriptionManager?

    /// Create graphus client
    public init(url: URLConvertible,
                batchUrl: URLConvertible? = nil,
                subscriptionManager: SubscriptionManager? = nil,
                configuration: Configuration = .default) {
        self.url = url
        self.batchUrl = batchUrl
        self.configuration = configuration
        let session = Alamofire.Session(rootQueue: DispatchQueue(label: "com.graphene.client.rootQueue"),
                                        startRequestsImmediately: false,
                                        interceptor: configuration.interceptor,
                                        serverTrustManager: configuration.serverTrustManager,
                                        redirectHandler: configuration.redirectHandler,
                                        cachedResponseHandler: configuration.cachedResponseHandler,
                                        eventMonitors: configuration.eventMonitors)
        self.alamofireSession = session
        self.subscriptionManager = subscriptionManager
        self.subscriptionManager?.session = session
        self.subscriptionManager?.headers = self.configuration.prepareHttpHeaders()
    }

}

extension Client {
    public struct Configuration {
        public typealias ErrorModifier = (Error) -> Error
        public static var `default`: Configuration { Configuration() }
        public var eventMonitors: [GrapheneEventMonitor] = []
        public var serverTrustManager: ServerTrustManager?
        public var cachedResponseHandler: CachedResponseHandler?
        public var redirectHandler: RedirectHandler?
        public var interceptor: RequestInterceptor?
        public var requestModifier: Alamofire.Session.RequestModifier?
        public var errorModifier: ErrorModifier?
        public var httpHeaders: HTTPHeaders?
        public var validation: DataRequest.Validation?
        public var muteCanceledRequests: Bool = true
        public var keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .convertFromSnakeCase
        public var dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .deferredToDate
        public var useOperationNameAsReferer: Bool = true
    }
}

extension Client.Configuration {
    internal func prepareHttpHeaders() -> HTTPHeaders {
        var httpHeaders = self.httpHeaders ?? []
        if !httpHeaders.contains(where: { $0.name.lowercased() == "user-agent" }),
           let version = Bundle(for: Session.self).infoDictionary?["CFBundleShortVersionString"] as? String {
            httpHeaders.add(.userAgent("Graphene/\(version)"))
        }
        return httpHeaders
    }
}

extension Client {
    public struct SubscriptionConfiguration {
        public let url: URL
        public let socketProtocol: String?
        public let eventMonitors: [GrapheneSubscriptionEventMonitor]
        public let timeoutInterval: TimeInterval

        public init(url: URL,
                    socketProtocol: String? = nil,
                    eventMonitors: [GrapheneSubscriptionEventMonitor] = [],
                    timeoutInterval: TimeInterval = 5) {
            self.url = url
            self.socketProtocol = socketProtocol
            self.eventMonitors = eventMonitors
            self.timeoutInterval = timeoutInterval
        }
    }
}
