
import XCTest
import CoreData
@testable import JSONObject

func setUpInMemoryPersistentContainer() -> NSPersistentContainer {
    let managedObjectModel = NSManagedObjectModel.mergedModel(from: [Bundle.main])!
    let persistentContainer =  NSPersistentContainer(name: "inMemoryPersistentContainer", managedObjectModel: managedObjectModel)
    
    do {
        try persistentContainer.persistentStoreCoordinator.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)
    } catch {
        print("Adding in-memory persistent store failed")
    }
    
    return persistentContainer
}

fileprivate class JSONableTestable: JSONAble
{
    private(set) var titleText: String?
    fileprivate(set) var id: String?
    
    static func create(inContext context: NSManagedObjectContext) -> Self {
        return .init()
    }
    
    func fromJSON(_ JSONObject: JSONObject, context: NSManagedObjectContext, keyPath: String) throws {
        
        self.id = try JSONObject.valueForKey("\(keyPath).id")
        self.titleText = try JSONObject.valueForKey("\(keyPath).titleText")
    }
}

class JSONObjectTests: XCTestCase {
    
    var inMemoryPersistentContainer: NSPersistentContainer!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        inMemoryPersistentContainer = setUpInMemoryPersistentContainer()
    }
    
    override func tearDown() {
        inMemoryPersistentContainer = nil
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testJSONValue_array1CountIntoDictionary_ShouldEqualData()
    {
        // Arrange
        let data =
            [
                ["id": "1",
                 "posts":[
                    ["titleText": "test1",
                     "id": "1"],
                    ["titleText": "test2",
                     "id": "2"]]]
        ]
        
        class JSONableTestableWithPosts: JSONableTestable
        {
            private(set) var posts: [[String: AnyObject]]?
            
            override func fromJSON(_ JSONObject: JSONObject, context: NSManagedObjectContext, keyPath: String = "[0]") throws {
                self.id = try JSONObject.valueForKey("\(keyPath).id")
                self.posts = try JSONObject.valueForKey("\(keyPath).posts")
            }
        }
        
        // Act
        let spy = JSONableTestableWithPosts()
        
        let jsonObj = JSONObject(collection: data)
        
        try? spy.fromJSON(jsonObj, context: inMemoryPersistentContainer.viewContext)
        
        // Assert
        XCTAssertEqual(spy.id, "1")
        XCTAssertEqual(spy.posts?[0]["titleText"] as! String, "test1")
        XCTAssertEqual(spy.posts?[0]["id"] as! String, "1")
        XCTAssertEqual(spy.posts?[1]["titleText"] as! String, "test2")
        XCTAssertEqual(spy.posts?[1]["id"] as! String, "2")
    }
    
    func testJSONValue_array2CountIntoDictionary_ShouldEqualData()
    {
        // Arrange
        let data =
            [
                ["id": "1",
                 "posts":[
                    ["titleText": "test1",
                     "id": "1"],
                    ["titleText": "test2",
                     "id": "2"]]],
                ["id": "2",
                 "posts":[
                    ["titleText": "test3",
                     "id": "3"],
                    ["titleText": "test4",
                     "id": "4"]]]
        ]
        
        class JSONAbleTester: JSONAble
        {
            private(set) var id: String?
            private(set) var posts: [[String: AnyObject]]?
            
            fileprivate static func create(inContext context: NSManagedObjectContext) -> Self {
                return .init()
            }
            
            func fromJSON(_ JSONObject: JSONObject, context: NSManagedObjectContext, keyPath: String = "") throws {
                self.id = try JSONObject.valueForKey("\(keyPath).id")
                self.posts = try JSONObject.valueForKey("\(keyPath).posts")
            }
        }
        
        // Act
        let spy = JSONAbleTester()
        
        let jsonObj = JSONObject(collection: data)
        
        try? spy.fromJSON(jsonObj, context: inMemoryPersistentContainer.viewContext, keyPath: "[0]")
        
        // Assert
        XCTAssertEqual(spy.id, "1")
        XCTAssertEqual(spy.posts?[0]["titleText"] as! String, "test1")
        XCTAssertEqual(spy.posts?[0]["id"] as! String, "1")
        XCTAssertEqual(spy.posts?[1]["titleText"] as! String, "test2")
        XCTAssertEqual(spy.posts?[1]["id"] as! String, "2")
        
        try? spy.fromJSON(jsonObj, context: inMemoryPersistentContainer.viewContext, keyPath: "[1]")
        
        XCTAssertEqual(spy.id, "2")
        XCTAssertEqual(spy.posts?[0]["titleText"] as! String, "test3")
        XCTAssertEqual(spy.posts?[0]["id"] as! String, "3")
        XCTAssertEqual(spy.posts?[1]["titleText"] as! String, "test4")
        XCTAssertEqual(spy.posts?[1]["id"] as! String, "4")
    }
    
    func testEnumerateObjects_array5Count_ShouldEqualData()
    {
        // Arrange
        let data =
        [
            "1",
            "2",
            "3",
            "4",
            "5"
        ]
        
        // Act
        let SUT = JSONObject(collection: data)
        
        // Assert
        var index = 0
        SUT.enumerateObjects(atKeyPath: "") { (keyIndex, element) in
            XCTAssertEqual(Int(keyIndex)!, index)
            XCTAssertEqual(data[index], String(describing: element))
            index += 1
        }
        
        XCTAssertEqual(5, index)
    }
    
    func testEnumerateObjects_array8Count_ShouldEqualData()
    {
        // Arrange
        let data =
            [
                "1",
                "2",
                "3",
                "4",
                "5",
                "6",
                "7",
                "8"
        ]
        
        // Act
        let SUT = JSONObject(collection: data)
        
        // Assert
        var index = 0
        SUT.enumerateObjects(atKeyPath: "") { (keyIndex, element) in
            XCTAssertEqual(Int(keyIndex)!, index)
            XCTAssertEqual(data[index], String(describing: element))
            index += 1
        }
        
        XCTAssertEqual(8, index)
    }
    
    func testEnumerateObjects_array3Dictionaries_ShouldEqualData()
    {
        // Arrange
        let data =
        [
            ["value": "1"],
            ["value": "2"],
            ["value": "3"]
        ]
        
        // Act
        let SUT = JSONObject(collection: data)
        
        // Assert
        var index = 0
        SUT.enumerateObjects(atKeyPath: "") { (keyIndex, element) in
            XCTAssertEqual("\(index)", keyIndex)
            
            XCTAssertEqual(data[index], element as! [String : String])
            index += 1
        }
        
        XCTAssertEqual(3, index)
    }
    
    func testEnumerateObjects_dictionary3Count_ShouldEqualData()
    {
        // Arrange
        let data =
        [
            "1": "1",
            "2": "2",
            "3": "3"
        ]
        
        // Act
        let SUT = JSONObject(collection: data)
        
        // Assert
        var index = 0
        SUT.enumerateObjects(atKeyPath: "") { (keyIndex, element) in
            XCTAssertEqual(data[keyIndex], String(describing: element) )
            index += 1
        }
        
        XCTAssertEqual(3, index)
    }
    
    func testEnumerateObjects_arrayInDictionary3CountIntoDictionary_ShouldEqualData()
    {
        // Arrange
        let data =
        [
            "one": ["1","2","3"]
        ]
        
        // Act
        let SUT = JSONObject(collection: data)
        
        // Assert
        var index = 0
        SUT.enumerateObjects(atKeyPath: "one") { (keyIndex, element) in
            XCTAssertEqual(data["one"]?[index], String(describing: element) )
            index += 1
        }
        
        XCTAssertEqual(3, index)
    }
    
    func testEnumerateObjects_array4CountInDictionary_ShouldEqualData()
    {
        // Arrange
        let data =
        [
            "two": ["3", "4", "5", "6"]
        ]
        
        // Act
        let SUT = JSONObject(collection: data)
        
        // Assert
        var index = 0
        SUT.enumerateObjects(atKeyPath: "two") { (keyIndex, element) in
            XCTAssertEqual(data["two"]?[index], String(describing: element) )
            index += 1
        }
        
        XCTAssertEqual(4, index)
    }

    func testEnumerateObjects_nestedExample_ShouldEqualData()
    {
        // Arrange
        let data =
        [
            "a": ["one", "two", "three"],
            "two": [4, 5, 6, 7],
            "tres": ["three": ["8": 8, "9": 9]]
        ] as [String : Any]
        
        
        let SUT = JSONObject(collection: data)
        
        
        // Act
        var index = 0
        SUT.enumerateObjects(atKeyPath: "a") { (keyIndex, element) in
            let array = data["a"] as? [String]
            // Assert
            XCTAssertEqual(array?[index], String(describing: element) )
            index += 1
        }
        
        XCTAssertEqual(3, index)
        
        index = 0
        SUT.enumerateObjects(atKeyPath: "two") { (keyIndex, element) in
            let array = data["two"] as? [Int]
            // Assert
            XCTAssertEqual(array?[index], element as? Int)
            index += 1
        }
        
        XCTAssertEqual(4, index)
        
        index = 0
        SUT.enumerateObjects(atKeyPath: "tres.three") { (keyIndex, element) in
            guard let dict = data["tres"] as? [String: Any] else { XCTFail(); return }
            guard let innerDict = dict["three"] as? [String: Int] else { XCTFail(); return }
            // Assert
            XCTAssertEqual(innerDict[keyIndex], element as? Int)
            index += 1
        }
        
        XCTAssertEqual(2, index)
    }
    
    func testValueForKey_getFirstPostOfcategoryTitle_isEqualToData()
    {
        // Arrange
        let data =
        [
            "category":
                ["id": "1",
                 "posts":[
                    ["titleText": "test1",
                     "id": "1"]]]
        ]

        let SUT = JSONObject(collection: data)

        // Act
        let title: String = try! SUT.valueForKey("category.posts[0].titleText")
        let id: String = try! SUT.valueForKey("category.posts[0].id")
        
        XCTAssertNotNil(title)
        XCTAssertEqual("test1", title)
        XCTAssertEqual("1", id)
    }
    
    func testValueForKey_getSecondPostOfcategoryTitle_isEqualToData()
    {
        // Arrange
        let data =
            [
                "category":
                    ["id": "1",
                     "posts":[
                        ["titleText": "test3",
                         "id": "3"],
                        ["titleText": "test4",
                         "id": "4"]]]
        ]
        
        let SUT = JSONObject(collection: data)
        
        // Act
        var title: String = try! SUT.valueForKey("category.posts[0].titleText")
        var id: String = try! SUT.valueForKey("category.posts[0].id")
        
        XCTAssertNotNil(title)
        XCTAssertEqual("test3", title)
        XCTAssertEqual("3", id)
        
        title = try! SUT.valueForKey("category.posts[1].titleText")
        id = try! SUT.valueForKey("category.posts[1].id")
        
        XCTAssertNotNil(title)
        XCTAssertEqual("test4", title)
        XCTAssertEqual("4", id)
    }
    
    func testValueForKey_getNestedArrayValues_isEqualToData()
    {
        // Arrange
        let data =
        [
            "category":
                ["id": "1",
                 "posts":
                  [["t","e","s","t","1"]]
                ]
        ]
        
        let SUT = JSONObject(collection: data)
        
        // Act
        var testString: String = try! SUT.valueForKey("category.posts[0][0]")
        testString.append(try! SUT.valueForKey("category.posts[0][1]") as String)
        testString.append(try! SUT.valueForKey("category.posts[0][2]") as String)
        testString.append(try! SUT.valueForKey("category.posts[0][3]") as String)
        testString.append(try! SUT.valueForKey("category.posts[0][4]") as String)
        
        XCTAssertEqual("test1", testString)
    }
    
    func testValueForKey_get2NestedArrayValues_isEqualToData()
    {
        // Arrange
        let data =
            [
                "category":
                    ["id": "1",
                     "posts":
                        [["t","e","s","t","1"],
                        ["v","a","l","u","e"]]
                ]
        ]
        
        let SUT = JSONObject(collection: data)
        
        // Act
        var testString: String = try! SUT.valueForKey("category.posts[0][0]")
        testString.append(try! SUT.valueForKey("category.posts[0][1]") as String)
        testString.append(try! SUT.valueForKey("category.posts[0][2]") as String)
        testString.append(try! SUT.valueForKey("category.posts[0][3]") as String)
        testString.append(try! SUT.valueForKey("category.posts[0][4]") as String)
        
        XCTAssertEqual("test1", testString)
        
        testString = try! SUT.valueForKey("category.posts[1][0]")
        testString.append(try! SUT.valueForKey("category.posts[1][1]") as String)
        testString.append(try! SUT.valueForKey("category.posts[1][2]") as String)
        testString.append(try! SUT.valueForKey("category.posts[1][3]") as String)
        testString.append(try! SUT.valueForKey("category.posts[1][4]") as String)
        
        XCTAssertEqual("value", testString)
    }
    
    func testValueForKey_get3Values2Arrays1DictionaryWithArrays_isEqualToData()
    {
        // Arrange
        let data =
            [
                "category":
                    ["id": "1",
                     "posts":
                        [
                            ["t","e","s","t","1"],
                            ["v","a","l","u","e"],
                            ["id":[["k","y","l","e"],["c","r","a","n","e"]]]
                        ]
                ]
        ]
        
        let SUT = JSONObject(collection: data)
        
        // Act
        var testString: String = try! SUT.valueForKey("category.posts[0][0]")
        testString.append(try! SUT.valueForKey("category.posts[0][1]") as String)
        testString.append(try! SUT.valueForKey("category.posts[0][2]") as String)
        testString.append(try! SUT.valueForKey("category.posts[0][3]") as String)
        testString.append(try! SUT.valueForKey("category.posts[0][4]") as String)
        
        XCTAssertEqual("test1", testString)
        
        testString = try! SUT.valueForKey("category.posts[1][0]")
        testString.append(try! SUT.valueForKey("category.posts[1][1]") as String)
        testString.append(try! SUT.valueForKey("category.posts[1][2]") as String)
        testString.append(try! SUT.valueForKey("category.posts[1][3]") as String)
        testString.append(try! SUT.valueForKey("category.posts[1][4]") as String)
        
        XCTAssertEqual("value", testString)
        
        testString = try! SUT.valueForKey("category.posts[2].id[0][0]")
        testString.append(try! SUT.valueForKey("category.posts[2].id[0][1]") as String)
        testString.append(try! SUT.valueForKey("category.posts[2].id[0][2]") as String)
        testString.append(try! SUT.valueForKey("category.posts[2].id[0][3]") as String)
        testString.append(" ")
        testString.append(try! SUT.valueForKey("category.posts[2].id[1][0]") as String)
        testString.append(try! SUT.valueForKey("category.posts[2].id[1][1]") as String)
        testString.append(try! SUT.valueForKey("category.posts[2].id[1][2]") as String)
        testString.append(try! SUT.valueForKey("category.posts[2].id[1][3]") as String)
        testString.append(try! SUT.valueForKey("category.posts[2].id[1][4]") as String)
        
        XCTAssertEqual("kyle crane", testString)
    }

    func testEnumerateJSONConvertible_5ItemsSpy_CallsFunctionsAndSetsVariables()
    {
        // Arrange
        let data =
            [
                "category":
                    [
                        "jsonable":
                            [
                                ["titleText": "test1",
                                 "id": "1"],
                                ["titleText": "test2",
                                 "id": "2"],
                                ["titleText": "test3",
                                 "id": "3"],
                                ["titleText": "test4",
                                 "id": "4"],
                                ["titleText": "test5",
                                 "id": "5"]
                        ]
                ]
        ]
        
        let SUT = JSONObject(collection: data)
        
        // Act
        var count = 0
        SUT.enumerateObjects(ofType: TestEntity.self, forKeyPath: "category.jsonable", context: inMemoryPersistentContainer.viewContext) { (jsonablePost) in
            
            count += 1
            guard let deserialised = jsonablePost as? TestEntity else { XCTFail(); return }
            
            XCTAssertTrue(TestEntity.wasCreateCalled)
            XCTAssertEqual(TestEntity.lastContextForCreate, inMemoryPersistentContainer.viewContext)
            
            XCTAssertTrue(deserialised.wasFromJSONCalled)
            XCTAssertTrue(deserialised.lastJsonObject === SUT)
            XCTAssertEqual(deserialised.lastContextForFromJSON, inMemoryPersistentContainer.viewContext)
            XCTAssertEqual(deserialised.lastKeyPath, "category.jsonable[\(count-1)]")
        }
        
        XCTAssertEqual(count, 5)
    }
    
    func testEnumerateJSONConvertible_5JsonableTestable_isStuff()
    {
        // Arrange
        let data =
            [
                "category":
                    [
                        "testables":
                            [
                                ["titleText": "test1",
                                 "id": "1"],
                                ["titleText": "test2",
                                 "id": "2"],
                                ["titleText": "test3",
                                 "id": "3"],
                                ["titleText": "test4",
                                 "id": "4"],
                                ["titleText": "test5",
                                 "id": "5"]
                        ]
                ]
        ]
        
        let SUT = JSONObject(collection: data)
        
        // Act
        var count = 0
        SUT.enumerateObjects(ofType: JSONableTestable.self, forKeyPath: "category.testables") { (jsonableObject) in
            
            count += 1
            guard let jsonTestable = jsonableObject as? JSONableTestable else { XCTFail(); return }
            
            XCTAssertEqual(data["category"]?["testables"]?[count-1]["titleText"], jsonTestable.titleText)
            XCTAssertEqual(data["category"]?["testables"]?[count-1]["id"], jsonTestable.id)
        }
        
        XCTAssertEqual(count, 5)
    }
    
    
    func testEnumerateJSONConvertible_3JsonableTestableWithoutContext_isStuff()
    {
        // Arrange
        let data =
            [
                "category":
                    [
                        "testables":
                            [
                                ["titleText": "testabc",
                                 "id": "a"],
                                ["titleText": "test123",
                                 "id": "b"],
                                ["titleText": "test456",
                                 "id": "c"]
                        ]
                ]
        ]
        
        let SUT = JSONObject(collection: data)
        
        // Act
        var count = 0
        SUT.enumerateObjects(ofType: JSONableTestable.self, forKeyPath: "category.testables") { (jsonableObject) in
            
            count += 1
            guard let jsonTestable = jsonableObject as? JSONableTestable else { XCTFail(); return }
            
            XCTAssertEqual(data["category"]?["testables"]?[count-1]["titleText"], jsonTestable.titleText)
            XCTAssertEqual(data["category"]?["testables"]?[count-1]["id"], jsonTestable.id)
        }
        
        XCTAssertEqual(count, 3)
    }
}
