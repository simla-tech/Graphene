//
//  RequestPerformer.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 28.01.2021.
//

import Foundation
import Alamofire

extension Client {

    @discardableResult
    public func execute<O: GraphQLOperation>(_ operation: O,
                                             queue: DispatchQueue = .main,
                                             completion: @escaping (ExecuteResponse<O.Result>) -> Void) -> OperationRequest {

        var httpHeaders = self.configuration.httpHeaders ?? []
        if !httpHeaders.contains(where: { $0.name.lowercased() == "user-agent" }),
           let version = Bundle(for: Session.self).infoDictionary?["CFBundleShortVersionString"] as? String {
            httpHeaders.add(name: "User-Agent", value: "Graphene /\(version)")
        }

        let operationContext = operation.prepareContext()
        let monitors = CompositeGrapheneEventMonitor(monitors: self.configuration.eventMonitors)

        var dataRequest = self.alamofireSession.upload(
            multipartFormData: operationContext.getMultipartFormData(),
            to: self.url,
            usingThreshold: MultipartFormData.encodingMemoryThreshold,
            method: .post,
            headers: httpHeaders,
            requestModifier: self.configuration.requestModifier
        )

        // Set up validators
        if let customValidation = self.configuration.validation {
            dataRequest = dataRequest.validate(customValidation)
        }
        dataRequest = dataRequest.validate(GrapheneStatusValidator.validateStatus(request:response:data:)).validate()

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = self.configuration.keyDecodingStrategy
        decoder.dateDecodingStrategy = self.configuration.dateDecodingStrategy
        dataRequest.responseDecodable(of: OperationRawResponse<O.RootSchema>.self,
                                      queue: .global(qos: .utility),
                                      decoder: decoder) { [weak monitors] dataResponse in

            if self.configuration.muteCanceledRequests, dataResponse.error?.isExplicitlyCancelledError ?? false {
                return
            }

            monitors?.operation(operationContext,
                                didFinishWith: dataResponse.response?.statusCode ?? -999,
                                interval: dataResponse.metrics?.taskInterval ?? .init())

            var firstResponse: ExecuteResponse<O.RootSchema>
            var graphQlErrors: [GraphQLError]?
            do {
                let alamofireResult = try dataResponse.result.get()
                graphQlErrors = alamofireResult.errors?.isEmpty ?? true ? nil : alamofireResult.errors
                guard let data = alamofireResult.data else {
                    if let graphqlErrors = alamofireResult.errors, graphqlErrors.count > 1 {
                        throw GraphQLErrors(graphqlErrors)
                    }
                    throw alamofireResult.errors?.first ?? GrapheneError.invalidResponse
                }
                let prepRes = Result<O.RootSchema>(value: data, errors: alamofireResult.errors)
                firstResponse = .success(prepRes)
            } catch {
                firstResponse = .failure(error.asAFError?.underlyingError ?? error)
            }

            var secondResponse: ExecuteResponse<O.Result>
            do {
                let newValue = try operation.handleResponse(firstResponse)
                let prepRes = Result<O.Result>(value: newValue, errors: graphQlErrors)
                secondResponse = .success(prepRes)
            } catch {
                monitors?.operation(operationContext, didFailWith: error)
                secondResponse = .failure(error)
            }

            queue.async {
                if !self.configuration.muteCanceledRequests || !dataRequest.isCancelled {
                    completion(secondResponse)
                }
            }

        }
        let request = OperationRequest(context: operationContext, dataRequest: dataRequest)
        monitors.client(self, willExecute: request)
        dataRequest.resume()
        return request
    }

}

private struct OperationRawResponse<Root: Decodable>: Decodable {
    let data: Root?
    let errors: [GraphQLError]?
}
