//
//  Item.swift
//  Loca_Mac
//
//  Created by mihir maru on 09/08/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
