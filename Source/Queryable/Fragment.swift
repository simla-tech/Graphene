//
//  Fragment.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 04.02.2021.
//

import Foundation

public protocol Fragment: SomeFragment {
    associatedtype FragmentModel: Queryable
    static func fragmentQuery(_ builder: QueryContainer<FragmentModel>)
}

extension Fragment {
    public static var childrenFields: [Field] {
        let container = QueryContainer<FragmentModel>(self.fragmentQuery)
        return container.fields
    }
}

extension Fragment where FragmentModel: SchemaType {
    public static var schemaType: String {
        return FragmentModel.schemaType
    }
}
