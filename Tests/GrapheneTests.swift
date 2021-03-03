//
//  GrapheneTests.swift
//  GrapheneTests
//
//  Created by Ilya Kharlamov on 22.01.2021.
//

import XCTest
import Alamofire
@testable import Graphene

class GrapheneTests: XCTestCase {
    
    lazy var client: Graphene.Session = {
        var config: Graphene.Session.Configuration = .default
        config.httpHeaders = ["Authorization": "Bearer XXX"]
        config.validation = Self.customValidationBlock
        config.decoder.keyDecodingStrategy = .convertFromSnakeCase
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "ru_RU")
        config.decoder.dateDecodingStrategy = .formatted(formatter)
        return Session(url: "https://localhost:3241/app/api", configuration: config)
    }()
    
    static let customValidationBlock: DataRequest.Validation = { _, _, data in
        
        guard let data = data, let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            return .success(())
        }
        
        if let errorType = json["error"] as? String, errorType == "invalid_grant",
            let errorDescription = json["error_description"] as? String {
            return .failure(TestError(errorDescription: errorDescription))
            
        } else if let errorType = json["error"] as? String, errorType == "access_denied",
            let errorDescription = json["error_description"] as? String {
            return .failure(TestError(errorDescription: errorDescription))
            
        } else if let errorDescription = json["error_description"] as? String {
            return .failure(TestError(errorDescription: errorDescription))
            
        } else if let errorMsg = json["errorMsg"] as? String {
            return .failure(TestError(errorDescription: errorMsg))
        }

        return .success(())

    }
    
    func testQuery() throws {
        let operation = OrderListQuery(first: 10, after: nil, filter: nil)
        let expectedQuery = """
        {totalCount,pageInfo{...PageInfoFragment},edges{node{id,number,unionCustomer{__typename,id,createdAt}}}}
        """
        let field = operation.query.buildField()
        XCTAssertTrue(field.contains(expectedQuery))
        XCTAssertTrue(field.contains("after:null"))
        XCTAssertTrue(field.contains("first:10"))
        XCTAssertTrue(field.contains("filter:null"))

    }
    
    func testFragments() throws {
        let operation = OrderDetailQuery(orderId: "32")
        let fragments = operation.asField.fragments.map({ $0.fragmentName })
        XCTAssertTrue(fragments.contains("OrderDetailFragment"))
        XCTAssertTrue(fragments.contains("PageInfoFragment"))
        XCTAssertTrue(fragments.contains("MoneyFragment"))
    }
    
}

private struct TestError: LocalizedError {
    var errorDescription: String?
}
