//
//  Content.swift
//  RedactKit
//
//  Created by Supachod Trakansirorut on 30/8/25.
//

import SwiftData
import Foundation

@Model
class Content {
    var timestamp: Date
    var data: String
    var id: UUID
    
    init(data: String, timestamp: Date = Date()) {
        self.data = data
        self.timestamp = timestamp
        self.id = UUID()
    }
}
