//
//  GrapheneTests.swift
//  GrapheneTests
//
//  Created by Ilya Kharlamov on 22.01.2021.
//

import Alamofire
import XCTest
@testable import Graphene

class QueryTests: XCTestCase {

    func testVariableIdentifiers() {
        let allKeys = OrderDetailQuery.Variables.allKeys
        let firstIdentifiers = Set(allKeys.map(\.identifier))
        let secondIdentifiers = Set(allKeys.map(\.identifier))
        XCTAssertEqual(firstIdentifiers, secondIdentifiers)
    }

    func testVariableSchemaTypes() {
        let allKeys = OrderDetailQuery.Variables.allKeys
        let types = Set(allKeys.map(\.variableType))
        XCTAssertEqual(types, ["String!", "Int", "Unknown_Optional<Dictionary<String, Double>>"])
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

    func testOperationType() {
        XCTAssertEqual(OrderEditMutation.buildQuery().prefix(8), "mutation")
        XCTAssertEqual(OrderDetailQuery.buildQuery().prefix(5), "query")
    }

    func testOperatioMname() {
        XCTAssert(OrderEditMutation.buildQuery().contains("OrderEditMutation("))
        XCTAssert(OrderDetailQuery.buildQuery().contains("OrderDetailQuery("))
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

        clone.payments?.append(Payment(id: "new"))
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

            XCTAssert(paymentsChange.childChanges.contains(where: { $0.key == "new" && $0 is FieldChange }))

        } else {
            XCTFail("payments change not found")
        }

        XCTAssert(changeSet.contains(where: { $0.key == "nickName" && $0 is FieldChange }))
        XCTAssert(changeSet.contains(where: { $0.key == "number" && $0 is FieldChange }))
        XCTAssert(changeSet.contains(where: { $0.key == "firstName" && $0 is FieldChange }))
        XCTAssert(!changeSet.contains(where: { $0.key == "lastName" && $0 is FieldChange }))

    }

}

private struct SomeVariable: Codable, EncodableVariable {
    var qqq: String
    func encode(to encoder: VariableEncoder) {
        let container = encoder.container(keyedBy: CodingKeys.self)
        container.encode(self.qqq, forKey: .qqq)
    }
}
