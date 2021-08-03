//
//  RequestPerformer.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 28.01.2021.
//

import Foundation
import Alamofire

extension Client {

    public func request<O: GraphQLOperation>(for operations: [O]) -> BatchOperationRequest<O> {

        let multipartFormData = MultipartFormData(fileManager: .default, boundary: nil)

        let operationContexts = operations.map({ OperationContextData(operation: $0) })
        let operations = operationContexts.map({ $0.getOperationJSON() }).joined(separator: ",")
        if let data = "[\(operations)]".data(using: .utf8) {
            multipartFormData.append(data, withName: "operations")
        }
        let uploads = operationContexts.enumerated().reduce(into: [String: Upload]()) { uploads, context in
            for upload in context.element.getUploads() {
                uploads["\(context.offset).\(upload.key)"] = upload.value
            }
        }
        self.append(uploads: uploads, to: multipartFormData)

        let context = BatchOperationContextData(operation: O.self, operationContexts: operationContexts)
        let dataRequest = self.dataRequest(with: multipartFormData, url: self.batchUrl)
        return BatchOperationRequest(alamofireRequest: dataRequest,
                                     context: context,
                                     config: self.configuration)
    }

    public func request<O: GraphQLOperation>(for operation: O) -> OperationRequest<O> {
        let operationContext = OperationContextData(operation: operation)
        let multipartFormData = MultipartFormData(fileManager: .default, boundary: nil)
        let operations = operationContext.getOperationJSON()
        if let data = operations.data(using: .utf8) {
            multipartFormData.append(data, withName: "operations")
        }
        self.append(uploads: operationContext.getUploads(), to: multipartFormData)

        let dataRequest = self.dataRequest(with: multipartFormData, url: self.url)
        return OperationRequest(alamofireRequest: dataRequest,
                                context: operationContext,
                                config: self.configuration)
    }

    // MARK: - Utilits

    private func append(uploads: [String: Upload], to multipartFormData: MultipartFormData) {
        let mapStr = uploads.enumerated().map({ (index, upload) -> String in
            return "\"\(index)\": [\"variables.\(upload.key)\"]"
        }).joined(separator: ",")
        if let data = "{\(mapStr)}".data(using: .utf8) {
            multipartFormData.append(data, withName: "map")
        }
        for (index, upload) in uploads.enumerated() {
            multipartFormData.append(upload.value.data,
                                     withName: "\(index)",
                                     fileName: upload.value.name,
                                     mimeType: MimeType(path: upload.value.name).value)
        }
    }

    private var httpHeaders: HTTPHeaders {
        var httpHeaders = self.configuration.httpHeaders ?? []
        if !httpHeaders.contains(where: { $0.name.lowercased() == "user-agent" }),
           let version = Bundle(for: Session.self).infoDictionary?["CFBundleShortVersionString"] as? String {
            httpHeaders.add(.userAgent("Graphene/\(version)"))
        }
        return httpHeaders
    }

    private func dataRequest(with multipartFormData: MultipartFormData, url: URLConvertible) -> UploadRequest {
        var dataRequest = self.alamofireSession.upload(
            multipartFormData: multipartFormData,
            to: url,
            usingThreshold: MultipartFormData.encodingMemoryThreshold,
            method: .post,
            headers: self.httpHeaders,
            requestModifier: self.configuration.requestModifier
        )

        // Set up validators
        if let customValidation = self.configuration.validation {
            dataRequest = dataRequest.validate(customValidation)
        }
        dataRequest = dataRequest.validate(GrapheneStatusValidator.validateStatus(request:response:data:)).validate()
        return dataRequest
    }

}
