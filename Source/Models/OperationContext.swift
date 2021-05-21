//
//  GraphQLOperationData.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 19.05.2021.
//

import Foundation

public struct OperationContext {
    
    public let operationName: String
    public let query: String
    public let variables: [SomeInputVariable]

    public func jsonVariablesString(prettyPrinted: Bool = false) -> String? {
        
        guard !self.variables.isEmpty else { return nil }
        
        let variablesJson = self.variables.reduce(into: [String: Any](), {
            if let value = $1.value { $0[$1.key] = value.json }
        })
        
        guard let variablesData = try? JSONSerialization.data(withJSONObject: variablesJson,
                                                              options: prettyPrinted ? [.prettyPrinted, .sortedKeys] : []) else {
            return nil
        }
        
        return String(data: variablesData, encoding: .utf8)
        
    }
    
}
