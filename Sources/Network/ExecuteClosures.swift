//
//  ExecuteClosures.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 21.09.2021.
//  Copyright © 2021 DIGITAL RETAIL TECHNOLOGIES, S.L. All rights reserved.
//

import Foundation

internal struct ExecuteClosureStorage<T> {

    typealias SuccessClosure = (T) -> Void
    typealias FailureClosure = (Error) -> Void
    typealias FinishClosure = () -> Void

    var successClosure: SuccessClosure?
    var failureClosure: FailureClosure?
    var finishClosure: FinishClosure?

}

public protocol SuccessableRequest: FailureableRequest {
    associatedtype ResultValue
    typealias SuccessClosure = (ResultValue) -> Void

    @discardableResult
    func onSuccess(_ closure: @escaping SuccessClosure) -> FailureableRequest
}

public protocol FailureableRequest: FinishableRequest {
    typealias FailureClosure = (Error) -> Void

    @discardableResult
    func onFailure(_ closure: @escaping FailureClosure) -> FinishableRequest
}

public protocol FinishableRequest: GrapheneRequest {
    typealias FinishClosure = () -> Void

    @discardableResult
    func onFinish(_ closure: @escaping FinishClosure) -> GrapheneRequest
}

public protocol GrapheneRequest: CancellableRequest {
    var context: OperationContext { get }
    var request: URLRequest? { get }
}

public protocol CancellableRequest {
    func cancel()
}
