//
//  UploadAttachmentOperation.swift
//  GrapheneTests
//
//  Created by Ilya Kharlamov on 03.02.2021.
//

import Foundation
@testable import Graphene

final class UploadAttachmentMutation: MutationOperation {
    
    let input: UploadAttachmentInput
    
    init(input: UploadAttachmentInput) {
        self.input = input
    }

    lazy var query = Query<UploadAttachmentPayload>("uploadAttachment", args: ["input": InputVariable(self.input)]) { builder in
        builder += .attachments { builder in
            builder += .id
        }
    }

}
