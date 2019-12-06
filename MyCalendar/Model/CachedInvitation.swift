//
//  CachedInvitation.swift
//  MyCalendar
//
//  Created by DKS_mac on 2019/12/6.
//  Copyright © 2019 dks. All rights reserved.
//

import Foundation

class CachedInvitation {
    var name: String?
    var phoneNumber: String
    var lastEditTime: Date
    init(phoneNumber: String, editTime: Date) {
        self.phoneNumber = phoneNumber
        self.lastEditTime = editTime
    }
}
