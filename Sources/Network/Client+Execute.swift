//
//  Client+Execute.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 03.08.2021.
//  Copyright © 2021 DIGITAL RETAIL TECHNOLOGIES, S.L. All rights reserved.
//

import Alamofire
import Foundation

public extension Client {

    func execute<O: GraphQLOperation>(
        _ operation: O,
        queue: DispatchQueue = .main
    ) -> ExecuteRequest<O> where O.RootSchema: MutationSchema {
        self.executeQuery(operation, queue: queue)
    }

    func execute<O: GraphQLOperation>(
        _ operation: O,
        queue: DispatchQueue = .main
    ) -> ExecuteRequest<O> where O.RootSchema: QuerySchema {
        self.executeQuery(operation, queue: queue)
    }

    private func executeQuery<O: GraphQLOperation>(_ operation: O, queue: DispatchQueue = .main) -> ExecuteRequest<O> {

        if O.RootSchema.mode == .subscription {
            assertionFailure(
                "You can't execute \"\(O.operationName)\" operation. \"\(String(describing: O.RootSchema.self))\" must have .query or .mutation mode"
            )
        }

        let operationContext = OperationContextData(operation: operation)
        let multipartFormData = MultipartFormData(fileManager: .default, boundary: nil)
        let operations = operationContext.getOperationJSON()
        if let data = operations.data(using: .utf8) {
            multipartFormData.append(data, withName: "operations")
        }
        self.append(uploads: operationContext.getUploads(), to: multipartFormData)

        let dataRequest = self.prepareDataRequest(context: operationContext, with: multipartFormData, url: self.url)
        return ExecuteRequestImpl(
            client: self,
            alamofireRequest: dataRequest,
            decodePath: O.decodePath(of: O.ResponseValue.self),
            context: operationContext,
            queue: queue
        )
    }

}
