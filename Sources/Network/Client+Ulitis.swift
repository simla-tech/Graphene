//
//  Client+Ulitis.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 21.09.2021.
//  Copyright © 2021 DIGITAL RETAIL TECHNOLOGIES, S.L. All rights reserved.
//

import Alamofire
import Foundation

extension Client {

    func append(uploads: [String: Upload], to multipartFormData: MultipartFormData) {
        let mapStr = uploads.enumerated().map({ index, upload -> String in
            "\"\(index)\": [\"\(upload.key)\"]"
        }).joined(separator: ",")
        if let data = "{\(mapStr)}".data(using: .utf8) {
            multipartFormData.append(data, withName: "map")
        }
        for (index, upload) in uploads.enumerated() {
            multipartFormData.append(
                upload.value.data,
                withName: "\(index)",
                fileName: upload.value.name,
                mimeType: MimeType(path: upload.value.name).value
            )
        }
    }

    func httpHeaders<O: GraphQLOperation>(for type: O.Type) -> HTTPHeaders {
        var httpHeaders = self.configuration.prepareHttpHeaders()
        if self.configuration.useOperationNameAsReferer {
            httpHeaders.add(name: "Referer", value: "/\(O.RootSchema.mode.rawValue)/\(O.operationName)")
        }
        return httpHeaders
    }

    func prepareDataRequest<O: GraphQLOperation>(
        for type: O.Type,
        with multipartFormData: MultipartFormData,
        url: URLConvertible
    ) -> UploadRequest {

        var dataRequest = self.alamofireSession.upload(
            multipartFormData: multipartFormData,
            to: url,
            usingThreshold: MultipartFormData.encodingMemoryThreshold,
            method: .post,
            headers: self.httpHeaders(for: type),
            requestModifier: self.configuration.requestModifier
        )

        // Set up validators
        if let customValidation = self.configuration.validation {
            dataRequest = dataRequest.validate(customValidation)
        }

        dataRequest = dataRequest
            .validate(GrapheneValidator.validateGraphQLError(request:response:data:))
            .validate(GrapheneValidator.validateStatus(request:response:data:))
            .validate()
        return dataRequest
    }

}
