//
//  QueryBuilder.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 03.02.2021.
//

import Foundation

public typealias QueryBuilder<T: Queryable> = (QueryContainer<T>) -> Void
