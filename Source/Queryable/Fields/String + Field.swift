//
//  String + Field.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 05.02.2021.
//

import Foundation

extension String: Field {
    public var fieldString: String {
        return self
    }
    public var childrenFields: [Field] {
        return []
    }
    public var arguments: Arguments {
        return [:]
    }
}
