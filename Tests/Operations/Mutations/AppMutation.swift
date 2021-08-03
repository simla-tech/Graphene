//
//  AppMutations.swift
//  GrapheneTests
//
//  Created by Ilya Kharlamov on 03.08.2021.
//  Copyright © 2021 RetailDriver LLC. All rights reserved.
//

import Foundation
@testable import Graphene

struct AppMutation: Schema {

    static let mode: OperationMode = .mutation

    let editOrder: EditOrderPayload?
    let uploadAttachment: UploadAttachmentPayload?

}

extension AppMutation: Queryable {

    final class QueryKeys: QueryKey {

        static func editOrder(input: Argument<EditOrderInput>, _ builder: @escaping QueryBuilder<EditOrderPayload>) -> QueryKeys {
            return Query(CodingKeys.editOrder, args: ["input": input], builder).asKey()
        }

        static func uploadAttachment(input: Argument<UploadAttachmentInput>,
                                     _ builder: @escaping QueryBuilder<UploadAttachmentPayload>) -> QueryKeys {
            return Query(CodingKeys.uploadAttachment, args: ["input": input], builder).asKey()
        }

    }

}
