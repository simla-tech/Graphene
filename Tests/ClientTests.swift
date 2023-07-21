//
//  ClientTests.swift
//  GrapheneTests
//
//  Created by Ilya Kharlamov on 03.08.2021.
//  Copyright © 2021 DIGITAL RETAIL TECHNOLOGIES, S.L. All rights reserved.
//

import Alamofire
import XCTest
@testable import Graphene

class ClientTests: XCTestCase {

    private var dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "ru_RU")
        return .formatted(formatter)
    }()

    private lazy var client: Client = {
        var config: Client.Configuration = .default
        config.session.headers = ["Authorization": "Bearer XXX"]
        config.keyDecodingStrategy = .convertFromSnakeCase
        config.dateDecodingStrategy = self.dateDecodingStrategy
        config.muteCanceledRequests = false
        return Client(url: "https://google.com/app/api", batchUrl: "https://google.com/app/api/batch", configuration: config)
    }()

    func testCancelledError() {
        let expectation = XCTestExpectation()
        let query = OrderDetailQuery(variables: OrderDetailQuery.Variables(orderId: "1", someString: "test", someInt: nil, someDict: nil))
        let request = self.client.execute(query)
            .onSuccess({ _ in XCTFail("There is no error") })
            .onFailure({ XCTAssertEqual($0.localizedDescription, AFError.explicitlyCancelled.localizedDescription) })
            .onFinish(expectation.fulfill)
        request.cancel()
        wait(for: [expectation], timeout: 5.0)
    }

    func testQuery() {
        let expectation = XCTestExpectation()
        print("--\nQUERY:\n", OrderDetailQuery.buildQuery())
        let query = OrderDetailQuery(variables: OrderDetailQuery.Variables(orderId: "1", someString: "test", someInt: nil, someDict: nil))
        let request = self.client.execute(query)
        print("-\nVARS:\n", request.context.variables(prettyPrinted: true) ?? "none")
        request.onFinish(expectation.fulfill)
        wait(for: [expectation], timeout: 10.0)
    }

    func testBatchQuery() {
        let expectation = XCTestExpectation()
        print("--\nQUERY:\n", OrderDetailQuery.buildQuery())
        let query1 = OrderDetailQuery(variables: OrderDetailQuery.Variables(orderId: "1", someString: "test", someInt: nil, someDict: nil))
        let query2 = OrderDetailQuery(variables: OrderDetailQuery.Variables(orderId: "2", someString: "test", someInt: nil, someDict: nil))
        let query3 = OrderDetailQuery(variables: OrderDetailQuery.Variables(orderId: "3", someString: "test", someInt: nil, someDict: nil))
        let request = self.client.execute([query1, query2, query3])
        request.onFinish(expectation.fulfill)
        wait(for: [expectation], timeout: 10.0)
    }

}
