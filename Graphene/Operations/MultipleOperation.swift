//
//  MultipleOperation.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 04.02.2021.
//

import Foundation

/**
 Multiple operation. Use this object to create operation with child operations
 
 Example GraphQL request:
 ```
 {
   aOperation: someOperation(id: 1) {
     number
   }
   bOperation: someOperation(id: 2) {
     number
   }
 }
 ```
 
 You need to have dictionary of type `[String:Operation]` to initialize MultipleOperation:
 ```
 let aOperation = SomeOperation()
 let bOperation = SomeOperation()
 let multipleOperation = MultipleOperation(["a": aOperation, "b": bOperation])
 ```
 
 **Notice**: You have to have the same operations to execute them
 */
public struct MultipleOperation<O: Graphene.Operation>: Graphene.Operation {
    
    public typealias QueryModel = MultipleOperationResponse<O.QueryModel>
    
    private var operations: [String: O]

    public init(_ operations: [String: O]) {
        self.operations = operations
    }
    
    
    /// Mode is equal to child operations
    public static var mode: OperationMode {
        return O.mode
    }
    
    /// Equal to automatically generated UUID string
    public let operationIdentifier: String = UUID().uuidString
        
    /// Equal to null
    public let decoderRootKey: String? = nil
    
    private func buildQuery(_ builder: QueryContainer<QueryModel>) {
        for (operationKey, operation) in self.operations {
            builder += .childrenOperation(key: operationKey, operation: operation)
        }
    }
    
    public var query: Query<QueryModel> {
        return Query(self.operationIdentifier, self.buildQuery)
    }
    
    public var asField: Field {
        return MultipleQuery<QueryModel>(self.operationIdentifier, self.buildQuery)
    }
    
}

extension MultipleOperation: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, O)...) {
        self.init([:])
        elements.forEach { self.operations.updateValue($0.1, forKey: $0.0) }
    }
}
