//
//  JSONHandler.swift
//  NineGagTest
//
//  Created by Ben Fowler on 23/11/2016.
//  Copyright © 2016 BF. All rights reserved.
//

import Foundation
import UIKit
import CoreData

enum ParSONError : Error {
    case NoValueForKey(String)
    case IndexOutOfRange
    case TypeMismatch
    case InvalidString
}

protocol ParSONDeserializable {
    static func create(inContext context: NSManagedObjectContext) -> Self
    func deserialize(_ parSONObject: ParSON, context: NSManagedObjectContext, keyPath: String) throws
}

final class ParSON
{
    private var array: [Any]?
    private var dictionary: [String: Any]?
    
    init<T: Any>(collection: T) where T: Collection {
        
        self.array = nil
        self.dictionary = nil
        
        if let dictionary = collection as? [String: Any] {
            
            self.dictionary = dictionary
        }
        else if let array = collection as? [Any] {
            
            self.array = array
        }
    }
    
    func value<A: Any>( forKeyPath key: String) throws -> A {
        
        let valueAtPath = try? self.valueAtPath(key)
        
        if let value = valueAtPath as? A {
            return value
        }
        
        throw ParSONError.TypeMismatch
    }

    private func valueAtPath(_ keyPath: String) throws -> Any
    {
        let pathComponents = keyPath.components(separatedBy:".")
    
        var valueAtPath: Any?
        
        if let array = self.array {
            valueAtPath = array
        }
        
        if let dictionary = self.dictionary {
            valueAtPath = dictionary
        }
        
        var arrayOfIndices: [Int] = []
        
        for component in pathComponents {
            
            var charset = CharacterSet()
            charset.insert("[")
            charset.insert("]")
            let innerComponents = component.components(separatedBy: charset)
            
            if innerComponents.count > 1, innerComponents.count < 3 { throw ParSONError.InvalidString }
            
            let key = innerComponents.first
            
            if innerComponents.count > 1 {
                for innerComponent in innerComponents {
                    if let index = Int(innerComponent) {
                        arrayOfIndices.append(index)
                    }
                }
            }
        
            if let dict = valueAtPath as? [String:Any] {
                if let value = dict[key!] {
                    valueAtPath = value
                }
            }
            
            if let array = valueAtPath as? [Any] {
                
                if !arrayOfIndices.isEmpty {
                    
                    func nestedValue(inArray jsonArray: [Any], forIndices indices: inout [Int]) -> Any {
                        
                        var value = jsonArray[indices.removeFirst()]
                        
                        if let newArray = value as? [AnyObject],
                            !indices.isEmpty {
                            value = nestedValue(inArray: newArray, forIndices: &indices)
                        }
                        
                        return value
                    }
                    
                    valueAtPath = nestedValue(inArray: array, forIndices: &arrayOfIndices)
                }
                else {
                    valueAtPath = array
                }
            }
        }
        
        return valueAtPath!
    }
    
    
    
    func objectForKey(_ key: String) throws -> ParSON {
        
        var retVal: ParSON?
        
        if let dict: [String: AnyObject] = try? value(forKeyPath: key) {
            retVal = ParSON(collection: dict)
        }
        
        if let array: [AnyObject] = try? value(forKeyPath: key) {
            retVal = ParSON(collection: array)
        }
        
        return retVal!
    }
   
    func enumerateObjects(atKeyPath keypath: String, enumerationClosure: ( _ indexKey: String, _ element: AnyObject) -> Void)  {
        
        let value = try? self.valueAtPath(keypath)
        
        if let array = value as? [Any] {
            for(index, element) in array.enumerated() {
                enumerationClosure("\(index)", element as AnyObject)
            }
        }
        else if let dictionary = value as? [String: Any] {
            for(index, element) in dictionary {
                enumerationClosure(index, element as AnyObject)
            }
        }
    }
    
    func enumerateObjects(ofType type: ParSONDeserializable.Type, forKeyPath keyPath: String, context: NSManagedObjectContext = NSManagedObjectContext.init(concurrencyType: NSManagedObjectContextConcurrencyType.privateQueueConcurrencyType), enumerationsClosure: (_ element: ParSONDeserializable) -> Void) {
        
        for index in 0...self.countForRelationship(keyPath) - 1 {
            let deserialisedParSONObject = type.create(inContext: context)
            try? deserialisedParSONObject.deserialize(self, context: context, keyPath: "\(keyPath)[\(index)]")
            
            enumerationsClosure(deserialisedParSONObject)
        }
    }
    
    private func countForRelationship(_ key: String) -> Int {
        
        let valueAtPath = try? self.valueAtPath(key)
        
        if let value = valueAtPath as? Dictionary<String, Any> {
            return Int(value.count)
        }
        else if let value = valueAtPath as? Array<Any> {
            return Int(value.count)
        }
        
        return 0
    }
    
}
