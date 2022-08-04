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

    public let url: Alamofire.URLConvertible
    public let graphRef: String
    public let session: Alamofire.Session

    public init(url: Alamofire.URLConvertible, graphRef: String) {
        self.url = url
        self.graphRef = graphRef
        self.session = Alamofire.Session(rootQueue: DispatchQueue(label: "com.graphene.GrapheneInspector"))
    }

    public func validate<O: GraphQLOperation>(_ operationType: O.Type, completion: @escaping (Result<Response, Error>) -> Void) {
        do {
            let url = try self.url.asURL()
            guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
                completion(.failure(AFError.invalidURL(url: self.url)))
                return
            }
            urlComponents.path = "/validate"
            urlComponents.queryItems = [URLQueryItem(name: "graphRef", value: self.graphRef)]
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
