//
//  QueryOperation.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 08.02.2021.
//

import Foundation

public protocol QueryOperation: GraphQLOperation {
    
    associatedtype QueryModel: Queryable
    
    var query: Query<QueryModel> { get }
        
}

extension QueryOperation {
    
    /// Equal to `.query` value
    public static var mode: OperationMode { .query }
    
    // Default value
    public var decoderRootKey: String? {
        return self.query.name
    }
    
    // Default value
    public var asField: Field {
        return self.query
    }
    
    // Default value
    public static var operationName: String {
        return String(describing: self)
    }
    
}

extension QueryOperation where QueryModel: Decodable {
    public static func mapResult(_ result: QueryModel) throws -> QueryModel {
        return result
    }
}
