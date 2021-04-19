//
//  Call.swift
//  VidyoConnector
//

import Foundation

class Call {
    
    let uuid: UUID
    let isOutgoing: Bool
    var handle: String?
    
    init(uuid: UUID, isOutgoing: Bool = false) {
        self.uuid = uuid
        self.isOutgoing = isOutgoing
    }
}
