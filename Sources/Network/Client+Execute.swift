//
//  Client+Execute.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 03.08.2021.
//  Copyright © 2021 RetailDriver LLC. All rights reserved.
//

import Foundation

extension Client {

    @discardableResult
    public func execute<O: GraphQLOperation>(_ operations: [O],
                                             queue: DispatchQueue = .main,
                                             completion: @escaping (Result<[O.Value], Error>) -> Void) -> CancellableOperationRequest {
        return self.request(for: operations).perform(queue: queue, completion: completion)
    }

    @discardableResult
    public func execute<O: GraphQLOperation>(_ operation: O,
                                             queue: DispatchQueue = .main,
                                             completion: @escaping (Result<O.Value, Error>) -> Void) -> CancellableOperationRequest {
        return self.request(for: operation).perform(queue: queue, completion: completion)
    }

}
