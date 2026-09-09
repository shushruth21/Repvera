//
//  Item.swift
//  Workout Partner
//
//  Created by Shushruth Bharadwaj on 09/09/26.
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
