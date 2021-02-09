//
//  Logger.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 28.01.2021.
//

import Foundation
import os.log

public protocol LoggerProtocol {
    func requestSended(operation: String, query: String, variablesJson: String?)
    func responseRecived(operation: String, statusCode: Int, interval: DateInterval)
}

internal class Logger: LoggerProtocol {
    
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
