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
    
    // weekday与中文描述对应的map
    // https://stackoverflow.com/questions/27990503/nsdatecomponents-returns-wrong-weekday
    public static let weekDayMap = [ 1:"星期天", 2:"星期一", 3:"星期二", 4:"星期三", 5:"星期四", 6:"星期五", 7:"星期六" ]
    
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

// 事件种类
// 任务、节假日、节假日调休
// Implicit raw value
// String类型的raw value将默认与case同名
enum EventType: String {
    case Task
    case Holiday
    case Adjust
}

// 任务处理界面当前状态(增加、编辑、展示、默认)
enum Status: String {
    case Add, Edit, Show, Default
}
