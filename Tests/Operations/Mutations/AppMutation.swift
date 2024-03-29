//
//  APIMutationSchemas.swift
//  GrapheneTests
//
//  Created by Ilya Kharlamov on 03.08.2021.
//  Copyright © 2021 DIGITAL RETAIL TECHNOLOGIES, S.L. All rights reserved.
//

import Foundation
@testable import Graphene

struct APIMutationSchema: MutationSchema {

    final class QueryKeys: QueryKey {

        static func editOrder(input: Argument<EditOrderInput>, _ builder: @escaping QueryBuilder<EditOrderPayload>) -> QueryKeys {
            Query("editOrder", args: ["input": input], builder).asKey()
        }

        static func uploadAttachment(
            input: Argument<UploadAttachmentInput>,
            _ builder: @escaping QueryBuilder<UploadAttachmentPayload>
        ) -> QueryKeys {
            Query("uploadAttachment", args: ["input": input], builder).asKey()
        }

    }

}
