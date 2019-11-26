//
//  Event.swift
//  MyCalendar
//
//  Created by DKS_mac on 2019/11/25.
//  Copyright © 2019 dks. All rights reserved.
//

import Foundation

class Event {
    var title: String = ""
    var startTime = ""          // TODO: pick by date picker
    var endTime = ""            // TODO: pick by date picker
    var location: String?
    var invitations: [String]?
    var note: String = ""
    
    init(st: String, title: String) {
        self.startTime = st
        self.title = title
    }
    
    // TODO: data check and alert
    init(title: String, st: String, et: String, loc: String, invitations: [String]?, note: String) {
        self.title = title
        self.startTime = st
        self.endTime = et
        self.location = loc
        self.invitations = invitations
        self.note = note
    }
    
}
