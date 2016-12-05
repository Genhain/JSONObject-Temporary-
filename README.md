# JSONObject-Temporary-

Example usage

given the JSON of

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
	
you can extract the first two dictionaries like so

	let jsonObject = JSONObject(collection: jsonData)

	let firstDictionary: [String: AnyObject] = jsonObject.value(forKeyPath: "first")
	let secondDictionary: [String: AnyObject] = jsonObject.value(forKeyPath: "second")
	
and you can then access the values normally as one would traverse a swift collection.

If However you wish to iterated through the json and get a value directly, you can.

	let nameOfFirstStuff: String = jsonObject.value(forKeyPath: "first.name")
	let nameOfSecondStuff: String = jsonObject.value(forKeyPath: "second.name")
	
So dictionaries should be pretty straight forward each successive key inside it's parent dicitonary is prepended with a "."

e.g "this.that.thisOneInsideThat.other"

For arrays however the syntax is a little different

	let upperCaseAlphabetFirstLetter: [String] = jsonObject.value(forKeyPath: "first.upperCase[0]") // 'A'
	let thirdNumericalItem: [String] = jsonObject.value(forKeyPath: "second.data[2]") // '3'
	
just place the index you wish to access inside square brackets, this also works for nested array

given

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
	
	let jsonObject = JSONObject(collection: nestedJSONArray)
	
	var greeting: = jsonObject.value(forKeyPath: "response[0][0]") // 'hello' 
	greeting.append(" \((jsonObject.value(forKeyPath: "response[0][1]") as String). ") // 'hello there. '
	greeting.append(" \((jsonObject.value(forKeyPath: "response[1][0]") as String)") // 'hello there. cup'
	greeting.append(" \((jsonObject.value(forKeyPath: "response[1][1]") as String)") // 'hello there. cup of'
	greeting.append(" \((jsonObject.value(forKeyPath: "response[1][2]") as String)") // 'hello there. cup of tea?'
	
	var leaving = jsonObject.value(forKeyPath: "response[1][0]") // 'good'
	leaving.append( " \((jsonObject.value(forKeyPath: "response[1][0]") as String)." // 'good bye.'
	
	leaving.append( " \((jsonObject.value(forKeyPath: "addOn[0]") as String)" // 'good bye. and'
	leaving.append( " \((jsonObject.value(forKeyPath: "addOn[1]") as String)" // 'good bye. and good'
	leaving.append( " \((jsonObject.value(forKeyPath: "addOn[2]") as String)." // 'good bye. and good luck.'
	
