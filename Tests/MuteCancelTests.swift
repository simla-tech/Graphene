//
//  MuteCancelTests.swift
//  GrapheneTests
//
//  Created by Ilya Kharlamov on 03.08.2021.
//  Copyright © 2021 RetailDriver LLC. All rights reserved.
//

import XCTest
import Alamofire
@testable import Graphene

class MuteCancelTests: XCTestCase {

    private lazy var client: Client = {
        var config: Client.Configuration = .default
        config.muteCanceledRequests = true
        return Client(url: "https://google.com/app/api", configuration: config)
    }()

    func testMuteCancelledRequest() {
        let expectation = XCTestExpectation(description: "Download apple.com home page")
        let query = OrderDetailQuery(variables: .init(orderId: "48"))
        let request = self.client.execute(query) { _ in
            XCTFail("Request must be ignore cancel")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            expectation.fulfill()
        }
        request.cancel()
        wait(for: [expectation], timeout: 10.0)
    }

}
