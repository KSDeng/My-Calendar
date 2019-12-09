//
//  Notification.swift
//  MyCalendar
//
//  Created by DKS_mac on 2019/12/9.
//  Copyright © 2019 dks. All rights reserved.
//

// References:
// 1. https://learnappmaking.com/local-notifications-scheduling-swift/
// 2. https://developer.apple.com/documentation/usernotifications/unusernotificationcenter/1649517-removependingnotificationrequest

import Foundation
import UserNotifications


class LocalNotificationManager {
    var notifications = [CachedNotification]()
    
    // check what local notifications have been scheduled
    func listScheduledNotifications(){
        print("Scheduled notifications list: ")
        UNUserNotificationCenter.current().getPendingNotificationRequests(completionHandler: {
            notifications in
            for notification in notifications {
                print(notification)
            }
        })
    }
    
    // asking permission to send local notifications
    private func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound], completionHandler: { granted, error in
            if granted == true && error == nil {
                self.scheduleNotifications()
            }else {
                
            }
        })
    }
    
    // schedule local notifications
    private func scheduleNotifications() {
        for noti in notifications {
            
            let content = UNMutableNotificationContent()
            content.title = noti.title
            content.body = noti.body
            content.sound = .default
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.year,.month,.day,.hour,.minute,.second], from: noti.datetime), repeats: false)
            let request = UNNotificationRequest(identifier: noti.id.uuidString, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request, withCompletionHandler: {error in
                guard error == nil else {return}
                print("Notification scheduled! --- ID = \(noti.id) TIME = \(Utils.getDateAsFormat(date: noti.datetime, format: "yyyy/MM/dd HH:mm:ss"))")
            })
        }
    }
    
    // checking local notifications permission status
    private func schedule(){
        UNUserNotificationCenter.current().getNotificationSettings(completionHandler: {settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                self.requestAuthorization()
            case .authorized:
                self.scheduleNotifications()
            default:
                break
            }
        })
    }
    
    // add notification according to date and time
    func addNotification(notification: CachedNotification){
        
        notifications.append(notification)
        self.schedule()
        listScheduledNotifications()
    }
    
    // delete notification according to id
    func deleteNotification(id: UUID){
        /*
        listScheduledNotifications()
        let index = notifications.firstIndex(where: {notification in notification.id == id})
        guard let index_n = index else {
            fatalError("Notification to be deleted does not exist!")
        }
        notifications.remove(at: index_n)
        */
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id.uuidString])
    }
    
}
