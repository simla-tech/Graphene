//
//  OperationRequest.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 03.08.2021.
//  Copyright © 2021 RetailDriver LLC. All rights reserved.
//

import Foundation
import Alamofire

public class OperationRequest {
    public let context: OperationContext
    private let dataRequest: Request

    internal init(context: OperationContext, dataRequest: Request) {
        self.context = context
        self.dataRequest = dataRequest
    }

    public func cancel() {
        self.dataRequest.cancel()
    }
}
