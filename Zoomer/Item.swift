//
//  Item.swift
//  Zoomer
//
//  Created by Christopher Walsh on 2024-08-17.
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
