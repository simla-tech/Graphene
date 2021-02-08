//
//  Operation.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 22.01.2021.
//

import Foundation

/// Basic operation protocol
public protocol Operation {
    
    /// Type associated with some Queryable model
    associatedtype QueryModel: Queryable
    
    /**
     Operation Mode
     
     Set `.query` or `.mutation` depending on the your choise
     */
    static var mode: OperationMode { get }
    
    /**
     Unique identifier of operation
     
     Using for logging to identify multiple requests responses
     */
    var operationIdentifier: String { get }
    
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
    
    /**
     Query for this operation
     
     Example:
     ```
     var query = Query<SomeModel>("detail", args: ["id": 2]) { builder in
        builder += .id
        builder += .number
        builder += .unionCustomer { builder in
            builder += .id
            builder += .createdAt
        }
     }
     ```
     */
    var query: Query<QueryModel> { get }
    
}

extension Operation {
    
    // Default value
    public var decoderRootKey: String? {
        return self.query.name
    }
    
    // Default value
    public var asField: Field {
        return self.query
    }
    
    // Default value
    public var operationIdentifier: String {
        return self.query.name
    }
    
}
