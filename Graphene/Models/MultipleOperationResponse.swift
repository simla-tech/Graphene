//
//  MultipleOperationResponse.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 04.02.2021.
//

import Foundation

public struct MultipleOperationResponse<T> {
    public typealias ResponseType = [String : T]
    private var data: ResponseType = [:]
}

extension MultipleOperationResponse: CustomStringConvertible {
    public var description: String {
        return "\(self.data)"
    }
}

extension MultipleOperationResponse: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, T)...) {
        self.init()
        elements.forEach { self.data.updateValue($0.1, forKey: $0.0) }
    }
}

extension MultipleOperationResponse: Collection {
    
    public typealias Indices = ResponseType.Indices
    public typealias Iterator = ResponseType.Iterator
    public typealias SubSequence = ResponseType.SubSequence
    public typealias Index = ResponseType.Index
    
    // The upper and lower bounds of the collection, used in iterations
    public var startIndex: Index { return self.data.startIndex }
    public var endIndex: Index { return self.data.endIndex }
    
    public subscript(position: Index) -> Iterator.Element { return self.data[position] }
    public subscript(bounds: Range<Index>) -> SubSequence { return self.data[bounds] }
    public var indices: Indices { return self.data.indices }
    
    // Required subscript, based on a dictionary index
    public subscript(index: Index) -> T {
        return self.data[index].value
    }
    
    // Method that returns the next index when iterating
    public func index(after i: Index) -> Index {
        return self.data.index(after: i)
    }
    
    public func makeIterator() -> Iterator {
        return self.data.makeIterator()
    }
    
}

extension MultipleOperationResponse: Queryable {
    public class QueryKeys: QueryKey {
        static func childrenOperation<O: Graphene.Operation>(key: String, operation: O) -> QueryKeys {
            var query = operation.query
            query.alias = key
            return QueryKeys(query)
        }
    }
}

extension MultipleOperationResponse: Decodable where T: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.data = try container.decode([String: T].self)
    }
}
