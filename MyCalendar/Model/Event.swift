//
//  Event.swift
//  MyCalendar
//
//  Created by DKS_mac on 2019/11/25.
//  Copyright © 2019 dks. All rights reserved.
//

import UIKit
import Foundation

// 事件种类
// 任务、节假日、节假日调休
enum EventType {
    case Task, Holiday, Adjust
}

struct Event {
    var type = EventType.Task
    var title = ""
    var startTime = Date()
    var endTime = Date()
    var location = ""
    var invitations: [String]?
    var note: String?
    var colorPoint = 0
}
