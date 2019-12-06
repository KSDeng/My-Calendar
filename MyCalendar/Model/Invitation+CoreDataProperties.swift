//
//  Invitation+CoreDataProperties.swift
//  MyCalendar
//
//  Created by DKS_mac on 2019/12/6.
//  Copyright © 2019 dks. All rights reserved.
//
//

import Foundation
import CoreData


extension Invitation {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Invitation> {
        return NSFetchRequest<Invitation>(entityName: "Invitation")
    }

    @NSManaged public var name: String?
    @NSManaged public var phoneNumber: String?
    @NSManaged public var time: Date?
    @NSManaged public var belongedTo: Task?

}
