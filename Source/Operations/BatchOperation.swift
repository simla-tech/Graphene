//
//  BatchOperation.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 04.02.2021.
//

import Foundation

public struct BatchOperation<O: Graphene.QueryOperation>: Graphene.GraphQLOperation {
  
    private var operations: [O]

    public init(_ operations: [O]) {
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
                builder += .childrenOperation(operation: operation)
            }
        })
    }
    
    public static var operationName: String {
        return "Batch_\(O.operationName)"
    }
    
    public static func handleSuccess(with result: MultipleOperationResponse<O.DecodableResponse>) throws -> [O.Result] {
        return try result.data.values.map({ try O.handleSuccess(with: $0) })
    }
    
}

extension BatchOperation: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: O...) {
        self.init(elements)
    }
}

extension BatchOperation: MutableCollection, RangeReplaceableCollection, RandomAccessCollection {
    
    public typealias Element = O
    public typealias Index = Int
    public typealias SubSequence = ArraySlice<O>
    
    public mutating func replaceSubrange<C, R>(_ subrange: R, with newElements: C) where C: Collection, R: RangeExpression, Self.Element == C.Element, Self.Index == R.Bound {
        self.operations.replaceSubrange(subrange, with: newElements)
    }
    
    public init() {
        self.init([])
    }
    
    // The upper and lower bounds of the collection, used in iterations
    public var startIndex: Index { return self.operations.startIndex }
    public var endIndex: Index { return self.operations.endIndex }
    
    public subscript(bounds: Range<Index>) -> SubSequence {
        get {
            return self.operations[bounds]
        }
        set(newValue) {
            newValue.enumerated().forEach { self.operations[$0] = $1 }
        }
    }

    public subscript(position: Index) -> Element {
        get {
            return self.operations[position]
        }
        set(newValue) {
            return self.operations[position] = newValue
        }
    }
        
    public func index(after i: Index) -> Index {
        return self.operations.index(after: i)
    }
    
    public func index(before i: Index) -> Index {
        return self.operations.index(before: i)
    }
    
}
