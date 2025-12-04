//
//  Item.swift
//  suİzim
//
//  Created by Yusuf Serdaroğlu on 4.12.2025.
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
