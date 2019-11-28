//
//  Event.swift
//  MyCalendar
//
//  Created by DKS_mac on 2019/11/25.
//  Copyright © 2019 dks. All rights reserved.
//

import UIKit
import Foundation

struct Event {
    var title = ""
    var startTime = Date()
    var endTime = Date()
    var location = ""
    var invitations: [String]?
    var note: String?
    var color: UIColor?         // Color to show
}
