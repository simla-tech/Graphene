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

    private var dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "ru_RU")
        return .formatted(formatter)
    }()

    lazy var client: Client = {
        var config: Client.Configuration = .default
        config.httpHeaders = ["Authorization": "Bearer XXX"]
        // config.validation = Self.customValidationBlock
        config.keyDecodingStrategy = .convertFromSnakeCase
        config.dateDecodingStrategy = self.dateDecodingStrategy
        return Client(url: "https://localhost:3241/app/api", configuration: config)
    }()

    func testVariableIdentifiers() {
        let allKeys = OrderDetailQuery.Variables.allKeys
        let firstIdentifiers = Set(allKeys.map({ $0.identifier }))
        let secondIdentifiers = Set(allKeys.map({ $0.identifier }))
        XCTAssertEqual(firstIdentifiers, secondIdentifiers)
    }

    func testVariableSchemaTypes() {
        let allKeys = OrderDetailQuery.Variables.allKeys
        let types = Set(allKeys.map({ $0.variableType }))
        XCTAssertEqual(types, ["String!", "Int", "Unknown_Dictionary<String, Float>"])
    }

    func testInputVariablesTypes() {

        /*
         Swift    | GraphQL
         -------------------
         Some     | Some!
         Some?    | Some
         [Some]   | [Some!]!
         [Some]?  | [Some!]
         [Some?]  | [Some]!
         [Some?]? | [Some]
         */

        let variable = SomeVariable(qqq: "qwe")
        XCTAssertEqual(type(of: variable).variableType, "SomeVariable!")

        let variable2: SomeVariable? = SomeVariable(qqq: "qwe")
        XCTAssertEqual(type(of: variable2).variableType, "SomeVariable")

        let variable3: [SomeVariable] = [SomeVariable(qqq: "qwe")]
        XCTAssertEqual(type(of: variable3).variableType, "[SomeVariable!]!")

        let variable4: [SomeVariable]? = [SomeVariable(qqq: "qwe")]
        XCTAssertEqual(type(of: variable4).variableType, "[SomeVariable!]")

        let variable5: [SomeVariable?] = [SomeVariable(qqq: "qwe")]
        XCTAssertEqual(type(of: variable5).variableType, "[SomeVariable]!")

        let variable6: [SomeVariable?]? = [SomeVariable(qqq: "qwe")]
        XCTAssertEqual(type(of: variable6).variableType, "[SomeVariable]")

    }

    func testQuery() {
        print("--\nQUERY:\n", OrderDetailQuery.buildQuery())
        let query = OrderDetailQuery(variables: .init(orderId: "48"))
        let context = query.prepareContext()
        print("-\nVARS:\n", context.jsonVariablesString(prettyPrinted: true) ?? "none")
    }

    func testChangeSet() {

        var orignal = Order(id: Order.ID())
        orignal.contragent = Contragent(contragentType: .enterpreneur)
        orignal.contragent?.INN = "1231232"
        orignal.contragent?.KPP = "31232"
        orignal.deliveryContragent = Contragent(contragentType: .individual)
        orignal.deliveryContragent?.INN = "3232"
        orignal.deliveryContragent?.KPP = "3213"
        orignal.payments = [
            Payment(id: "1"),
            Payment(id: "2", comment: "1231232")
        ]
        orignal.nickName = "Ilya"
        orignal.lastName = "Kharlamov"
        orignal.number = "3333"

        var clone = orignal
        clone.contragent?.KPP = nil
        clone.contragent?.OGRN = "1231232"
        clone.deliveryContragent = nil
        clone.customerContragent = Contragent(contragentType: .legalEntity)
        clone.customerContragent?.INN = "4122"
        clone.customerContragent?.KPP = "123123"
        clone.payments?.remove(at: 0)
        clone.payments?[0].comment = "123212"
        clone.payments?[0].paidAt = Date()
        let newPaymentId = Payment.ID()
        clone.payments?.append(Payment(id: newPaymentId))
        clone.nickName = "12332"
        clone.number = nil
        clone.firstName = "Nick"
        clone.lastName = "Kharlamov"

        let changeSet = ChangeSet(source: orignal, target: clone)

        if let contragentChange = changeSet.first(where: "contragent") as? RootChange {
            XCTAssert(!contragentChange.childChanges.contains(where: { $0.key == "INN" }))
            XCTAssert(contragentChange.childChanges.contains(where: { $0.key == "KPP" && $0 is FieldChange }))
            XCTAssert(contragentChange.childChanges.contains(where: { $0.key == "OGRN" && $0 is FieldChange }))
        } else {
            XCTFail("contragent change not found")
        }

        XCTAssert(changeSet.contains(where: { $0.key == "deliveryContragent" && $0 is FieldChange }))
        XCTAssert(changeSet.contains(where: { $0.key == "customerContragent" && $0 is FieldChange }))

        if let paymentsChange = changeSet.first(where: "payments") as? RootChange {
            if let editPayment = paymentsChange.childChanges.first(where: { $0.key == "2" }) as? RootChange {
                XCTAssert(!editPayment.childChanges.contains(where: { $0.key == "status" }))
                XCTAssert(!editPayment.childChanges.contains(where: { $0.key == "amount" }))
                XCTAssert(editPayment.childChanges.contains(where: { $0.key == "comment" && $0 is FieldChange }))
                XCTAssert(editPayment.childChanges.contains(where: { $0.key == "paidAt" && $0 is FieldChange }))
            } else {
                XCTFail("payment change not found")
            }

            XCTAssert(paymentsChange.childChanges.contains(where: { $0.key == newPaymentId.description && $0 is FieldChange }))

        } else {
            XCTFail("payments change not found")
        }

        XCTAssert(changeSet.contains(where: { $0.key == "nickName" && $0 is FieldChange }))
        XCTAssert(changeSet.contains(where: { $0.key == "number" && $0 is FieldChange }))
        XCTAssert(changeSet.contains(where: { $0.key == "firstName" && $0 is FieldChange }))
        XCTAssert(!changeSet.contains(where: { $0.key == "lastName" && $0 is FieldChange }))

    }

}

    /*

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
        XCTAssertTrue(field.contains("first:10"))

    }

    func testFragments() throws {
        let operation = OrderDetailQuery(orderId: "32")
        let fragments = operation.asField.fragments.map({ $0.fragmentName })
        XCTAssertTrue(fragments.contains("OrderDetailFragment"))
        XCTAssertTrue(fragments.contains("PageInfoFragment"))
        XCTAssertTrue(fragments.contains("MoneyFragment"))
    }

    func testInputVariablesTypes() {

         Swift    | GraphQL
         -------------------
         Some     | Some!
         Some?    | Some
         [Some]   | [Some!]!
         [Some]?  | [Some!]
         [Some?]  | [Some]!
         [Some?]? | [Some]

        let variable = SomeVariable(qqq: "qwe")
        XCTAssertEqual(InputVariable(variable).schemaType, "SomeVariable!")

        let variable2: SomeVariable? = SomeVariable(qqq: "qwe")
        XCTAssertEqual(InputVariable(variable2).schemaType, "SomeVariable")

        let variable3: [SomeVariable] = [SomeVariable(qqq: "qwe")]
        XCTAssertEqual(InputVariable(variable3).schemaType, "[SomeVariable!]!")

        let variable4: [SomeVariable]? = [SomeVariable(qqq: "qwe")]
        XCTAssertEqual(InputVariable(variable4).schemaType, "[SomeVariable!]")

        let variable5: [SomeVariable?] = [SomeVariable(qqq: "qwe")]
        XCTAssertEqual(InputVariable(variable5).schemaType, "[SomeVariable]!")

        let variable6: [SomeVariable?]? = [SomeVariable(qqq: "qwe")]
        XCTAssertEqual(InputVariable(variable6).schemaType, "[SomeVariable]")

    }

}

private struct SomeVariable: Codable, EncodableVariable, SchemaType {
    var qqq: String

    func encode(to encoder: VariableEncoder) {
        let container = encoder.container(keyedBy: CodingKeys.self)
        container.encode(self.qqq, forKey: .qqq)
    }
}

private struct TestError: LocalizedError {
    var errorDescription: String?
}
*/

private struct SomeVariable: Codable, EncodableVariable {
    var qqq: String

    func encode(to encoder: VariableEncoder) {
        let container = encoder.container(keyedBy: CodingKeys.self)
        container.encode(self.qqq, forKey: .qqq)
    }
}
