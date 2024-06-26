//
//  Client+ExecuteBatch.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 21.09.2021.
//  Copyright © 2021 DIGITAL RETAIL TECHNOLOGIES, S.L. All rights reserved.
//

import Alamofire
import Foundation

public extension Client {

    func execute<O: GraphQLOperation>(
        _ operations: [O],
        queue: DispatchQueue = .main
    ) -> ExecuteBatchRequest<O> where O.RootSchema: MutationSchema {
        self.executeBatch(operations, queue: queue)
    }

    func execute<O: GraphQLOperation>(
        _ operations: [O],
        queue: DispatchQueue = .main
    ) -> ExecuteBatchRequest<O> where O.RootSchema: QuerySchema {
        self.executeBatch(operations, queue: queue)
    }

    private func executeBatch<O: GraphQLOperation>(_ operations: [O], queue: DispatchQueue = .main) -> ExecuteBatchRequest<O> {

        if O.RootSchema.mode == .subscription {
            assertionFailure(
                "You can't execute \"\(O.operationName)\" operation. \"\(String(describing: O.RootSchema.self))\" must have .query or .mutation mode"
            )
        }
        let multipartFormData = MultipartFormData(fileManager: .default, boundary: nil)

        let operationContexts = operations.map({ OperationContextData(operation: $0) })
        let operations = operationContexts.map({ $0.getOperationJSON() }).joined(separator: ",")
        multipartFormData.append(Data("[\(operations)]".utf8), withName: "operations")
        let uploads = operationContexts.enumerated().reduce(into: [String: Upload]()) { uploads, context in
            for upload in context.element.getUploads() {
                uploads["\(context.offset).\(upload.key)"] = upload.value
            }
        }
        self.append(uploads: uploads, to: multipartFormData)

        let context = BatchOperationContextData(operation: O.self, operationContexts: operationContexts)

        guard let batchUrl = self.batchUrl else {
            fatalError("To use batch request please provide batchUrl option in Client.init method")
        }

        let dataRequest = self.prepareDataRequest(context: context, with: multipartFormData, url: batchUrl)
        return ExecuteBatchRequestImpl(
            client: self,
            alamofireRequest: dataRequest,
            decodePath: O.decodePath(of: O.ResponseValue.self),
            context: context,
            queue: queue
        )
    }

}
