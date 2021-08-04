//
//  CancellableOperationRequest.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 04.08.2021.
//  Copyright © 2021 RetailDriver LLC. All rights reserved.
//

import Foundation
import Alamofire

public class CancellableOperationRequest {

    internal let alamofireRequest: UploadRequest
    internal let jsonDecoder: JSONDecoder
    internal let muteCanceledRequests: Bool
    internal let monitor: CompositeGrapheneEventMonitor
    public let context: OperationContext

    internal init(alamofireRequest: UploadRequest, decodePath: String?, context: OperationContext, config: Client.Configuration) {
        self.monitor = CompositeGrapheneEventMonitor(monitors: config.eventMonitors)
        self.muteCanceledRequests = config.muteCanceledRequests
        self.alamofireRequest = alamofireRequest
        self.context = context
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = config.keyDecodingStrategy
        decoder.dateDecodingStrategy = config.dateDecodingStrategy
        self.jsonDecoder = decoder
    }

    public func cancel() {
        self.alamofireRequest.cancel()
    }

}
