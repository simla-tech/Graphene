//
//  StringParameterEncoding.swift
//  GrapheneInspector
//
//  Created by Ilya Kharlamov on 7/18/22.
//

import Alamofire
import Foundation

struct StringParameterEncoding: ParameterEncoding {
    let body: String

    func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
        var request = try urlRequest.asURLRequest()
        request.httpBody = self.body.data(using: .utf8, allowLossyConversion: false)
        return request
    }
}
