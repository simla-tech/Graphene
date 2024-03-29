//
//  MuteCancelTests.swift
//  GrapheneTests
//
//  Created by Ilya Kharlamov on 03.08.2021.
//  Copyright © 2021 DIGITAL RETAIL TECHNOLOGIES, S.L. All rights reserved.
//

import Alamofire
import XCTest
@testable import Graphene

class MuteCancelTests: XCTestCase {

    private lazy var client: Client = {
        var config: Client.Configuration = .default
        config.muteCanceledRequests = true
        return Client(url: "https://google.com/app/api", configuration: config)
    }()

    func testMuteCancelledRequest() {
        let expectation = XCTestExpectation(description: "Download apple.com home page")
        let query = OrderDetailQuery(variables: OrderDetailQuery.Variables(orderId: "32", someString: "test", someInt: nil, someDict: nil))
        let request = self.client.execute(query)
            .onSuccess({ _ in XCTFail("Request must be ignore cancel") })
            .onFailure({ _ in XCTFail("Request must be ignore cancel") })
            .onFinish({ XCTFail("Request must be ignore cancel") })
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            expectation.fulfill()
        }
        request.cancel()
        wait(for: [expectation], timeout: 10.0)
    }

}
