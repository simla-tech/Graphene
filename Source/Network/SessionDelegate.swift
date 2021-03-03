//
//  Logger.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 28.01.2021.
//

import Foundation
import os.log

@objc public protocol SessionDelegate: AnyObject {
    @objc optional func requestSended(operation: String, query: String, variablesJson: String?)
    @objc optional func responseRecived(operation: String, statusCode: Int, interval: DateInterval)
}

internal class DefaultSessionDelegate: SessionDelegate {
        
    func requestSended(operation: String, query: String, variablesJson: String?) {
        if let variables = variablesJson {
            os_log("[Graphene] Request \"%@\" sended:\n%@\nvariables: %@", operation, query, variables)
        } else {
            os_log("[Graphene] Request \"%@\" sended:\n%@", operation, query)
        }
    }
    
    func responseRecived(operation: String, statusCode: Int, interval: DateInterval) {
        os_log("[Graphene] Response \"%@\" recived. Code: %d. Duration: %.3f", operation, statusCode, interval.duration)
    }
    
}
