//
//  Attachment.swift
//  GrapheneTests
//
//  Created by Ilya Kharlamov on 03.02.2021.
//

import Foundation
@testable import Graphene

struct Attachment: Decodable, Identifiable {

    var id: ID

}

extension Attachment: Queryable {

    class QueryKeys: QueryKey {
        static let id = QueryKeys(CodingKeys.id)
    }

}
