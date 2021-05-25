//
//  MutationOperation.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 08.02.2021.
//

import Foundation

/**
 Operation with `.query` mode
 
 Example:
 ```
 struct SomeOperation: MutationOperation {
    ...
    var someQuery = Query<Model>("editObject") { ... }
 }
 ```
 */
public protocol MutationOperation: QueryOperation {}

extension MutationOperation {
    
    /// Equal to `.mutation` value
    public static var mode: OperationMode { .mutation }
    
}
