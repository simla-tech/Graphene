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
    typealias ProgressClosure = (Double) -> Void
    typealias FailureClosure = (Error) -> Void
    typealias FinishClosure = () -> Void

    var successClosure: SuccessClosure?
    var progressClosure: ProgressClosure?
    var failureClosure: FailureClosure?
    var finishClosure: FinishClosure?

}

public protocol SuccessableRequest: ProgressableRequest {
    associatedtype ResultValue
    typealias SuccessClosure = (ResultValue) -> Void

    @discardableResult
    func onSuccess(_ closure: @escaping SuccessClosure) -> ProgressableRequest
}

public protocol ProgressableRequest: FailureableRequest {
    typealias ProgressClosure = (Double) -> Void

    @discardableResult
    func onProgress(_ closure: @escaping ProgressClosure) -> FailureableRequest
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

public protocol GrapheneRequest {
    var context: OperationContext { get }
    var request: URLRequest? { get }
    var task: URLSessionTask? { get }
    func cancel()
}

public struct GrapheneResponse {
    public let context: OperationContext
    public let request: URLRequest?
    public let response: HTTPURLResponse?
    public let error: Error?
    public let data: Data?
    public let metrics: URLSessionTaskMetrics?
}
