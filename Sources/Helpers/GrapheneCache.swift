//
//  GrapheneCache.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 11/13/23.
//  Copyright © 2023 DIGITAL RETAIL TECHNOLOGIES, S.L. All rights reserved.
//

import Alamofire
import Foundation

public class GrapheneCache: URLCache, @unchecked Sendable {

    private func cachableRequest(for request: URLRequest) -> URLRequest? {
        guard let operationName = request.headers[HTTPHeader.operationNameKey] else {
            return nil
        }

        guard let url = request.url, var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }

        urlComponents.queryItems = {
            var queryItems: [URLQueryItem] = [.operationName(operationName)]
            if let variablesHash = request.headers[HTTPHeader.variablesHashKey] {
                queryItems.append(.variablesHash(variablesHash))
            }
            return queryItems
        }()

        guard let newUrl = urlComponents.url else {
            return nil
        }

        return try? URLRequest(url: newUrl, method: .get)
    }

    override public func storeCachedResponse(_ cachedResponse: CachedURLResponse, for request: URLRequest) {
        guard let cachableRequest = self.cachableRequest(for: request) else {
            super.storeCachedResponse(cachedResponse, for: request)
            return
        }
        super.storeCachedResponse(cachedResponse, for: cachableRequest)
    }

    override public func cachedResponse(for request: URLRequest) -> CachedURLResponse? {
        guard let cachableRequest = self.cachableRequest(for: request) else {
            return super.cachedResponse(for: request)
        }
        return super.cachedResponse(for: cachableRequest)
    }

}
