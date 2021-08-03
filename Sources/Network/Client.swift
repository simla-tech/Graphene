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

    /// Create graphus client
    public init(url: URLConvertible, configuration: Configuration = .default) {
        self.url = url
        self.configuration = configuration
        self.alamofireSession = Alamofire.Session(configuration: URLSessionConfiguration.af.default,
                                                  delegate: Alamofire.SessionDelegate(),
                                                  rootQueue: DispatchQueue(label: "com.graphene.client.rootQueue"),
                                                  startRequestsImmediately: false,
                                                  requestQueue: nil,
                                                  serializationQueue: nil,
                                                  interceptor: configuration.interceptor,
                                                  serverTrustManager: configuration.serverTrustManager,
                                                  redirectHandler: configuration.redirectHandler,
                                                  cachedResponseHandler: configuration.cachedResponseHandler,
                                                  eventMonitors: configuration.eventMonitors)
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
    }
}
