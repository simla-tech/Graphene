//
//  Client+Execute.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 03.08.2021.
//  Copyright © 2021 DIGITAL RETAIL TECHNOLOGIES, S.L. All rights reserved.
//

import Foundation
import Alamofire

extension Client {

    public func execute<O: GraphQLOperation>(_ operation: O,
                                             queue: DispatchQueue = .main) -> ExecuteRequest<O> where O.RootSchema: MutationSchema {
        return self.executeQuery(operation, queue: queue)
    }

    public func execute<O: GraphQLOperation>(_ operation: O,
                                             queue: DispatchQueue = .main) -> ExecuteRequest<O> where O.RootSchema: QuerySchema {
        return self.executeQuery(operation, queue: queue)
    }

    private func executeQuery<O: GraphQLOperation>(_ operation: O, queue: DispatchQueue = .main) -> ExecuteRequest<O> {

        if O.RootSchema.mode == .subscription {
            assertionFailure("You can't execute \"\(O.operationName)\" operation. \"\(String(describing: O.RootSchema.self))\" must have .query or .mutation mode")
        }

        let operationContext = OperationContextData(operation: operation)
        let multipartFormData = MultipartFormData(fileManager: .default, boundary: nil)
        let operations = operationContext.getOperationJSON()
        if let data = operations.data(using: .utf8) {
            multipartFormData.append(data, withName: "operations")
        }
        self.append(uploads: operationContext.getUploads(), to: multipartFormData)

        let dataRequest = self.prepareDataRequest(for: O.self, with: multipartFormData, url: self.url)
        return ExecuteRequest(alamofireRequest: dataRequest,
                              decodePath: O.decodePath(of: O.ResponseValue.self),
                              context: operationContext,
                              config: self.configuration,
                              queue: queue)
    }

}
