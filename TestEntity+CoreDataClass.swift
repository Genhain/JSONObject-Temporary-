//
//  TestEntity+CoreDataClass.swift
//  JSONObject
//
//  Created by Ben Fowler on 4/12/2016.
//  Copyright © 2016 BF. All rights reserved.
//

import Foundation
import CoreData

public class TestEntity: NSManagedObject, JSONAble
{
    private(set) static var wasCreateCalled = false
    private(set) static var lastContextForCreate: NSManagedObjectContext?
    
    private(set) var wasFromJSONCalled = false
    private(set) var lastJsonObject: JSONObject?
    private(set) var lastContextForFromJSON: NSManagedObjectContext?
    private(set) var lastKeyPath: String?
    
    static func create(inContext context: NSManagedObjectContext) -> Self {
        self.wasCreateCalled = true
        self.lastContextForCreate = context
        return .init(entity: NSEntityDescription.entity(forEntityName: "TestEntity", in: context)!, insertInto: context)
    }
    
    func fromJSON(_ JSONObject: JSONObject, context: NSManagedObjectContext, keyPath: String) throws {
        self.wasFromJSONCalled = true
        self.lastJsonObject = JSONObject
        self.lastContextForFromJSON = context
        self.lastKeyPath = keyPath
    }
}
