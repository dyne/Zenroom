<!-- Unused files
 
givenDebugOutputVerbose.json
givenLongOutput.json


Link file with relative path: 
<a href="./_media/examples/zencode_cookbook/givenArraysLoadInput.json" download>givenArraysLoadInput.json</a>
 
-->


# The *Given* phase: reading and verifying input

The *Given* keyword marks the first phase of Zencode execution, where input is read and processed and first internal variables are set. More precisely: 
 - Read data from files, passed using the *--data* and *--keys* parameters, formatted in JSON or CBOR (where JSON is the default and CBOR needs to be specified)
 - Validate the input, both synctatically and cryptographically. 
 - State the identity of the script executor.

 
# Intro on data input in Zencode


Zencode allows you to load a very broad spectrum of input by: 
 - Reading input data as ***JSON*** or ***CBOR***
 - Importing and validating several simple ***data types*** as well as complex data structures
 - Reading data coming with different ***encodings***, which are crucial in cryptographic operations. Zencode's default encoding is ***base64*** but many crypto-operation will work with data in ***hex*** and for example *bitcoin* uses ***base58*** encoding - Zenroom can read all of these, and more. 

Keep in mind that encodings conversions can be operated at input time as well as when the output is generated, which happens in the ***Then*** phase, which we'll discuss late.

## Encodings as *types* of simple objects

In the *Given* phase, encodings are used in Zencode in a similar fashion as declaring a variable, where an encoding is associated to a variable name. 
Loading a string from a JSON file, will look like: 

```gherkin
Given I have a 'string' named 'myString'
``` 

Some of you may find surprising referring to a ***string*** as an ***encoding***: this is due to the internal mechanics of the Zenroom virtual machine, which converts all data (to an internal encoding called ***OCTET***) when processing it and converts it back to the data original encoding when the output is being generated. The encodings supported in Zencode are: 

- ***string***
- ***number*** 
- ***hex***
- ***bin***
- ***base64*** 
- ***url64***
- ***base58***


## *Data types*: loading complex objects

So we've learned the Zencode's ***encoding*** does roughly match the *type* in traditional programming. Besides simple objects, Zenroom can read ***data types***. with different level of complexity, that we're grouping together as: 

- ***Variables***: simple atomic elements, like in traditional programming.
- ***Arrays***: one-dimensional arrays of objects sharing same encoding, arranged by a numeric value called *order*, like in traditional programming.
- ***Dictionaries***: one-dimensional arrays of objects with same encoding, where each element has a string-like name, similar to **key-value storage** 
- ***Schemas***: complex objects, whose shape is predefined in ***Zencode scenarios***

In the previous example, we've loaded a ***variable*** containing a simple object encoded as ***string***: since no ***data type*** was declared, the atomic nature of the object was implied in loading statement.

On the other hand, whenever we're loading an ***array*** or a ***dictionary***, we'll need to explicitly specifiy the encoding of the elements contained in them. 
If for example we want to load an of array hex, next to a string, we'll write something like: 

```gherkin
Given I have a 'string' named 'myString'
And I have a 'hex array' named 'someHexArray'
``` 

Loading ***schemas*** is yet a different story.

## ***Schemas***: loading complex objects for specific tasks

***Schemas*** are mostly used in cryptography, when complex cryptographic objects are used. The internal structures of the ***schemas*** will typically not be intuitive to non crypto-developers and can therefore be transparent to the user. A simple example of ***schema*** is the **<a href="./_media/examples/zencode_cookbook/cookbook_intro/alice_keyring.json" download>keyring</a>** (from the *ecdh* scenario), a more complex example is the ***credential*** (from the *credential* scenario). We'll look at schemas in detail when looking at each individual scenario.


## Strings

For security reasons (see: [LangSec strings](https://langsec.org/bof-handout.pdf)), strings need to be managed with extra care: some data manipulation will happen when working with strings, so on one hand spaces are transformed into underscores like ***___***. 
When using ***strings*** (and only in this case!) underscores and spaces are interchangeable when processing both input and output, so in Zenroom "***Hello World!***" will be interchangeable with "***Hello_World!***"

## Comments
You can add comments to your Zencode scripys by starting a line with the hashtag sign, like: 

```gherkin
# this is a comment!
``` 


# Loading data in Zencode

We're about to get our hands dirty: what will do in the rest of this tutorial about the ***Given*** phase will be mostly loading sample data and printing it out, with some occasional data manipulation. For now, keep an eye open on how the JSON files are loaded and don't worry about the rest as we'll look at data manipulation and output later in detail.

  
## Importing a flat JSON in Zencode (Part 1)
 
The *Given I have* is in fact a family of statements that do most of the data import in Zencode. Some processing is happening too the statement changes based on the operator used along: *a*, *my*. Let's try with some example:

Let's start with a create a file named *myFlatObject.json* containing several an *number*, a *string* and a *string array*:

[](../_media/examples/zencode_cookbook/cookbook_given/myFlatObject.json ':include :type=code json')




### *Given I have*: load data from a flat JSON 

The most important thing to know about loading data in Zencode, is that ***each object must be loaded individually***, and one statement is needed to load each object. In this JSON we have one ***string***, one ***number*** and one ***array***, so we'd need three to load our whole JSON file, but we'll leave alone the array for now, so two statements will be enough.

Following is a script that loads (and validates) all the data in myNestedObject.json and (extra bonus!) it randomizes the array and prints the output:

[](../_media/examples/zencode_cookbook/cookbook_given/givenLoadFlatObject.zen ':include :type=code gherkin')

Let's now the script, loading the data, using the command line:

```bash
zenroom -a myFlatObject.json -z givenLoadFlatObject.zen | tee givenLoadFlatObjectOutput.json
``` 

The output should look like this:

[](../_media/examples/zencode_cookbook/cookbook_given/givenLoadFlatObjectOutput.json ':include :type=code json')

Remember that the output gets sorted alphabetically, because in Zenroom *determinism is King*, no matter in what order you loaded them.


Once again, alla data needs to be explicitly loaded, else Zenroom will ignore them. Using the same JSON file, try now this script:

[](../_media/examples/zencode_cookbook/cookbook_given/givenLoadNumber.zen ':include :type=code gherkin')

Which should return this output:

[](../_media/examples/zencode_cookbook/cookbook_given/givenLoadNumberOutput.json ':include :type=code json')
 
 
  
<!-- Temp removed, -->



## State the user's identity: *Given I am*

By using the ***Given I am*** statement, you are declaring the identity of the one who is executing the current script. This means that, when loading nested JSON files (as in the next example), the name of one of the nested JSON objects has to match the name following the ***Given I am*** statement, looking like this: 



```gherkin
Given I am 'Alice'
``` 

This statement is typically used when: 
- Executing cryptographic operations that will need a key or a keyring: the keys are passed to Zenroom (via *-a* and *-k* parameters) as JSON or CBOR files, using a format that includes the owner of the keys. In the next example we'll indeed a *keyring*.
- In scripts where the identity is a condition for the execution of the script.

Note: this statement has a number of alias, so you these you can use the same statement with the syntax:

```gherkin
Given I am known as 'Alice'
``` 

Or

```gherkin
Given that I am known as 'Alice'
``` 

## Passing the identity via parameter:  *Given my name is in ''*

You can also load the identity of the user executing the script, from a parameter, which allows you to keep a clear separation of the code and the data. The statement looks like: 

```gherkin
Given my name is in a 'string' named 'myUserName'
``` 

And you will need to pass the identity in a parameter, looking like this: 

```json
{
	"myUserName" : "Alice"
}
```

The paramater can be passed to Zenroom (via *-a* and *-k* parameters) as JSON or CBOR files. 


## *Given I have*: load data from nested JSON file (part 2)

So let's go one step further and create a JSON file that containing two nested objects, we'll call it named *myNestedObject.json*:

[](../_media/examples/zencode_cookbook/cookbook_given/myNestedObject.json ':include :type=code json')
 
The JSON objects contain each a ***string***, a ***number*** and an ***array*** (we'll leave the arrays alone for now) and one also contains a cryptographic ***keyring***. 
We'll load a ***string***, a ***number*** and an ***keyring*** from the first object and  a ***string***, a ***number*** from the second one. 

Things you should focus on:
- In order to load the crypto keyring you'll need to use a *scenario*, in this case we'll use the *scenario 'simple'*, don't worry about this for now. 
- We're using the ***Given I am*** and the ***my*** operator to load data from the first JSON object, whose name matches the one declared in the ***Given I am*** statement.
- We're loading the second ***string*** and ***number*** from a second JSON object, whose name we need to state.

Time to look at the script and run it: 
 
[](../_media/examples/zencode_cookbook/cookbook_given/givenLoadNestedObject.zen ':include :type=code gherkin')
 
The output should look like this: 

[](../_media/examples/zencode_cookbook/cookbook_given/givenLoadNestedObjectOutput.json ':include :type=code json')

Once more, when looking at the output, remember that *determinism is king*. You'll read about manipulating, formatting and sorting the output when we'll get through the ***Then*** phase.

## The ***Array***: one per data type

Time to talk about the *arrays*, we have already loaded one but we also mentioned they need some extra attention in Zencode: unlike most programming language, the data type contained in the array has to be declared for each array. As a result, you have many different types of ***array*** and there is no such thing like a generic array.

The data types allowed are: 
 - string 
 - number 
 - bin 
 - hex
 - base64
 - base58
 - url64 

The syntax to load an ***array*** is pretty straight forward, just declare the *type* before the word ***array***, surround by single brackets, like this: 



```gherkin
Given I have a 'hex array' named 'myFavouriteColors'
``` 

If you want to experiment with loading different types of ***array*** you can experiment by loading the JSON file <a href="./_media/examples/zencode_cookbook/cookbook_given/givenArraysLoadInput.json" download>givenArraysLoadInput.json</a> using the script <a href="../_media/examples/zencode_cookbook/cookbook_given/givenArraysLoad.zen" download>givenArraysLoad.zen</a> with the line: 

```bash
zenroom -a givenArraysLoadInput.json -z givenArraysLoad.zen | tee myArraysOutput.json
``` 

The output should looke like this: <a href="../_media/examples/zencode_cookbook/cookbook_given/givenArraysLoadOutput.json" download>givenArraysLoadOutput.json</a>.
 

 
# Loading dictionaries

The last group includes all the statements that are exclusive to ***dictionaries***. A dictionary is a ***complex object*** that can be nested under another dictionary to create a ***list*** (that is still referred to as dictionary). Dictionaries can have ***different internal structure***. You can use dictionaries for examples when you have a list of transactions, a list of accounts, a list of data entries.

A basic ***list of dictionaries*** could look like:

```json
{
	"List" : {
		"Dictionary1": {
			"someNumber" : 1
		},
		"Dictionary2":{
			"someNumber" : 2

		},
		"Dictionary3":{
			"someNumber": 3,
			"someOtherNumber": 4
		}
	}
}
```

Here is a more complex ***list of dictionaries*** which contains elements of different type, including arrays:


```json
{
	"Beatles" : {
		"John": {
			"yearOfBirth" : 1940,
			"spouse" : ["Cynthia Powell","Yoko Ono"]

		},
		"Paul":{
			"instrumentPlayed":"bass",
			"spouse" : ["Linda Eastman","Heather Mills","Nancy Shevell"]
		},
		"Ringo":{
			"yearOfBirth":1940,
			"instrumentPlayed":"guitar",
			"spouse" : ["Maureen Cox","Barbara Bach" ]
		},
		"George":{
			"yearOfBirth":1943
		}
	}
}
```

Dictionaries are named and loaded in the same fashion as arrays, so in order to load a dictionary like the one above you will write something like:

```gherkin
Given I have a 'string dictionary' named 'Beatles' 
```

## Variations on *Given I have*, to load a nested JSON aka *Dictionary* (part 3)

Let's now load some real arrays, from a more complex JSON like this one: 

[](../_media/examples/zencode_cookbook/cookbook_given/myTripleNestedObject.json ':include :type=code json')

Let's try with this script: 

[](../_media/examples/zencode_cookbook/cookbook_given/givenLoadTripleNestedObject.zen ':include :type=code gherkin')
 

The output should look like this: 

[](../_media/examples/zencode_cookbook/cookbook_given/givenTripleNestedObjectOutput.json ':include :type=code json')

### More on loading dictionaries

So let's try to load a real dataset that contains two dictionaries, dummy datasets representing transactions, the first named *ABC-TransactionListFirstBatch* and the second *ABC-TransactionListSecondBatch*, which we'll save in the file **dictionariesBlockchain.json**:

[](../_media/examples/zencode_cookbook/cookbook_dictionaries/dictionariesBlockchain.json ':include :type=code json')


In order to load that the two dictionaries we'll use this script:

[](../_media/examples/zencode_cookbook/cookbook_dictionaries/dictionariesGiven.zen ':include :type=code gherkin')

Note that along with the dictionaries, we are also loadin two ***numbers*** where the one named *PricePerKG* exists as well as inside each element of the object: this homonimy is not a problem in this case.
You can use the *debug* statement everytime you are not sure about what is being loaded and what note, just read on to find out how.


# Corner cases


## Enjoy the silence: *Given nothing*
 
 This statement sets a pre-condition to the execution of the script: *Given nothing* will halt the execution if data is passed to Zenroom via *--data* and *--keys* parameters, you want to use it when you want to be sure that no data is being passed to Zenroom. You may want to use it when you generate random objects or the keyring. 
 
 
## Homonymy

Now let's look at corner cases: what would happen if I load two differently named objects, that contain objects with the same name? Something like this: 

[](../_media/examples/zencode_cookbook/cookbook_given/myNestedRepetitveObject.json ':include :type=code json')

We could try using the following script:


[](../_media/examples/zencode_cookbook/cookbook_given/givenLoadRepetitveObject.zen ':include :type=code gherkin')

After uncommenting the statemen that loads the object *'myStringArray'* for the second time, Zenroom would halt the execution and return an error.


## JSON empty objects and the *null* values 

You may bump into empty objects or null values like these: 
 
```json

{ "myData": {
		"myString1": "",
		"myString2": null,
		"myString3": "Hello World!"
	}
}
```

and you would load it with: 

```gherkin
Given I have a 'string' named 'myString1' in 'myData'
Given I have a 'string' named 'myString2' in 'myData'
Given I have a 'string' named 'myString3' in 'myData'
Then print data
```

When doing so, you would incur in errors, cause Zenroom doesn't load objects with empty or *null* values. On the other hand, Zenroom doesn't normally allow you to set or change the value of an existing object, so importing an empty object expecting to fill it later, doesn't make much sense. You may instead create, copy and rename new objects at execution time, you will read about this in the [When](/pages/zencode-cookbook-when?id=manipulation-sumsubtract-rename-remove-append) section of this manual.

 

<!-- Temp removed, 

 
# Comprehensive list of *Given* statements

Let's use an even larger object this time, named *myLargeNestedObject.json*: 

[](../_media/examples/zencode_cookbook/cookbook_given/myLargeNestedObject.json ':include :type=code json')

Below is a list of most of the *Given* statements you will need to load data in Zenroom:

[](../_media/examples/zencode_cookbook/cookbook_given/givenFullList.zen ':include :type=code gherkin')
-->

# The script used to create the material in this page

All the smart contracts and the data you see in this page are generated by the script [cookbook_given.sh](https://github.com/dyne/Zenroom/blob/master/test/zencode/cookbook_given.bats) and [cookbook_dictionaries.sh](https://github.com/dyne/Zenroom/blob/master/test/zencode/cookbook_dictionaries.bats) If you want to run the script (on Linux) you should: 
 - *git clone https://github.com/dyne/Zenroom.git*
 - install **zsh** and **jq**
 - download a [zenroom binary](https://zenroom.org/#downloads) and place it */bin* or */usr/bin* or in *./Zenroom/src*


