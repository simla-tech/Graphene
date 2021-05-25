//
//  GraphQLOperation+PrepareOperationData.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 19.05.2021.
//

import Foundation

extension GraphQLOperation {
    
    public func prepareContext() -> OperationContext {
        
        let field = self.asField
        let variablesArr = field.variables
        let fragments = field.fragments

        // Prepare query string
        var query = "\(Self.mode.rawValue) \(Self.operationName)"
        if !variablesArr.isEmpty {
            let variablesStrCompact = variablesArr.map { variable -> String in
                return "$\(variable.key):\(variable.schemaType)"
            }
            query += "(\(variablesStrCompact.joined(separator: ",")))"
        }
        query += " {\(field.buildField())}"
        
        if !fragments.isEmpty {
            query += fragments.map({ $0.fragmentBody }).joined()
        }
        
        return OperationContext(operationName: Self.operationName,
                                query: query,
                                variables: variablesArr)
        
    }
    
}
