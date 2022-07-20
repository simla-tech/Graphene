//
//  VariableEncoder.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 28.01.2021.
//

import Foundation
import Graphene
import Alamofire

public class GrapheneInspector {

    public let host: String
    public let port: Int?
    public let graphRef: String
    public let session: Alamofire.Session

    public init(host: String, port: Int? = nil, graphRef: String) {
        self.host = host
        self.port = port
        self.graphRef = graphRef
        self.session = Alamofire.Session(rootQueue: DispatchQueue(label: "com.graphene.GrapheneInspector"))
    }

    public func validate<O: GraphQLOperation>(_ operationType: O.Type, completion: @escaping (Result<Response, Error>) -> Void) {
        var urlComponents = URLComponents()
        urlComponents.scheme = "http"
        urlComponents.host = self.host
        urlComponents.port = self.port
        urlComponents.path = "/validate"
        urlComponents.queryItems = [URLQueryItem(name: "graphRef", value: self.graphRef)]
        do {
            try self.session.request(
                urlComponents.asURL(),
                method: .post,
                encoding: operationType.buildQuery(),
                headers: [HTTPHeader.contentType("text/plain")]
            ).responseDecodable(
                of: Response.self,
                completionHandler: { completion($0.result.mapError({ $0 })) }
            )
        } catch {
            completion(.failure(error))
        }
    }

}
