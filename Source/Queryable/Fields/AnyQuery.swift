//
//  AnyQuery.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 10.02.2021.
//

import Foundation

protocol AnyQuery: Field {
    var name: String { get }
    var alias: String? { get }
}

extension AnyQuery {
    
    public func buildField() -> String {
        var res = [String]()
        
        if let alias = self.alias {
            res.append("\(alias):\(self.name)")
        } else {
            res.append(self.name)
        }
        if !self.arguments.isEmpty {
            let argumentsStr = self.arguments
                .map({ "\($0):\($1.rawValue)" })
                .joined(separator: ",")
            res.append("(\(argumentsStr))")
        }
        
        if !self.childrenFields.isEmpty {
            res.append("{\(self.childrenFields.map({ $0.buildField() }).joined(separator: ","))}")
        }
        
        return res.joined()
    }
    
}
