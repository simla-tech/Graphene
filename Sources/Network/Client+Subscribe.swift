//
//  Client+Subscribe.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 21.09.2021.
//  Copyright © 2021 RetailDriver LLC. All rights reserved.
//

import Foundation
import Alamofire

public extension Client {
    
    func subscribe<O: GraphQLOperation>(to operation: O) -> WebSocketRequest {
        if O.RootSchema.mode != .subscription {
            assertionFailure("You can't subsribe to \"\(O.operationName)\" operation. \"\(String(describing: O.RootSchema.self))\" must have .subscription mode")
        }
        let asdsd = URLRequest(url: URL.init(string: "")!)
        return self.alamofireSession.websocketRequest(asdsd, protocol: "graphql-ws")
    }
    
}
