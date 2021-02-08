//
//  Client.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 28.01.2021.
//

import Foundation
import Alamofire

public class Client: SessionDelegate {
    
    internal let session: Session
    internal let loggerQueue = DispatchQueue(label: "Graphene.LoggerQueue", qos: .utility)
    
    public let configuration: Configuration
    public let url: URLConvertible
    public var logger: LoggerProtocol = Logger()
    
    /// Create graphus client
    public init(url: URLConvertible, configuration: Configuration = .default){
        self.url = url
        self.configuration = configuration
        self.session = Session(configuration: URLSessionConfiguration.af.default,
                               delegate: SessionDelegate(),
                               rootQueue: DispatchQueue(label: "com.graphene.session.rootQueue"),
                               startRequestsImmediately: true,
                               requestQueue: DispatchQueue(label: "com.graphene.session.requestQueue"),
                               serializationQueue: DispatchQueue(label: "com.graphene.session.serializationQueue"),
                               interceptor: configuration.interceptor,
                               serverTrustManager: configuration.serverTrustManager,
                               redirectHandler: configuration.redirectHandler,
                               cachedResponseHandler: configuration.cachedResponseHandler,
                               eventMonitors: configuration.eventMonitors)
    }
    
    @discardableResult
    func executeAny<O: Operation>(_ operation: O,
                                  queue: DispatchQueue = .main,
                                  _ completionHandler: @escaping (Result<GrapheneResponse<Any>, Error>) -> Void) -> CancelableRequest {
        let request = Request(operation: operation, client: self)
        request.executeAny(queue: queue, completionHandler: completionHandler)
        return .init(request.dataRequest)
    }
    
    @discardableResult
    func execute<O: Operation>(_ operation: O,
                               queue: DispatchQueue = .main,
                               _ completionHandler: @escaping (Result<GrapheneResponse<O.QueryModel>, Error>) -> Void) -> CancelableRequest where O.QueryModel: Decodable {
        let request = Request(operation: operation, client: self)
        request.execute(queue: queue, completionHandler: completionHandler)
        return .init(request.dataRequest)
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
        public var requestModifier: Session.RequestModifier?
        public var requestTimeout: TimeInterval = 60
        public var muteCanceledRequests: Bool = false
        public var httpHeaders: HTTPHeaders?
        public var validation: DataRequest.Validation?
        public var rootResponseKey: String = "data"
        public var rootErrorsKey: String? = "errors"
        public var decoder: JSONDecoder = JSONDecoder()
    }
}
