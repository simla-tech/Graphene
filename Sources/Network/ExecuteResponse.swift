//
//  ExecuteResponse.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 03.08.2021.
//  Copyright © 2021 RetailDriver LLC. All rights reserved.
//

import Foundation

public enum ExecuteResponse<Value> {
   case success(Value)
   case failure(Error)
}

extension ExecuteResponse {

    public var value: Value? {
        switch self {
        case .success(let result):
            return result
        case .failure:
            return nil
        }
    }

    public var error: Error? {
        switch self {
        case .success:
            return nil
        case .failure(let error):
            return error
        }
    }

    public func get() throws -> Value {
        switch self {
        case .success(let result):
            return result
        case .failure(let error):
            throw error
        }
    }

    public func get<T>(_ transform: (Value) throws -> T?) throws -> T {
        let value = try self.get()
        guard let value = try transform(value) else {
            throw GrapheneError.valueIsNull(String(describing: T.self))
        }
        return value
    }

}
