//
//  JCMessage+CoreDataProperties.swift
//  Joyspace Challenge
//
//  Created by Lyndsey Scott on 1/28/16.
//  Copyright © 2016 StandableInc. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension JCMessage {

    @NSManaged var image: NSData?
    @NSManaged var text: String?
    @NSManaged var timestamp: NSDate?
    @NSManaged var isSender: NSNumber?
    @NSManaged var thread: JCThread?

}
