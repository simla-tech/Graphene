//
//  UploadAttachmentPayload.swift
//  GrapheneTests
//
//  Created by Ilya Kharlamov on 03.02.2021.
//

import Foundation
@testable import Graphene

struct UploadAttachmentPayload: Decodable, Queryable {
    
    var attachments: [Attachment]
    
    class QueryKeys: QueryKey {
        static func attachments(_ builder: @escaping QueryBuilder<Attachment>) -> QueryKeys {
            return Query(CodingKeys.attachments, builder).asKey()
        }
    }
    
}
