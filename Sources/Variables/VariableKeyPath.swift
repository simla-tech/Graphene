//
//  File.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 02.08.2021.
//  Copyright © 2021 DIGITAL RETAIL TECHNOLOGIES, S.L. All rights reserved.
//

import Foundation

/*
 public class VariableKeyPath<Value: Variable> {
     private let anyKeyPath: AnyKeyPath
     private init<Root: QueryVariables>(keyPath: KeyPath<Root, Value>) {
         self.anyKeyPath = keyPath
     }
 }

 public extension VariableKeyPath {
     static func from<Root: QueryVariables>(_ path: KeyPath<Root, Value>) -> VariableKeyPath<Value> {
         return VariableKeyPath(keyPath: path)
     }
 }

 extension VariableKeyPath: Argument {
     public var rawValue: String {
         return "$\(self.anyKeyPath.identifier)"
     }
 }
 */
