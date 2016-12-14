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

public enum ParSONError : Error {
    case NoValueForKey(String)
    case IndexOutOfRange
    case TypeMismatch
    case InvalidString
}

extension ParSONError: Equatable {
    
}

public func ==(lhs: ParSONError, rhs: ParSONError) -> Bool {
    
    if lhs._code == rhs._code {
        return true
    }
    
    return false
}

public protocol ParSONDeserializable {
    static func create(inContext context: NSManagedObjectContext) -> Self
    func deserialize(_ parSONObject: ParSON, context: NSManagedObjectContext, keyPath: String) throws
}

public final class ParSON
{
    private var array: [Any]?
    private var dictionary: [String: Any]?
    
    public init<T: Any>(collection: T) where T: Collection {
        
        self.array = nil
        self.dictionary = nil
        
        if let dictionary = collection as? [String: Any] {
            
            self.dictionary = dictionary
        }
        else if let array = collection as? [Any] {
            
            self.array = array
        }
    }
    
    public func value<A: Any>( forKeyPath key: String) throws -> A {
        
        let valueAtPath = try self.valueAtPath(key)
        
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
            
            let leftBrackets = component.matchingStrings(regex: "\\[")
            let rightBrackets = component.matchingStrings(regex: "\\]")
            
            if leftBrackets.count != rightBrackets.count {
                throw ParSONError.InvalidString
            }
            
            if leftBrackets.count > 0,
                rightBrackets.count > 0 {
                
                let bracketedIndexValues = component.matchingStrings(regex: "\\[(.*?)\\]")
                
                if bracketedIndexValues.count != leftBrackets.count {
                    throw ParSONError.InvalidString
                }
                
                for item in bracketedIndexValues {
                    if item.last!.isEmpty {
                        throw ParSONError.InvalidString
                    }
                }
            }
            
            var componentsSeperatedByCharacterSet = component.components(separatedBy: charset)
            componentsSeperatedByCharacterSet.removeObject(object: "")
            
            var hasAssignedValue = keyPath == "" ? true:false
            
            if let dict = valueAtPath as? [String:Any] {
                
                var key: String = ""
                
                if !componentsSeperatedByCharacterSet.isEmpty {
                    key = componentsSeperatedByCharacterSet.removeFirst()
                }
                
                if let value = dict[key] {
                    hasAssignedValue = true
                    valueAtPath = value
                }
                else if key != "" {
                    throw ParSONError.NoValueForKey(key)
                }
            }
            
            for innerComponent in componentsSeperatedByCharacterSet {
                if let index = Int(innerComponent) {
                    arrayOfIndices.append(index)
                }
            }
            
            if let array = valueAtPath as? [Any] {
                
                if !arrayOfIndices.isEmpty {
                    
                    func nestedValue(inArray jsonArray: [Any], forIndices indices: inout [Int])throws -> Any {
                        
                        guard jsonArray.count > indices.first! else { throw ParSONError.IndexOutOfRange }
                        
                        var value = jsonArray[indices.removeFirst()]
                        
                        if let newArray = value as? [AnyObject],
                            !indices.isEmpty {
                            value = try nestedValue(inArray: newArray, forIndices: &indices)
                        }
                        
                        return value
                    }
                    
                    valueAtPath = try nestedValue(inArray: array, forIndices: &arrayOfIndices)
                }
                else {
                    valueAtPath = array
                }
                
                hasAssignedValue = true
            }
            
            if !hasAssignedValue {
                throw ParSONError.NoValueForKey(component)
            }
        }
        
        return valueAtPath!
    }
    
    
    
    public func objectForKey(_ key: String) throws -> ParSON {
        
        var retVal: ParSON?
        
        if let dict: [String: AnyObject] = try? value(forKeyPath: key) {
            retVal = ParSON(collection: dict)
        }
        
        if let array: [AnyObject] = try? value(forKeyPath: key) {
            retVal = ParSON(collection: array)
        }
        
        return retVal!
    }
   
    public func enumerateObjects(atKeyPath keypath: String = "", enumerationClosure: ( _ indexKey: String, _ element: AnyObject) -> Void)throws  {
        
        let value = try self.valueAtPath(keypath)
        
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
    
    public func enumerateObjects(ofType type: ParSONDeserializable.Type, forKeyPath keyPath: String, context: NSManagedObjectContext = NSManagedObjectContext.init(concurrencyType: NSManagedObjectContextConcurrencyType.privateQueueConcurrencyType), enumerationsClosure: (_ element: ParSONDeserializable) -> Void) {
        
        let relationShipCount = countForRelationship(keyPath)
        
        guard relationShipCount > 0 else {
            return
        }
        
        for index in 0...relationShipCount - 1 {
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

extension String {
    func matchingStrings(regex: String) -> [[String]] {
        guard let regex = try? NSRegularExpression(pattern: regex, options: []) else { return [] }
        let nsString = self as NSString
        let results  = regex.matches(in: self, options: [], range: NSMakeRange(0, nsString.length))
        return results.map { result in
            (0..<result.numberOfRanges).map { result.rangeAt($0).location != NSNotFound
                ? nsString.substring(with: result.rangeAt($0))
                : ""
            }
        }
    }
}

extension Array where Element: Equatable
{
    mutating func removeObject(object: Element) {
        
        while self.contains(object) {
            if let index = index(of: object) {
                remove(at: index)
            }
        }
    }
}
