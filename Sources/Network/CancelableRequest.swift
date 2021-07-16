//
//  CancelableRequest.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 03.03.2021.
//

import Foundation
import Alamofire

open class CancelableRequest {

    internal var dataRequest: Alamofire.DataRequest

    internal init(request: Alamofire.DataRequest) {
        self.dataRequest = request
    }

    public func cancel() {
        self.dataRequest.cancel()
    }

}
