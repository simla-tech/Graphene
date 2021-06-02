//
//  BatchOperation.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 04.02.2021.
//

import Foundation

public struct BatchOperation<O: Graphene.QueryOperation>: Graphene.GraphQLOperation {
    
    private let operations: [String: O]
    
    public init(_ operations: [O]) {
        var dict: [String: O] = [:]
        for operation in operations {
            let key: String = .random(length: 12)
            dict[key] = operation
        }
        self.init(dict)
    }
    
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
            for operation in self.operations {
                builder += .childrenOperation(operation: operation.value, key: operation.key)
            }
        })
    }
    
    public static var operationName: String {
        return "Batch_\(O.operationName)"
    }
    
    public func handleSuccess(with result: MultipleOperationResponse<O.DecodableResponse>) throws -> [String: O.Result] {
        var newResult: [String: O.Result] = [:]
        for (index, item) in result.data {
            guard let operation = self.operations[index] else { continue }
            newResult[index] = try operation.handleSuccess(with: item)
        }
        return newResult
    }

}

extension BatchOperation: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: O...) {
        self.init(elements)
    }
}

extension BatchOperation: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, O)...) {
        var dict: [String: O] = [:]
        for element in elements {
            dict[element.0] = element.1
        }
        self.init(dict)
    }
}
