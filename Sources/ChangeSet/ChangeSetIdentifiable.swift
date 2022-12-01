//
//  Identity.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 02.02.2021.
//

import Foundation

public protocol AnyChangeSetIdentifiable {
    var anyChangeSetIdentifier: AnyHashable { get }
}

public protocol ChangeSetIdentifiable: AnyChangeSetIdentifiable {

    /// A type representing the stable identity of the entity associated with an instance.
    associatedtype ID: Hashable

    /// The stable identity of the entity associated with this instance.
    var id: Self.ID { get }
}

extension ChangeSetIdentifiable {
    public var anyChangeSetIdentifier: AnyHashable { self.id }
}

internal typealias AnyChangeSetIdentifiableVariable = AnyChangeSetIdentifiable & Variable
