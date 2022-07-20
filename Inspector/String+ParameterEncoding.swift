//
//  String+ParameterEncoding.swift
//  GrapheneInspector
//
//  Created by Ilya Kharlamov on 7/18/22.
//

import Foundation
import Alamofire

extension String: ParameterEncoding {
    public func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
        var request = try urlRequest.asURLRequest()
        request.httpBody = data(using: .utf8, allowLossyConversion: false)
        return request
    }
}
