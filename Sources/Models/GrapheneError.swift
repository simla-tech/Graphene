//
//  GrapheneError.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 28.01.2021.
//

import Foundation

public enum GrapheneError: Error {
    
    case emptyResponse
    case unknownKey(String)
    case unknownSchemaType(String)
    case server(_ message: String, _ code: Int, _ rawResponse: String?)
    case authentication(_ message: String, _ code: Int, _ rawResponse: String?)
    case client(_ message: String, _ code: Int, _ rawResponse: String?)
    
    public var rawResponse: String? {
        switch self {
        case .authentication(_, _, let rawResponse):
            return rawResponse
        case .client(_, _, let rawResponse):
            return rawResponse
        case .server(_, _, let rawResponse):
            return rawResponse
        default:
            return nil
        }
    }
    
    public var statusCode: Int? {
        switch self {
        case .authentication(_, let code, _):
            return code
        case .client(_, let code, _):
            return code
        case .server(_, let code, _):
            return code
        default:
            return nil
        }
    }
    
}

extension GrapheneError: LocalizedError {
    
    public var localizedDescription: String {
        switch self {
        case .authentication(let message, _, _):
            return message
        case .emptyResponse:
            return "Response data is null"
        case .server(let message, _, _):
            return message
        case .client(let message, _, _):
            return message
        case .unknownKey(let key):
            return "Unknown key \"\(key)\""
        case .unknownSchemaType(let schemaType):
            return "Unknown GraphQL schema type \"\(schemaType)\""
        }
    }
    
    public var errorDescription: String? {
        return self.localizedDescription
    }
    
}

extension GrapheneError: CustomNSError {
    
    public static var errorDomain: String = "Graphene.GrapheneError"
    
    public var errorCode: Int {
        return self.statusCode ?? 0
    }
    
    public var errorUserInfo: [String: Any] {
        if let rawResponse = self.rawResponse {
            return ["raw_response": rawResponse]
        }
        return [:]
    }
    
}
