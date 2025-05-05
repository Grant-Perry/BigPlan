//   Item.swift
//   BigPlan
//
//   Created by: Gp. on 5/5/25 at 10:11 AM
//     Modified: 
//
//  Copyright © 2025 Delicious Studios, LLC. - Grant Perry
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
