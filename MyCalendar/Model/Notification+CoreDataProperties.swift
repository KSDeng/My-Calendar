//
//  Notification+CoreDataProperties.swift
//  MyCalendar
//
//  Created by DKS_mac on 2019/12/9.
//  Copyright © 2019 dks. All rights reserved.
//
//

import Foundation
import CoreData


extension Notification {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Notification> {
        return NSFetchRequest<Notification>(entityName: "Notification")
    }

    @NSManaged public var body: String?
    @NSManaged public var datetime: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var range: String?
    @NSManaged public var number: Int16
    @NSManaged public var task: Task?

}
