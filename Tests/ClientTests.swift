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
        let expectation = XCTestExpectation(description: "Download apple.com home page")
        let query = OrderDetailQuery(variables: .init(orderId: "48"))
        let request = self.client.execute(query) { response in
            XCTAssertEqual(response.error?.localizedDescription, AFError.explicitlyCancelled.localizedDescription)
            expectation.fulfill()
        }
        request.cancel()
        wait(for: [expectation], timeout: 10.0)
    }

}
