//
//  GrapheneError.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 28.01.2021.
//

import Foundation

public enum GrapheneError: Error {
    case invalidResponse
    case unknownSchemaType(String)
    case server(_ message: String, _ code: Int, _ rawResponse: String?)
    case authentication(_ message: String, _ code: Int, _ rawResponse: String?)
    case client(_ message: String, _ code: Int, _ rawResponse: String?)
}

extension GrapheneError: LocalizedError {

    public var localizedDescription: String {
        switch self {
        case .authentication(let message, _, _):
            return message
        case .invalidResponse:
            return "Response data is invalid"
        case .server(let message, _, _):
            return message
        case .client(let message, _, _):
            return message
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
        switch self {
        case .invalidResponse:
            return 1
        case .unknownSchemaType:
            return 2
        case .authentication(_, let code, _):
            return code
        case .client(_, let code, _):
            return code
        case .server(_, let code, _):
            return code
        }
    }

    public var errorUserInfo: [String: Any] {
        switch self {
        case .authentication(_, _, let rawResponse):
            return ["raw_response": rawResponse ?? "null"]
        case .client(_, _, let rawResponse):
            return ["raw_response": rawResponse ?? "null"]
        case .server(_, _, let rawResponse):
            return ["raw_response": rawResponse ?? "null"]
        case .unknownSchemaType(let schemaType):
            return ["schema_type": schemaType]
        default:
            return [:]
        }
    }

}
