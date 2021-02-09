//
//  RequestPerformer.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 28.01.2021.
//

import Foundation
import Alamofire

public class CancelableRequest {
    private let requst: Alamofire.DataRequest
    internal init(_ requst: Alamofire.DataRequest) {
        self.requst = requst
    }
    public func cancel() {
        self.requst.cancel()
    }
}
