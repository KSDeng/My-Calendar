//
//  Task+CoreDataProperties.swift
//  MyCalendar
//
//  Created by DKS_mac on 2019/12/9.
//  Copyright © 2019 dks. All rights reserved.
//
//

import Foundation
import CoreData


extension Task {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Task> {
        return NSFetchRequest<Task>(entityName: "Task")
    }

    @NSManaged public var arrayIndex: Int32
    @NSManaged public var colorPoint: Int16
    @NSManaged public var dateIndex: String?
    @NSManaged public var endDate: Date?
    @NSManaged public var endTime: Date?
    @NSManaged public var ifAllDay: Bool
    @NSManaged public var locAddrDetail: String?
    @NSManaged public var locLatitude: Double
    @NSManaged public var locLongitude: Double
    @NSManaged public var locTitle: String?
    @NSManaged public var nDays: Int16
    @NSManaged public var note: String?
    @NSManaged public var startDate: Date?
    @NSManaged public var startTime: Date?
    @NSManaged public var title: String?
    @NSManaged public var type: String?
    @NSManaged public var invitations: NSSet?
    @NSManaged public var notification: Notification?

}

// MARK: Generated accessors for invitations
extension Task {

    @objc(addInvitationsObject:)
    @NSManaged public func addToInvitations(_ value: Invitation)

    @objc(removeInvitationsObject:)
    @NSManaged public func removeFromInvitations(_ value: Invitation)

    @objc(addInvitations:)
    @NSManaged public func addToInvitations(_ values: NSSet)

    @objc(removeInvitations:)
    @NSManaged public func removeFromInvitations(_ values: NSSet)

}
