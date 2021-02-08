//
//  QueryOperation.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 08.02.2021.
//

import Foundation

/**
 Operation with `.query` mode
 
 Example:
 ```
 struct SomeOperation: QueryOperation {
    ...
    var someQuery = Query<Model>("someObject") { ... }
 }
 ```
 */
public protocol QueryOperation: Operation {}

extension QueryOperation {
    /// Equal to `.query` value
    public static var mode: OperationMode { .query }
}
