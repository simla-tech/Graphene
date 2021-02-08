//
//  User.swift
//  GrapheneTests
//
//  Created by Ilya Kharlamov on 01.02.2021.
//

import Foundation
@testable import Graphene

public struct User: Codable, Identifiable {
    public var id: ID
    public var nickName: String?
    public var enabled: Bool?
    public var position: String?
    public var createdAt: Date?
    public var externalId: String?
    public var phone: String?
    public var phoneCanonical: String?
    public var phoneTfa: String?
    public var supportAccount: Bool?
    public var posManager: Bool?
    public var lastLogin: Date?
    public var photoUrl: String?
    public var isMe: Bool?
    public var isAdmin: Bool?
}

extension User: Queryable {

    public class QueryKeys: QueryKey {
        static let id               = QueryKeys(CodingKeys.id)
        static let nickName         = QueryKeys(CodingKeys.nickName)
        static let enabled          = QueryKeys(CodingKeys.enabled)
        static let position         = QueryKeys(CodingKeys.position)
        static let createdAt        = QueryKeys(CodingKeys.createdAt)
        static let externalId       = QueryKeys(CodingKeys.externalId)
        static let phone            = QueryKeys(CodingKeys.phone)
        static let phoneCanonical   = QueryKeys(CodingKeys.phoneCanonical)
        static let phoneTfa         = QueryKeys(CodingKeys.phoneTfa)
        static let supportAccount   = QueryKeys(CodingKeys.supportAccount)
        static let posManager       = QueryKeys(CodingKeys.posManager)
        static let lastLogin        = QueryKeys(CodingKeys.lastLogin)
        static let photoUrl         = QueryKeys(CodingKeys.photoUrl)
        static let isMe             = QueryKeys(CodingKeys.isMe)
        static let isAdmin          = QueryKeys(CodingKeys.isAdmin)
    }
    
}
