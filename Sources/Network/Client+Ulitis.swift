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

    func prepareDataRequest(
        context: OperationContext,
        with multipartFormData: MultipartFormData,
        url: URLConvertible
    ) -> UploadRequest {

        var headers: HTTPHeaders = [
            HTTPHeader(name: "Referer", value: "/\(context.mode.rawValue)/\(context.operationName)"),
            .operationName(context.operationName)
        ]

        if let variablesHash = context.variables?.hash {
            headers.add(.variablesHash(variablesHash))
        }

        var dataRequest = self.session.upload(
            multipartFormData: multipartFormData,
            to: url,
            usingThreshold: MultipartFormData.encodingMemoryThreshold,
            method: .post,
            headers: headers,
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
