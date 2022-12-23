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

    static func decodePath(of decodable: [Attachment].Type) -> String? {
        "uploadAttachment.attachments"
    }

    static func buildQuery(with builder: QueryContainer<APIMutationSchema>) {
        builder += .uploadAttachment(input: .reference(to: \Variables.input), { builder in
            builder += .attachments { builder in
                builder += .id
            }
        })
    }

}
