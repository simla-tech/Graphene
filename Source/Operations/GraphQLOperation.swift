//
//  GraphQLOperation.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 22.01.2021.
//

import Foundation

/// Basic operation protocol
public protocol GraphQLOperation {
    
    /// Type associated with some Queryable model
    associatedtype DecodableResponse: Decodable
    associatedtype Result
    
    /**
     Operation Mode
     
     Set `.query` or `.mutation` depending on the your choise
     */
    static var mode: OperationMode { get }
    
    /**
     Unique identifier of operation
     
     Using for logging to identify multiple requests responses
     */
    static var operationName: String { get }
    
    /**
     Universal representation of result sendable field
     
     By default equals to the `query` variable
     */
    var asField: Field { get }
    
    /**
     The root key which is used to decode server response
     
     By default equals to the curent query variable name
     */
    var decoderRootKey: String? { get }
    
    static func mapResult(_ result: DecodableResponse) throws -> Result
    
}