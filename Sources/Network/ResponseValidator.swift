//
//  ResponseValidator.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 28.01.2021.
//

import Alamofire
import Foundation

public enum GrapheneValidator {

    public static func validateGraphQLError(request: URLRequest?, response: HTTPURLResponse, data: Data?) -> DataRequest.ValidationResult {
        guard let data else {
            return .failure(GrapheneError.invalidResponse)
        }

        if !(200 ..< 300).contains(response.statusCode),
           let errors = try? JSONDecoder().decode(GraphQLErrors.self, from: data)
        {
            if errors.count > 1 {
                return .failure(errors)
            } else if let error = errors.first {
                return .failure(error)
            }
        }

        return .success(())

    }

    public static func validateStatus(request: URLRequest?, response: HTTPURLResponse, data: Data?) -> DataRequest.ValidationResult {
        var rawResponse: String?
        if let data {
            rawResponse = String(decoding: data, as: UTF8.self)
        }
        switch response.statusCode {
        case 400: return .failure(GrapheneError.client("Bad Request", response.statusCode, rawResponse))
        case 401: return .failure(GrapheneError.authentication("Unauthorized", response.statusCode, rawResponse))
        case 402: return .failure(GrapheneError.client("Payment Required", response.statusCode, rawResponse))
        case 403: return .failure(GrapheneError.authentication("Forbidden", response.statusCode, rawResponse))
        case 404: return .failure(GrapheneError.client("Not Found", response.statusCode, rawResponse))
        case 405: return .failure(GrapheneError.client("Method Not Allowed", response.statusCode, rawResponse))
        case 406: return .failure(GrapheneError.client("Not Acceptable", response.statusCode, rawResponse))
        case 407: return .failure(GrapheneError.authentication("Proxy Authentication Required", response.statusCode, rawResponse))
        case 408: return .failure(GrapheneError.client("Request Timeout", response.statusCode, rawResponse))
        case 409: return .failure(GrapheneError.client("Conflict", response.statusCode, rawResponse))
        case 410: return .failure(GrapheneError.client("Gone", response.statusCode, rawResponse))
        case 411: return .failure(GrapheneError.client("Length Required", response.statusCode, rawResponse))
        case 412: return .failure(GrapheneError.client("Precondition Failed", response.statusCode, rawResponse))
        case 413: return .failure(GrapheneError.client("Request Entity Too Large", response.statusCode, rawResponse))
        case 414: return .failure(GrapheneError.client("Request-URI Too Long", response.statusCode, rawResponse))
        case 415: return .failure(GrapheneError.client("Unsupported Media Type", response.statusCode, rawResponse))
        case 416: return .failure(GrapheneError.client("Requested Range Not Satisfiable", response.statusCode, rawResponse))
        case 417: return .failure(GrapheneError.client("Expectation Failed", response.statusCode, rawResponse))
        case 500: return .failure(GrapheneError.server("Internal Server Error", response.statusCode, rawResponse))
        case 501: return .failure(GrapheneError.server("Not Implemented", response.statusCode, rawResponse))
        case 502: return .failure(GrapheneError.server("Bad Gateway", response.statusCode, rawResponse))
        case 503: return .failure(GrapheneError.server("Service Unavailable", response.statusCode, rawResponse))
        case 504: return .failure(GrapheneError.server("Gateway Timeout", response.statusCode, rawResponse))
        case 505: return .failure(GrapheneError.server("HTTP Version Not Supported", response.statusCode, rawResponse))
        default: break
        }

        return .success(())
    }

}
