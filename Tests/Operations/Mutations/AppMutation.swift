//
//  AppMutations.swift
//  GrapheneTests
//
//  Created by Ilya Kharlamov on 03.08.2021.
//  Copyright © 2021 DIGITAL RETAIL TECHNOLOGIES, S.L. All rights reserved.
//

import Foundation
@testable import Graphene

struct AppMutation: MutationSchema {

    final class QueryKeys: QueryKey {

        static func editOrder(input: Argument<EditOrderInput>, _ builder: @escaping QueryBuilder<EditOrderPayload>) -> QueryKeys {
            return Query("editOrder", args: ["input": input], builder).asKey()
        }

        static func uploadAttachment(input: Argument<UploadAttachmentInput>,
                                     _ builder: @escaping QueryBuilder<UploadAttachmentPayload>) -> QueryKeys {
            return Query("uploadAttachment", args: ["input": input], builder).asKey()
        }

    }

}
