//
//  QueryContainer.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 03.02.2021.
//

import Foundation

public class QueryContainer<T: Queryable> {
    
    internal var fields: [Field] = []

    init(_ builder: QueryBuilder<T>) {
        builder(self)
    }
    
    public func append<F: Fragment>(_ fragment: FragmentContainer<F>) where F.FragmentModel == T {
        self.fields.append(fragment.object)
    }

    public static func +=<F: Fragment> (left: QueryContainer<T>, right: FragmentContainer<F>) where F.FragmentModel == T {
        left.append(right)
    }
    
    public func append(_ key: T.QueryKeys) {
        self.fields.append(key.object)
    }
    
    public static func += (left: QueryContainer<T>, right: T.QueryKeys) {
        left.append(right)
    }
    
}

public struct FragmentContainer<Fr: Fragment> {
    
    private init() {}
    
    internal var object: AnyFragment {
        return .init(Fr.self)
    }
        
    public static func fragment(_ type: Fr.Type) -> FragmentContainer<Fr> {
        return .init()
    }
    
}


