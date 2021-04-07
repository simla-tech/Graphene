//
//  QueryContainer.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 03.02.2021.
//

import Foundation

public class QueryContainer<T: Queryable> {
    
    internal(set) public var fields: [Field] = []

    public init(_ builder: QueryBuilder<T>) {
        builder(self)
    }
    
    public func append<F: Fragment>(_ fragment: F) where F.FragmentModel == T {
        self.fields.append(AnyFragment(fragment))
    }

    public static func +=<F: Fragment> (left: QueryContainer<T>, right: F) where F.FragmentModel == T {
        left.append(right)
    }
    
    public func append(_ key: T.QueryKeys) {
        self.fields.append(key.object)
    }
    
    public static func += (left: QueryContainer<T>, right: T.QueryKeys) {
        left.append(right)
    }
    
}
