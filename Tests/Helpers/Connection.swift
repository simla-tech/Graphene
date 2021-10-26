//
//  Connection.swift
//  GrapheneTests
//
//  Created by Ilya Kharlamov on 04.02.2021.
//

import Foundation
@testable import Graphene

public struct Connection<T> {
    public var totalCount: Int?
    public var pageInfo: PageInfo?
    private var edges: [T]

    init() {
        self.edges = []
    }

    private enum CodingKeys: String, CodingKey {
        case edges
        case pageInfo
        case totalCount
    }
}

extension Connection: CustomStringConvertible {
    public var description: String {
        return "\(self.edges)"
    }
}

extension Connection: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: T...) {
        self.edges = elements
    }
}

extension Connection: Collection {

    // The upper and lower bounds of the collection, used in iterations
    public var startIndex: Int { return self.edges.startIndex }
    public var endIndex: Int { return self.edges.endIndex }

    // Required subscript, based on a dictionary index
    public subscript(index: Int) -> T {
        get {
            return self.edges[index]
        }
        set(newValue) {
            return self.edges[index] = newValue
        }
    }

    // Method that returns the next index when iterating
    public func index(after i: Int) -> Int {
        return self.edges.index(after: i)
    }

}

extension Connection: Queryable {

    public class QueryKeys: QueryKey {

        static var totalCount: QueryKeys {
            QueryKeys(CodingKeys.totalCount)
        }

        static var pageInfo: QueryKeys {
            QueryKeys(Query(CodingKeys.pageInfo, fragment: PageInfoFragment.self))
        }

    }

}

extension Connection.QueryKeys where T: Queryable {
    static func edges(_ builder: @escaping QueryBuilder<T>) -> Connection.QueryKeys {
        return .init(Query(Connection.CodingKeys.edges) { (nodeBuilder: QueryContainer<Node<T>>) in
            nodeBuilder += .node(builder)
        })
    }
}

extension Connection: Decodable where T: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.pageInfo = try container.decodeIfPresent(PageInfo.self, forKey: .pageInfo)
        self.totalCount = try container.decodeIfPresent(Int.self, forKey: .totalCount)
        var nodes: [Node<T>] = []
        if var edges = try? container.nestedUnkeyedContainer(forKey: .edges) {
            while !edges.isAtEnd {
                nodes.append(try edges.decode(Node<T>.self))
            }
        }
        self.edges = nodes.map({ $0.node })
    }
}

extension Connection: Encodable where T: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.pageInfo, forKey: .pageInfo)
        try container.encode(self.edges.map({ Node<T>(node: $0) }), forKey: .edges)
        try container.encode(self.totalCount, forKey: .totalCount)
    }
}

/*
public protocol Paginable: Queryable {
    var totalCount: Int? { get set }
}

public protocol MultilevelContext: QueryBuilderContext {
    var childContext: QueryBuilderContext? { get set }
}

extension OmnicaModel {
    
    public struct Paginated<T: Codable & Queryable>: Paginable, Codable, Collection {
        
        public var totalCount: Int?
        public var pageInfo = PageInfo()
        public var data = [T]()
        public var ordersInfo: OrdersInfo?
        
        public struct Params: MultilevelContext {
            var includeTotalCount: Bool = true
            var includePageInfo: Bool = true
            var includeOrdersInfo: Bool = false
            public var childContext: QueryBuilderContext?
            init() {}
        }
        
        enum CodingKeys: String, CodingKey {
            case edges
            case node
            case pageInfo
            case totalCount
        }
        
        public init() {}
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let unkeyedContainer = try decoder.singleValueContainer()

            self.pageInfo = (try? container.decode(forKey: .pageInfo)) ?? PageInfo()
            
            var allData: [T] = []
            if var edges = try? container.nestedUnkeyedContainer(forKey: .edges) {
                while !edges.isAtEnd {
                    let edge = try edges.decode(NodeWrapper<T>.self)
                    allData += [edge.node]
                }
            }
            self.data = allData
            self.totalCount = try? container.decode(forKey: .totalCount)
            self.ordersInfo = try? unkeyedContainer.decode(OrdersInfo.self)
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(self.pageInfo, forKey: .pageInfo)
            try container.encode(self.data.map({ NodeWrapper<T>.init(node: $0) }), forKey: .edges)
            try container.encode(self.totalCount, forKey: .totalCount)
        }
        
        public static func buildQuery(with builder: QueryBuilder, context: QueryBuilderContext?) {
            let query = builder.query(keyedBy: CodingKeys.self)
            if let params = context as? Params {
                
                if params.includeTotalCount {
                    query.addField(.totalCount)
                }
                
                if params.includePageInfo {
                    query.addField(KeyedQuery(.pageInfo, model: PageInfo.self))
                }
                
                if params.includeOrdersInfo {
                    let builder = QueryBuilder()
                    OrdersInfo.buildQuery(with: builder, context: nil)
                    query.addFields(builder.fields)
                }
                
            } else {
                query.addField(.totalCount)
                query.addField(KeyedQuery(.pageInfo, model: PageInfo.self))
            }
            let childContext = (context as? MultilevelContext)?.childContext ?? context
            query.addField(Query("edges", fields: [Query("node", model: T.self, context: childContext)]))
        }
        
        // MARK: - Collection
        
        // The upper and lower bounds of the collection, used in iterations
        public var startIndex: Int { return self.data.startIndex }
        public var endIndex: Int { return self.data.endIndex }
        
        // Required subscript, based on a dictionary index
        public subscript(index: Int) -> T {
            get {
                return self.data[index]
            }
            set(newValue) {
                return self.data[index] = newValue
            }
        }
        
        // Method that returns the next index when iterating
        public func index(after i: Int) -> Int {
            return self.data.index(after: i)
        }
        
    }
    
    fileprivate struct NodeWrapper<T: Codable>: Codable {
        var node: T
    }
    
}

extension OmnicaModel.Paginated where T: Identifiable {
    
    public func firstIndex(of element: T) -> Int? {
        return self.data.firstIndex(where: { $0.id == element.id })
    }

    public func lastIndex(of element: T) -> Int? {
        return self.data.lastIndex(where: { $0.id == element.id })
    }
    
    public func contains(_ element: T) -> Bool {
        return self.data.contains(where: { $0.id == element.id })
    }
    
    public func elementsEqual<OtherSequence>(_ other: OtherSequence) -> Bool where OtherSequence: Sequence, Self.Element == OtherSequence.Element {
        return self.data.elementsEqual(other) { $0.id == $1.id }
    }
    
    public func firstIndex(whereId id: T.ID) -> Int? {
        return self.data.firstIndex(where: { $0.id == id })
    }
    
    public func first(whereId id: T.ID) -> T? {
        return self.data.first(where: { $0.id == id })
    }
    
    public func last(whereId id: T.ID) -> T? {
        return self.data.last(where: { $0.id == id })
    }
    
    public func contains(whereId id: T.ID) -> Bool {
        return self.data.contains(where: { $0.id == id })
    }
    
}

extension APIExecuteRequest.Successable where ResponseType: Paginable {
    
    public func getCount() -> APIExecuteRequest<Int>.Successable {
        var query: Query!
        if let name = self.graphusRequest?.query.name {
            query = Query(name, arguments: self.graphusRequest!.query.arguments, fields: ["totalCount"])
        } else {
            query = .unnamed(fields: ["totalCount"])
        }
        let requestModel = APIExecuteRequest<Int>.Successable.self
        let urlRequest = requestModel.from(.query, query)
        urlRequest.customRootKey = "data.\(self.graphusRequest!.query.name ?? "–").totalCount"
        return urlRequest
    }
    
}

extension OmnicaModel.Paginated: Equatable where T: Equatable {
    public static func == (lhs: OmnicaModel.Paginated<T>, rhs: OmnicaModel.Paginated<T>) -> Bool {
        return lhs.data == rhs.data
    }
}

extension OmnicaModel.Paginated: Hashable where T: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.data)
    }
}
*/
