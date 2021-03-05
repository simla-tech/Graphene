//
//  Callbacks.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 03.03.2021.
//

import Foundation

public class SuccessableCallback<T>: FailureableCallback {
    
    /// Success callback
    ///
    /// - Parameter result: response data
    public typealias Closure = (_ result: T) -> Void
    
    /// Successable callback
    public var success: Closure?
    
}

public class FailureableCallback: FinishableCallback {

    /// Error callback
    ///
    /// - Parameter result: response error
    public typealias Closure = (_ error: Error) -> Void
    
    /// Error callback
    public var failure: Closure?
    
}

public class FinishableCallback {
    
    /// Empty callback (without data)
    public typealias Closure = () -> Void
    
    /// Finish callback (without data)
    public var finish: Closure?
    
    public init() {}
    
}
