//
//  UploadAttachmentInput.swift
//  GrapheneTests
//
//  Created by Ilya Kharlamov on 03.02.2021.
//

import Foundation
@testable import Graphene

struct UploadAttachmentInput: Decodable, SchemaType, EncodableVariable {
        
    var files: [Upload] = []
    var entity: AttachEntity
    var entityId: String
    
    func encode(to encoder: VariableEncoder) {
        let container = encoder.container(keyedBy: CodingKeys.self)
        container.encode(self.files, forKey: .files)
        container.encode(self.entityId, forKey: .entityId)
        container.encode(self.entity, forKey: .entity)
    }
    
}
