//
//  CloseCode+Description.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 07.10.2021.
//  Copyright © 2021 RetailDriver LLC. All rights reserved.
//

import Foundation

public extension URLSessionWebSocketTask.CloseCode {
    
    var stringValue: String {
        switch self {
        case .invalid:
            return "invalid"
        case .normalClosure:
            return "normalClosure"
        case .goingAway:
            return "goingAway"
        case .protocolError:
            return "protocolError"
        case .unsupportedData:
            return "unsupportedData"
        case .noStatusReceived:
            return "noStatusReceived"
        case .abnormalClosure:
            return "abnormalClosure"
        case .invalidFramePayloadData:
            return "invalidFramePayloadData"
        case .policyViolation:
            return "policyViolation"
        case .messageTooBig:
            return "messageTooBig"
        case .mandatoryExtensionMissing:
            return "mandatoryExtensionMissing"
        case .internalServerError:
            return "internalServerError"
        case .tlsHandshakeFailure:
            return "tlsHandshakeFailure"
        @unknown default:
            return "@unknown"
        }
    }
    
}
