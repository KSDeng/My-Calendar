//
//  common.swift
//  MyCalendar
//
//  Created by DKS_mac on 2019/11/29.
//  Copyright © 2019 dks. All rights reserved.
//

import Foundation


class Utils {
    public static func getDateAsFormat(date: Date, format: String) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = .autoupdatingCurrent
        formatter.dateFormat = format
        return formatter.string(from: date)
    }
}
