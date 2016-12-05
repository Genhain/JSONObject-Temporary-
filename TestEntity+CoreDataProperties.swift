//
//  TestEntity+CoreDataProperties.swift
//  JSONObject
//
//  Created by Ben Fowler on 4/12/2016.
//  Copyright © 2016 BF. All rights reserved.
//

import Foundation
import CoreData


extension TestEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TestEntity> {
        return NSFetchRequest<TestEntity>(entityName: "TestEntity");
    }


}
