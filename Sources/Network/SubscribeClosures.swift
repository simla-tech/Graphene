//
//  SubscribeClosures.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 23.09.2021.
//  Copyright © 2021 RetailDriver LLC. All rights reserved.
//

import Foundation

internal struct SubscribeClosureStorage<T> {

    typealias ValueClosure = (T) -> Void
    typealias FailureClosure = (Error) -> Void
    typealias StateClosure = (SubscriptionState) -> Void

    var valueClosure: ValueClosure?
    var failureClosure: FailureClosure?
    var stateClosure: StateClosure?

}

public protocol SubscribeValueableRequest: SubscribeFailureableRequest {
    associatedtype ResultValue
    typealias ValueClosure = (ResultValue) -> Void

    @discardableResult
    func onValue(_ closure: @escaping ValueClosure) -> SubscribeFailureableRequest
}

public protocol SubscribeFailureableRequest: SubscribeStatableRequest {
    typealias FailureClosure = (Error) -> Void

    @discardableResult
    func onFailure(_ closure: @escaping FailureClosure) -> SubscribeStatableRequest
}

public protocol SubscribeStatableRequest: CancellableRequest {
    typealias StateClosure = (SubscriptionState) -> Void

    @discardableResult
    func onStateUpdate(_ closure: @escaping StateClosure) -> CancellableRequest
}
