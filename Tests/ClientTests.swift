//
//  ClientTests.swift
//  GrapheneTests
//
//  Created by Ilya Kharlamov on 03.08.2021.
//  Copyright © 2021 RetailDriver LLC. All rights reserved.
//

import XCTest
import Alamofire
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
        config.httpHeaders = ["Authorization": "Bearer XXX"]
        config.keyDecodingStrategy = .convertFromSnakeCase
        config.dateDecodingStrategy = self.dateDecodingStrategy
        config.muteCanceledRequests = false
        return Client(url: "https://google.com/app/api", configuration: config)
    }()

    func testCancelledError() {
        let expectation = XCTestExpectation()
        let query = OrderDetailQuery(variables: OrderDetailQuery.Variables(orderId: "1", someString: "test", someInt: nil, someDict: nil))
        let request = self.client.execute(query) { response in
            do {
                _ = try response.get()
                XCTFail("There is no error")
            } catch {
                XCTAssertEqual(error.localizedDescription, AFError.explicitlyCancelled.localizedDescription)
            }
            expectation.fulfill()
        }
        request.cancel()
        wait(for: [expectation], timeout: 5.0)
    }

    func testQuery() {
        let expectation = XCTestExpectation()
        print("--\nQUERY:\n", OrderDetailQuery.buildQuery())
        let query = OrderDetailQuery(variables: OrderDetailQuery.Variables(orderId: "1", someString: "test", someInt: nil, someDict: nil))
        let request = self.client.request(for: query)
        print("-\nVARS:\n", request.context.variables(prettyPrinted: true) ?? "none")
        request.perform { response in
            let test = try? response.get()
            print(test ?? [])
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
    }

    func testBatchQuery() {
        let expectation = XCTestExpectation()
        print("--\nQUERY:\n", OrderDetailQuery.buildQuery())
        let query1 = OrderDetailQuery(variables: OrderDetailQuery.Variables(orderId: "1", someString: "test", someInt: nil, someDict: nil))
        let query2 = OrderDetailQuery(variables: OrderDetailQuery.Variables(orderId: "2", someString: "test", someInt: nil, someDict: nil))
        let query3 = OrderDetailQuery(variables: OrderDetailQuery.Variables(orderId: "3", someString: "test", someInt: nil, someDict: nil))
        let request = self.client.request(for: [query1, query2, query3])
        request.perform { response in
            let test = try? response.get()
            print(test ?? [])
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
    }

}
