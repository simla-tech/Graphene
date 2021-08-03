//
//  UploadAttachmentOperation.swift
//  GrapheneTests
//
//  Created by Ilya Kharlamov on 03.02.2021.
//

import Foundation
@testable import Graphene

struct UploadAttachmentMutation: GraphQLOperation {

    let variables: Variables

    struct Variables: QueryVariables {
        let input: UploadAttachmentInput
        static var allKeys: [PartialKeyPath<Variables>] = [\Variables.input]
    }

    static func handleResponse(_ response: ExecuteResponse<AppMutation>) throws -> [Attachment] {
        return try response.get({ $0.uploadAttachment?.attachments })
    }

    static func buildQuery(with builder: QueryContainer<AppMutation>) {
        builder += .uploadAttachment(input: .reference(to: \Variables.input), { builder in
            builder += .attachments { builder in
                builder += .id
            }
        })
    }

}
