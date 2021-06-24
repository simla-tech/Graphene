//
//  Logger.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 28.01.2021.
//

import Foundation
import os.log

public protocol GrapheneDelegate: AnyObject {
    func requestWillSend(context: OperationContext)
    func responseRecived(statusCode: Int, interval: DateInterval, context: OperationContext)
    func errorCatched(_ error: Error, context: OperationContext)
}

internal class DefaultDelegate: GrapheneDelegate {
        
    func requestWillSend(context: OperationContext) {
        if let variables = context.jsonVariablesString(prettyPrinted: true) {
            os_log("[Graphene.DefaultDelegate] Will send request \"%@\":\n%@\nvariables: %@", context.operationName, context.query, variables)
        } else {
            os_log("[Graphene.DefaultDelegate] Will send request \"%@\":\n%@", context.operationName, context.query)
        }
    }
    
    func responseRecived(statusCode: Int, interval: DateInterval, context: OperationContext) {
        os_log("[Graphene.DefaultDelegate] Response \"%@\" recived. Code: %d. Duration: %.3f", context.operationName, statusCode, interval.duration)
    }
    
    func errorCatched(_ error: Error, context: OperationContext) {
        os_log("[Graphene.DefaultDelegate] Catched error for \"%@\" operation: %@", context.operationName, error.localizedDescription)
    }
    
}
