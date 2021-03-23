//
//  BatchOperation.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 04.02.2021.
//

import Foundation

public struct BatchOperation<O: QueryOperation>: GraphQLOperation {
    
    private var operations: [O]
    
    
}

/*
public struct BatchOperation<O: Graphene.QueryOperation>: Graphene.GraphQLOperation {
  
    private var operations: [String: O]

    public init(_ operations: [String: O]) {
        self.operations = operations
        self.decoderRootKey = nil
    }
    
    /// Mode is equal to child operations
    public static var mode: OperationMode {
        return O.mode
    }
        
    /// Equal to null
    public let decoderRootKey: String?
    
    public var asField: Field {
        return MultipleQuery<MultipleOperationResponse<O.DecodableResponse>>({ builder in
            for (operationKey, operation) in self.operations {
                builder += .childrenOperation(key: operationKey, operation: operation)
            }
        })
    }
    
    public static var operationName: String {
        return "Batch_\(O.operationName)"
    }
    
    public static func mapResult(_ result: MultipleOperationResponse<O.DecodableResponse>) throws -> [O.Result] {
        return try result.values.map({ try O.mapResult($0) })
    }
    
}

extension BatchOperation: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, O)...) {
        self.init([:])
        elements.forEach { self.operations.updateValue($0.1, forKey: $0.0) }
    }
}
*/
