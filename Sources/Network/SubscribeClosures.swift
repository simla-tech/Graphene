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
    typealias StateClosure = (SubscriptionState) -> Void

    var valueClosure: ValueClosure?
    var stateClosure: StateClosure?

}

public protocol SubscribeValueableRequest: SubscribeStatableRequest {
    associatedtype ResultValue
    typealias ValueClosure = (ResultValue) -> Void

    @discardableResult
    func onValue(_ closure: @escaping ValueClosure) -> SubscribeStatableRequest
}

public protocol SubscribeStatableRequest: SubscribeCancellableRequest {
    typealias StateClosure = (SubscriptionState) -> Void

    @discardableResult
    func onStateUpdate(_ closure: @escaping StateClosure) -> SubscribeCancellableRequest
}

public protocol SubscribeCancellableRequest {
    var state: SubscriptionState { get }
    func cancel()
}
