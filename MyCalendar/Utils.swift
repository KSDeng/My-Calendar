//
//  Utils.swift
//  MyCalendar
//
//  Created by DKS_mac on 2019/11/30.
//  Copyright © 2019 dks. All rights reserved.
//
import UIKit
import Foundation

class Utils {
    public static func getDateAsFormat(date: Date, format: String) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = .autoupdatingCurrent
        formatter.dateFormat = format
        return formatter.string(from: date)
    }
    
    // 节假日颜色
    public static let holidayColor = UIColor(red:0.09, green:0.63, blue:0.52, alpha:1.0)           // 绿
    
    // 调休日颜色
    public static let adjustDayColor = UIColor(red:0.95, green:0.15, blue:0.07, alpha:1.0)        // 红
    // 自定义事件卡片颜色
    public static let eventColorArray = [
        UIColor(red:0.22, green:0.67, blue:0.98, alpha:1.0),            // 蓝
        UIColor(red:0.90, green:0.39, blue:0.39, alpha:1.0),            // 红
        UIColor(red:0.88, green:0.50, blue:0.95, alpha:1.0),            // 紫罗兰
        UIColor(red:0.39, green:0.90, blue:0.90, alpha:1.0)             // 靓
    ]
    
    // 事件卡片颜色指针
    public static var currentColorPoint = 0
    

    // CoreData上下文
    public static let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
}



