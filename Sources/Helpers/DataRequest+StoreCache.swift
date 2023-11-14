//
//  AlamofireURLCache.swift
//  AlamofireURLCache
//
//  Created by Kenshin Cui on 2017/5/23.
//  Copyright © 2017年 CMJStudio. All rights reserved.
//
//  Source: https://github.com/kenshincui/AlamofireURLCache
//

import Alamofire
import CoreFoundation
import CryptoKit
import Foundation

extension DataRequest {

    private static var HTTPVersion = "HTTP/1.1"

    private enum RefreshCacheValue: String {
        case refreshCache
        case useCache
    }

    private static let refreshCacheKey = "Refresh-Cache-Policy"

    @discardableResult
    internal func storeCacheIgnoringServer(context: OperationContext, maxAge: Int, in cache: URLCache)
        -> Self
    {

        guard maxAge > 0 else { return self }

        if let newRequest = self.request,
           let allHTTPHeaderFields = newRequest.allHTTPHeaderFields,
           allHTTPHeaderFields[Self.refreshCacheKey] != RefreshCacheValue.refreshCache.rawValue,
           let cachedResponse = cache.cachedResponse(for: newRequest)?.response as? HTTPURLResponse,
           let value = cachedResponse.allHeaderFields[Self.refreshCacheKey] as? String,
           value == RefreshCacheValue.useCache.rawValue
        {
            return self
        }

        // add to response queue wait for invoke
        return response { defaultResponse in

            if let error = defaultResponse.error {
                debugPrint(error.localizedDescription)
                return
            }

            guard let httpResponse = defaultResponse.response else {
                return
            }

            guard let newData = defaultResponse.data else { return }
            guard let newRequest = defaultResponse.request else { return }
            guard let newURL = httpResponse.url else { return }
            guard let newHeaders = (httpResponse.allHeaderFields as NSDictionary).mutableCopy() as? NSMutableDictionary else { return }

            newHeaders.removeObject(forKey: "Vary")
            newHeaders.removeObject(forKey: "Pragma")

            if let date = newHeaders["Date"] as? String, let expires = Self.expiresHeaderValue(date: date, maxAge: maxAge) {
                newHeaders.setValue(expires, forKey: "Expires")
            } else {
                newHeaders.removeObject(forKey: "Expires")
            }
            newHeaders.setValue("max-age=\(maxAge)", forKey: "Cache-Control")

            guard let newResponse = HTTPURLResponse(
                url: newURL,
                statusCode: httpResponse.statusCode,
                httpVersion: Self.HTTPVersion,
                headerFields: newHeaders as? [String: String]
            ) else {
                return
            }

            let newCacheResponse = CachedURLResponse(
                response: newResponse,
                data: newData,
                userInfo: ["framework": "Graphene"],
                storagePolicy: .allowed
            )

            cache.storeCachedResponse(newCacheResponse, for: newRequest)

        }

    }

    // MARK: - Private method

    private static func expiresHeaderValue(date dateString: String, maxAge: Int) -> String? {
        let formate = DateFormatter()
        formate.dateFormat = "E, dd MMM yyyy HH:mm:ss zzz"
        formate.timeZone = TimeZone(identifier: "UTC")
        guard let date = formate.date(from: dateString) else { return nil }
        let expireDate = Date(timeInterval: TimeInterval(maxAge), since: date)
        return formate.string(from: expireDate)
    }

}
