//
//  Logger.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 28.01.2021.
//

import Foundation
import os.log

public protocol GrapheneLoggerDelegate: AnyObject {
    func requestSended(context: OperationContext)
    func responseRecived(statusCode: Int, interval: DateInterval, context: OperationContext)
    func errorCatched(_ error: Error, context: OperationContext)
}

internal class DefaultLoggerDelegate: GrapheneLoggerDelegate {
        
    func requestSended(context: OperationContext) {
        if let variables = try? context.jsonVariablesString(prettyPrinted: true) {
            os_log("[Graphene] Request \"%@\" sended:\n%@\nvariables: %@", context.operationName, context.query, variables)
        } else {
            os_log("[Graphene] Request \"%@\" sended:\n%@", context.operationName, context.query)
        }
    }
    
    func responseRecived(statusCode: Int, interval: DateInterval, context: OperationContext) {
        os_log("[Graphene] Response \"%@\" recived. Code: %d. Duration: %.3f", context.operationName, statusCode, interval.duration)
    }
    
    func errorCatched(_ error: Error, context: OperationContext) {
        os_log("[Graphene] Catched error for \"%@\" operation: %@", context.operationName, error.localizedDescription)
    }
    
}
