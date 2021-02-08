//
//  Logger.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 28.01.2021.
//

import Foundation
import os.log

public protocol LoggerProtocol {
    func requestSended(query: String, variablesJson: String?)
    func responseRecived(id: String, statusCode: Int, interval: DateInterval)
}

internal class Logger: LoggerProtocol {
    
    func requestSended(query: String, variablesJson: String?) {
        if let variables = variablesJson {
            os_log("[Graphene] Request sended:\n%@\nvariables: %@", query, variables)
        } else {
            os_log("[Graphene] Request sended:\n%@", query)
        }
    }
    
    func responseRecived(id: String, statusCode: Int, interval: DateInterval) {
        os_log("[Graphene] Response \"%@\" recived. Code: %d. Duration: %.3f", id, statusCode, interval.duration)
    }
    
}
