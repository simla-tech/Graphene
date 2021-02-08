//
//  Response.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 28.01.2021.
//

import Foundation

public struct GrapheneResponse<T> {
    
    public var data: T?
    public var errors: [GraphQLError] = []
    
    init(data: T?) {
        self.data = data
    }
    
    public var hasErrors: Bool {
        return !self.errors.isEmpty
    }

}
