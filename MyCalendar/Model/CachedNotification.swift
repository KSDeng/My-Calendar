//
//  CachedNotification.swift
//  MyCalendar
//
//  Created by DKS_mac on 2019/12/9.
//  Copyright © 2019 dks. All rights reserved.
//

import Foundation

class CachedNotification {
    var id: UUID
    var title: String
    var body: String
    var datetime: Date
    var range: String
    var number: Int
    init(id: UUID, title: String, body: String, datetime: Date, range: String, number: Int) {
        self.id = id
        self.title = title
        self.body = body
        self.datetime = datetime
        self.range = range
        self.number = number
    }
}
