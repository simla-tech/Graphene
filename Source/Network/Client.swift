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
                                                  startRequestsImmediately: true,
                                                  requestQueue: nil,
                                                  serializationQueue: nil,
                                                  interceptor: configuration.interceptor,
                                                  serverTrustManager: configuration.serverTrustManager,
                                                  redirectHandler: configuration.redirectHandler,
                                                  cachedResponseHandler: configuration.cachedResponseHandler,
                                                  eventMonitors: configuration.eventMonitors)
    }

    public func execute<O: Operation>(_ operation: O, queue: DispatchQueue = .main) -> Request<O> {
        return Request<O>(operation: operation, client: self, queue: queue)
    }
    
}

extension Client {
    public struct Configuration {
        public static var `default` = Configuration()
        public var eventMonitors: [EventMonitor] = []
        public var serverTrustManager: ServerTrustManager?
        public var cachedResponseHandler: CachedResponseHandler?
        public var redirectHandler: RedirectHandler?
        public var interceptor: RequestInterceptor?
        public var requestModifier: Alamofire.Session.RequestModifier?
        public var requestTimeout: TimeInterval = 60
        public var httpHeaders: HTTPHeaders?
        public var validation: DataRequest.Validation?
        // swiftlint:disable:next weak_delegate
        public var loggerDelegate: LoggerDelegate? = DefaultLoggerDelegate()
        public var muteCanceledRequests: Bool = true
        public var rootResponseKey: String = "data"
        public var rootErrorsKey: String? = "errors"
        public var decoder: JSONDecoder = JSONDecoder()
    }
}
