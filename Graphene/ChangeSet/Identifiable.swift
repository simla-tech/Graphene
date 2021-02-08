//
//  Identity.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 02.02.2021.
//

import Foundation

public protocol AnyIdentifiable {
    var anyIdentifier: AnyHashable { get }
}

public protocol Identifiable: AnyIdentifiable {
    associatedtype DifferenceIdentifier: Hashable
    var identifier: DifferenceIdentifier { get }
}

public extension Identifiable {
    var anyIdentifier: AnyHashable {
        return self.identifier
    }
}

public extension Identifiable where Self: Hashable {
    var identifier: Int {
        return self.hashValue
    }
}

internal typealias AnyIdentifiableVariable = AnyIdentifiable & Variable
