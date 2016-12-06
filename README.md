# ParSON
#### A lightweight JSON to swift Parser

Apple provides a way to get JSON from a URL but after that generally parsing is left up to you, and it's generally not the cleanest of affairs. This is my personal take on providing a solution.

## How to

**Given the JSON of**

```swift
let jsonData = 
[
	"first":
	[
		"name": "Alphabet",
		"upperCase": ["A", "B", "C"],
		"lowerCase": ["a","b","c"]
	],
	"second":
	[
		"name": "Numerics",
		"data": ["1","2","3"]
	]
]
```
	
#### Dictionaries
```swift
let parsonObject = ParSON(collection: jsonData)

let firstDictionary: [String: AnyObject] = try! parsonObject.value(forKeyPath: "first")
let secondDictionary: [String: AnyObject] = try! parsonObject.value(forKeyPath: "second")
```
	
and you can then access the values normally as one would traverse a swift collection.

If however you wish to iterate through the json and get a value directly, you can.
```swift
let nameOfFirstStuff: String = try! parsonObject.value(forKeyPath: "first.name")
let nameOfSecondStuff: String = try! parsonObject.value(forKeyPath: "second.name")
```	
So dictionaries should be pretty straight forward each successive key inside it's parent dicitonary is prepended with a "."

**e.g** "this.that.thisOneInsideThat.other"

#### Arrays
```swift
let upperCaseAlphabetFirstLetter: [String] = try! parsonObject.value(forKeyPath: "first.upperCase[0]") // 'A'
let thirdNumericalItem: [String] = try! parsonObject.value(forKeyPath: "second.data[2]") // '3'
```	
just place the index you wish to access inside square brackets, this also works for nested array
```swift
let nestedJSONArray =
[
	"response":
	[
		[
			["hello", "there"],
			["cup", "of", "tea?"]
		],
		["good", "bye"]
	],
	"addOn": ["and", "good", "luck"]
]

let parsonObject = ParSON(collection: nestedJSONArray)

var greeting: String = try! parsonObject.value(forKeyPath: "response[0][0]") // 'hello' 
greeting.append(" \(try! parsonObject.value(forKeyPath: "response[0][1]") as String).") // 'hello there. '
greeting.append(" \(try! parsonObject.value(forKeyPath: "response[0][1]") as String)") // 'hello there. cup'
greeting.append(" \(try! parsonObject.value(forKeyPath: "response[0][1]") as String)") // 'hello there. cup of'
greeting.append(" \(try! parsonObject.value(forKeyPath: "response[0][1]") as String)") // 'hello there. cup of tea?'

var leaving = parsonObject.value(forKeyPath: "response[1][0]") // 'good'
leaving.append( " \(try! parsonObject.value(forKeyPath: "response[1][0]") as String).") // 'good bye.'

leaving.append( " \(try! parsonObject.value(forKeyPath: "addOn[0]") as String)") // 'good bye. and'
leaving.append( " \(try! parsonObject.value(forKeyPath: "addOn[1]") as String)") // 'good bye. and good'
leaving.append( " \(try! parsonObject.value(forKeyPath: "addOn[2]") as String).") // 'good bye. and good luck.'
```	
## Collection Enumeration

If however instead of manually accessing the collection for each key and or index and you just wish to iterate over a known dictionary or array you can do so like so.
```swift
let jsonData = 
[
	"employees":
	[
		"jim",
		"barb",
		"sam"
	],
	"managers":
	[
		"racheal": ["dept": "HR", "salary": 123],
		"gavin": ["dept": "RND", "salary": 122]
	]
]

let parsonObject = ParSON(collection: jsonData)

parsonObject.enumerateObject(atKeyPath: "employees") { (keyIndex, element) in
	print("element: \(element) at index \(keyIndex)")
}

// element: jim at index 0
// element: barb at index 1
// element: sam at index 2

jsonObject.enumerateObject(atKeyPath: "managers") { (keyIndex, element) in
	print("element: \(element) for key \(keyIndex)")
}

// element: {"dept": "HR", "salary": 123} for key racheal
// element: {"dept": "RND", "salary": 122} for key gavin
```

## Object Enumeration

Generally you will pull values from the JSON and then assign the value to an instance variable of a class, the larger the class the more tedious this can become, ParSON however offers a way for you to dictate how each class will map the values and when enumerating you will get the object with the mapped values assigned.

**First, your class should conform to the protocol ParSONDeserializable**

``` swift
protocol ParSONDeserializable 
{
	static func create(inContext context: NSManagedObjectContext) -> Self
	func deserialize(_ parsonObject: ParSON, context: NSManagedObjectContext, keyPath: String) throws
}
```
**Example**
```swift
fileprivate class JSONableTestable: ParSONDeserializable
{
    private(set) var text: String?
    private(set) var id: String?

    static func create(inContext context: NSManagedObjectContext) -> Self {
	return .init()
    }

    func deserialize(_ parsonObject: ParSON, context: NSManagedObjectContext, keyPath: String) throws {
	self.id = try parsonObject.value(forKeyPath: "\(keyPath).id")
	self.text = try parsonObject.value(forKeyPath: "\(keyPath).text")
    }
}

let jsonData =
[
	"testables":
	[
		["id": "first"
		"text": "Welcome"],
		["id": "second"
		"text": "to my"],
		["id": "third"
		"text": "example"]
	]
]
	
	let jsonObject = ParSON(collection: jsonData)
	
	jsonObject.enumerateObjects(ofType: JSONableTestable.self, forKeyPath: "testables") { (jsonableObject) in
            
	    //The closure returns a JSONAble so, if you want to access the variables you need to cast it.
            guard let jsonTestable = jsonableObject as? JSONableTestable else { return }
            
		print("\(jsonTestable.id)")
		print("\(jsonTestable.text)")
        }
	
	// 'first'
	// 'Welcome'
	// 'second'
	// 'to my'
	// 'third'
	// 'example'
```	
## Core Data

You may notice that the ParSONDeserializable protocol and a few of the other methods have a parameter for an **NSManagedObjectContext**, this is in case you are using core data objects, you can pass the context through to create the objects inside the context.

## Exception Handling TBD
