//
//  XCTAssertInspectorResponse.swift
//  GrapheneInspector
//
//  Created by Ilya Kharlamov on 7/18/22.
//

import Foundation
import XCTest

public func XCTAssertInspectorResponse(
    _ response: Result<GrapheneInspector.Response, Error>,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    do {
        let response = try response.get()
        for error in response.errors {
            XCTFail(error.localizedDescription, file: file, line: line)
        }
        for deprecated in response.deprecated {
            XCTContext.runActivity(named: "Warning") { activity in
                let messageAttachment = XCTAttachment(string: deprecated.localizedDescription)
                messageAttachment.lifetime = .keepAlways
                activity.add(messageAttachment)
            }
        }
    } catch {
        XCTFail(error.localizedDescription, file: file, line: line)
    }
}
