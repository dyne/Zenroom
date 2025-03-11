# The Zenroom's virtual machine

At each run, Zenroom starts a **virtual machine** (VM) that is completely isolated from the operating system, has no access to the file system, is stateless and [fully deterministic](/pages/random). During operation, Zenroom's memory is heavily fenced and it gets wiped when Zenroom shuts down.

The Zenroom VM then executes smart contracts in the  domain-specific language **Zencode** and in Lua.


# Smart contracts in *human* language

The domain-specific language **Zencode** reads in a [natural English-like fashion](https://decodeproject.eu/blog/smart-contracts-english-speaker), and allows to perform cryptographic operations as long as more traditional data manipulation.

Zencode is heavily inspired by the [language-theoretical security](http://langsec.org) research and the [BDD Language](https://en.wikipedia.org/wiki/Behavior-driven_development). 

For the theoretical background see the [Zencode Whitepaper](https://files.dyne.org/zenroom/Zencode_Whitepaper.pdf).


# The 3 phases of Zencode execution

the Zenroom virtual machine that executes **Zencode** smart contracts operate in 3 phases:

1. **Given** - loads and validates the input
2. **When** - performs the computing
3. **Then** - prints out the output

The 3 separate blocks of code also correspond to 3 separate memory areas, sealed by security measures. 

If any single line in a Zencode contract fails, Zenroom stops executing and returns the error.

![Zencode documentation diagram](../_media/images/zencode_diagram.png)

All data processed has first to pass the validation phase according to scenario specific data schemas.
# How to execute Zenroom scripts

This section explains how to invoke the Zenroom to execute scripts from commandline or using the interactive console.


## Commandline

From **command-line** the Zenroom is operated passing files as
arguments:
```text
Usage: zenroom [-h] [-s] [ -D scenario ] [ -i ] [ -c config ] [ -k keys ] [ -a data ] [ -z | -v ] [ -l lib ] [ script.lua ]
```
where:
* **`-h`** show the help meessage
* **`-s`** activate seccomp execution
* **`-D`** followed by a scenario return all the statements under that scenario divided by the phase they are into
* **`-i`** activate the interactive mode
* **`-c`** followed by a string indicates the [configuration](zenroom-config.md) to use
* **`-k`** indicates the path to contract keys file
* **`-a`** indicates the path to contract data file
* **`-z`** activates the **zenCode** interpreter (rather than Lua)
* **`-v`** run only the given phase and reutrn if the input is valid for the given smart contract
* **`-l`**  allows to load an external lua library before executing zencode.

## Interactive console

Just executing `zenroom` will open an interactive console with limited functionalities, which is capable to parse finite instruction blocks on each line. To facilitate editing of lines is possible to prefix it with readline using the `rlwrap zenroom` command instead.

The content of the KEYS, DATA and SCRIPT files cannot exceed 2MiB.

Try:
```sh
./zenroom             [enter]
print("Hello World!") [enter]
                      [Ctrl-D] to quit
```
Will print Zenroom's execution details on `stderr` and the "Hello World!" string on `stdout`.

## Hashbang executable script

Zenroom also supports being used as an "hashbang" interpreter at the beginning of executable scripts. Just use:
```sh
#!/usr/bin/env zenroom
```
in the header to run lua commands with zenroom, or
```sh
#!/usr/bin/env -S zenroom -z
```
to run zencode contracts (the `-S` lets you pass multiple arguments in the shebang line).

# Quickstart: My first random array :id=quickstart

One of Zenroom's strong points is the quality of the random generation (see [random test 1](https://github.com/dyne/Zenroom/blob/master/test/random_hamming_gnuplot.sh)
and [random test 2](https://github.com/dyne/Zenroom/blob/master/test/random_rngtest_fips140-2.sh)).

Let's first go the super fast way to test code, entering the [Zenroom web playground](https://apiroom.net). Copy this code into the *Zencode* tab on the top left of the page:


```gherkin
Given nothing
When I create the array of '16' random objects of '32' bits
Then print all data
```



Then press the *PLAY▶️* button to execute the script, the result should look like this:

![CreateArrayWebDemo](../_media/images/ApiroomQuickIntro.png)

We got a nice array here. You can play with the values *'16'* and *'32'*, to see both the array and the random numbers change their length.

# Use Zenroom by command line (CLI)

Once you're done with your array, it's time to go pro, meaning that we're leaving the web demo and moving to using Zenroom as *command line application* (CLI).

 - The first step is to download a version of Zenroom that works on your system from the [Zenroom downloads](https://zenroom.org/#downloads).
 - If you're using Linux, you'll want to place Zenroom in `/bin` or `/usr/sbin` (or just create a symlink or an alias).
 - Third, fire up your favourite text editor, paste the smart contract in it and save it *arrayGenerator.zen*

Now you can let zenroom execute the script by launching the command:

```
zenroom -z arrayGenerator.zen
```

The result will look like this:

![CreateArrayRaspi](../_media/images/cookbookCreateArrayRaspi.png)

In the example Zenroom did graciously output first the licensing, then some information about the file and the execution setting, a warning, our array and finally a message stating the it correctly shutdown after using a certain amount of RAM...a lot of information: how do I get my array saved into a file that I can later use?

On Linux, you can use:

```bash
zenroom -z arrayGenerator.zen | tee myFirstRandomArray.json
```

After running this command, a file named *myFirstRandomArray.json* should have magically appeared in the folder you're in, looking like <a href="./_media/examples/zencode_cookbook/cookbook_intro/myFirstRandomArray.json" download>this one</a>.

# Renaming the array: the *And* keyword

Open *myArray.json* with your text editor, and notice that the array produced with our first script is named "array": that is Zenroom's behaviour when creating objects. But what if that array should be called something else? First you will need to learn two concepts:
 - All data manipulation has to occur in the *When* phase.
 - Each phase can have as many commands as you like, provided that they're on a different line and they begin with the keyword *And*
For example, you can rename your array to *'myArray'* by running this script:

```gherkin
Given nothing
When I create the array of '16' random objects of '32' bits
And I rename the 'array' to 'myArray'
Then print all data
```

Note that you need to use the **' '** in the line that renames the array, cause you may be generating and renaming a bunch of arrays already, like in this script:

```gherkin
Given nothing
When I create the array of '2' random objects of '8' bits
And I rename the 'array' to 'myTinyArray'
And I create the array of '4' random objects of '32' bits
And I rename the 'array' to 'myAverageArray'
And I create the array of '8' random objects of '128' bits
And I rename the 'array' to 'myBigFatArray'
Then print all data 
```


The script above will produce an output like this:


```json
{"myAverageArray":["wGI/kQ==","Y95+uw==","Jgwjxw==","0d/n5g=="],"myBigFatArray":["P5LyQaN54vyTTVKxZyBXIg==","eO2h+vocrBbrYQGST/i8hQ==","xmZs6L56Ru0P+JlCbDvlew==","EiF5mmW3+YpEIDElRo1uvg==","YJofnEkTQL6HCgpgA9DpRg==","rHM0SppnvEjlMHpV6tsuXQ==","u448E+Ms3dIvuzRnWQMNHw==","dlUhdpdwM9Stfi8ljtdyZA=="],"myTinyArray":["XQ==","2A=="]}
```



Certainly, at this point, your keen eye has noted something odd in the output...If in the Zencode I generated the arrays sorted by size,
why is output sorted differently? Because in Zenroom, my friend,  [Determinism](https://github.com/dyne/Zenroom/blob/master/test/determinism/run.bats)
is king, so Zenroom will by default sort the output alphabetically.

If you enjoyed the trip so far, go on and learn how to program Zencode starting by the [Given](/pages/zencode-cookbook-given) phase.
<!-- Unused files
 
givenDebugOutputVerbose.json
givenLongOutput.json


Link file with relative path: 
<a href="./_media/examples/zencode_cookbook/givenArraysLoadInput.json" download>givenArraysLoadInput.json</a>
 
-->


# The *Given* phase: reading and verifying input

The *Given* keyword marks the first phase of Zencode execution, where input is read and processed and first internal variables are set. More precisely: 
 - Read data from files, passed using the *--data* and *--keys* parameters, formatted in JSON
 - Validate the input, both synctatically and cryptographically. 
 - State the identity of the script executor.

 
# Intro on data input in Zencode


Zencode allows you to load a very broad spectrum of input by: 
 - Reading input data as ***JSON***
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
- ***number*** or ***float***
- ***time***
- ***integer***
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

```json
{ 
      "myNumber":12345,
      "myString":"Hello World!",
      "myFiveStrings":[
         "String-1-one",
         "String-2-two",
         "String-3-three",
	 "String-4-four",
	 "String-5-five"
      ]
}
```




### *Given I have*: load data from a flat JSON 

The most important thing to know about loading data in Zencode, is that ***each object must be loaded individually***, and one statement is needed to load each object. In this JSON we have one ***string***, one ***number*** and one ***array***, so we'd need three to load our whole JSON file, but we'll leave alone the array for now, so two statements will be enough.

Following is a script that loads (and validates) all the data in myNestedObject.json and (extra bonus!) it randomizes the array and prints the output:

```gherkin
Given I have a 'string' named 'myString'  
Given I have a 'number' named 'myNumber'
Then print all data
```

Let's now the script, loading the data, using the command line:

```bash
zenroom -a myFlatObject.json -z givenLoadFlatObject.zen | tee givenLoadFlatObjectOutput.json
``` 

The output should look like this:

```json
{"myNumber":12345,"myString":"Hello World!"}
```

Remember that the output gets sorted alphabetically, because in Zenroom *determinism is King*, no matter in what order you loaded them.


Once again, alla data needs to be explicitly loaded, else Zenroom will ignore them. Using the same JSON file, try now this script:

```gherkin
Given I have a 'number' named 'myNumber'
Then print all data
```

Which should return this output:

```json
{"myNumber":12345}
```
 
 
  
<!-- Temp removed, -->



## State the user's identity: *Given I am*

By using the ***Given I am*** statement, you are declaring the identity of the one who is executing the current script. This means that, when loading nested JSON files (as in the next example), the name of one of the nested JSON objects has to match the name following the ***Given I am*** statement, looking like this: 



```gherkin
Given I am 'Alice'
``` 

This statement is typically used when: 
- Executing cryptographic operations that will need a key or a keyring: the keys are passed to Zenroom (via *-a* and *-k* parameters) as JSON files, using a format that includes the owner of the keys. In the next example we'll indeed a *keyring*.
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

The paramater can be passed to Zenroom (via *-a* and *-k* parameters) as JSON files. 


## *Given I have*: load data from nested JSON file (part 2)

So let's go one step further and create a JSON file that containing two nested objects, we'll call it named *myNestedObject.json*:

```json
{
	"Alice":{
      "keyring":{
         "ecdh":"AxLMXkey00i2BD675vpMQ8WhP/CwEfmdRr+BtpuJ2rM="
      },
	  "myFirstNumber":87654321,
      "myFirstString":"Hello World!",
      "myFirstArray":[
         "Hello World! N.1",
         "Hello World! N.2",
         "Hello World! N.3",
         "Hello World! N.4"
      ]
   },
	"theSecondObject":{
      "theSecondNumber":12345678,
	  "theSecondString":"Oh, hello again!",
      "theSecondArray":[
         "123",
         "4.56",
         "123.45678",
         "12345678"
      ]      
   }   
}
```
 
The JSON objects contain each a ***string***, a ***number*** and an ***array*** (we'll leave the arrays alone for now) and one also contains a cryptographic ***keyring***. 
We'll load a ***string***, a ***number*** and an ***keyring*** from the first object and  a ***string***, a ***number*** from the second one. 

Things you should focus on:
- In order to load the crypto keyring you'll need to use a *scenario*, in this case we'll use the *scenario 'simple'*, don't worry about this for now. 
- We're using the ***Given I am*** and the ***my*** operator to load data from the first JSON object, whose name matches the one declared in the ***Given I am*** statement.
- We're loading the second ***string*** and ***number*** from a second JSON object, whose name we need to state.

Time to look at the script and run it: 
 
```gherkin
Scenario 'ecdh': let us load some stuff cause it is fun!
# 
# Here I am stating who I am:
Given I am 'Alice'
#
# Here I load the data from the JSON object having my name:
And I have my 'keyring'
And I have my 'string' named 'myFirstString'
And I have my 'number' named 'myFirstNumber'
#
# Here I load data from a different JSON object:
And I have a 'string' named 'theSecondString' inside 'theSecondObject'
And I have a 'number' named 'theSecondNumber' inside 'theSecondObject' 
Then print all data
```
 
The output should look like this: 

```json
{"myFirstNumber":8.765432e+07,"myFirstString":"Hello World!","theSecondNumber":1.234568e+07,"theSecondString":"Oh, hello again!"}
```

Once more, when looking at the output, remember that *determinism is king*. You'll read about manipulating, formatting and sorting the output when we'll get through the ***Then*** phase.

## The ***Array***: one per data type

Time to talk about the *arrays*, we have already loaded one but we also mentioned they need some extra attention in Zencode: unlike most programming language, the data type contained in the array has to be declared for each array. As a result, you have many different types of ***array*** and there is no such thing like a generic array.

The data types allowed are: 
 - string 
 - number or float
 - time
 - integer
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

```json
{
   "myFirstObject":{
      "myFirstNumber":1,
	  "myFirstString":"Hello World!",
      "myFirstHex": "616e7976616c7565",
	  "myFirstArray":[
         "String1",
		 "String2"
      ]
   },
   "mySecondObject":{
      "mySecondNumber":2,
      "mySecondArray":[
         "anotherString1",
         "anotherString2"
      ]
   },
   "myThirdObject":{
      "myThirdNumber":3,
      "myThirdArray":[
         "oneMoreString1",
         "oneMoreString2",
         "oneMoreString3"
      ]
   },
   "myFourthObject":{
      "myFourthArray":[
         "oneExtraString1",
         "oneExtraString2",
         "oneExtraString3",
		 "oneExtraString4"
      ]
   }
}
```

Let's try with this script: 

```gherkin
# Given I have a 'string array' named 'myFirstArray'   
Given I have a 'string array' named 'mySecondArray' inside 'mySecondObject'
Given I have a 'string array' named 'myThirdArray' inside 'myThirdObject' 
Given I have a 'string array' named  'myFourthArray' inside 'myFourthObject'   
Given I have a 'number' named 'myFirstNumber' inside 'myFirstObject'
Given I have a 'string' named 'myFirstString' inside 'myFirstObject'
Given I have a 'hex' named 'myFirstHex' inside 'myFirstObject'
Then print all data
```
 

The output should look like this: 

```json
{"myFirstHex":"616e7976616c7565","myFirstNumber":1,"myFirstString":"Hello World!","myFourthArray":["oneExtraString1","oneExtraString2","oneExtraString3","oneExtraString4"],"mySecondArray":["anotherString1","anotherString2"],"myThirdArray":["oneMoreString1","oneMoreString2","oneMoreString3"]}
```

### More on loading dictionaries

So let's try to load a real dataset that contains two dictionaries, dummy datasets representing transactions, the first named *ABC-TransactionListFirstBatch* and the second *ABC-TransactionListSecondBatch*, which we'll save in the file **dictionariesBlockchain.json**:

```json
{
   "TransactionsBatchB":{
      "Information":{
         "Metadata":"TransactionsBatchB6789",
         "Buyer":"John Doe"
      },
      "ABC-Transactions1Data":{
         "timestamp":1597573139,
         "TransactionValue":1000,
         "PricePerKG":2,
         "TransferredProductAmount":500,
         "UndeliveredProductAmount":100,
         "ProductPurchasePrice":1
      },
      "ABC-Transactions2Data":{
         "timestamp":1597573239,
         "TransactionValue":1000,
         "PricePerKG":2
      },
      "ABC-Transactions3Data":{
         "timestamp":1597573339,
         "TransactionValue":1000,
         "PricePerKG":2,
         "TransferredProductAmount":500
      },
      "ABC-Transactions4Data":{
         "timestamp":1597573439,
         "TransactionValue":2000,
         "PricePerKG":4,
         "TransferredProductAmount":500
      },
      "ABC-Transactions5Data":{
         "timestamp":1597573539,
         "TransactionValue":2000,
         "PricePerKG":4,
         "TransferredProductAmount":500
      },
      "ABC-Transactions6Data":{
         "timestamp":1597573639,
         "TransactionValue":2000,
         "PricePerKG":4,
         "TransferredProductAmount":500
      }
   },
   "TransactionsBatchA":{
      "Information":{
         "Metadata":"TransactionsBatchA12345",
         "Buyer":"Jane Doe"
      },
      "ABC-Transactions1Data":{
         "timestamp":1597573040,
         "TransactionValue":1000,
         "PricePerKG":2,
         "TransferredProductAmount":500
      },
      "ABC-Transactions2Data":{
         "timestamp":1597573140,
         "TransactionValue":1000,
         "PricePerKG":2,
         "TransferredProductAmount":500
      },
      "ABC-Transactions4Data":{
         "timestamp":1597573240,
         "TransactionValue":2000,
         "PricePerKG":4,
         "TransferredProductAmount":500
      },
      "ABC-Transactions5Data":{
         "timestamp":1597573340,
         "TransactionValue":1000
      },
      "ABC-Transactions6Data":{
         "timestamp":1597573440,
         "TransactionValue":1000,
         "PricePerKG":2,
         "TransferredProductAmount":510
      },
      "ABC-Transactions7Data":{
         "timestamp":1597573440,
         "TransactionValue":1000,
         "PricePerKG":2,
         "TransferredProductAmount":520
      },
      "ABC-Transactions8Data":{
         "timestamp":1597573440,
         "TransactionValue":2000,
         "PricePerKG":4
      }
   },
   "TransactionAmountsA":{
      "InitialAmount":20,
      "LaterAmount":30,
      "Currency":"EUR"
   },
   "TransactionAmountsB":{
      "InitialAmount":50,
      "LaterAmount":60,
      "Currency":"EUR"
   },
   "PowerData":{
      "Active_power_imported_kW":4.85835600,
      "Active_energy_imported_kWh":53.72700119,
      "Active_power_exported_kW":0.0,
      "Apparent_energy_imported_kVAh":0,
      "Apparent_power_exported_kVA":0.00000000,
      "Apparent_energy_exported_kVAh":0.00000000,
      "Power_factor":0.71163559,
      "Application_data":"Application_data_string",
      "Application_UID":"Application_UID_string",
      "Currency":"EUR",
      "Expected_annual_production":0.00000000
   },
   "dictionaryToBeFound":"ABC-Transactions1Data",
   "objectToBeCopied":"LaterAmount",
   "referenceTimestamp":1597573340,
   "PricePerKG":3,
   "otherPricePerKG":5,
   "myUserName":"Authority1234",
   "myVerySecretPassword":"password123",
   "notPrunedDictionary": {
      "empty1": "",
      "notEmpty": "Hello World!",
      "empty2": "",
      "emptyDictionary": {
         "empty3": "",
	 "empty4": ""
      }
   }
}
```


In order to load that the two dictionaries we'll use this script:

```gherkin
# LOAD DICTIONARIES
# Here we load the two dictionaries and import their data.
# Later we also load some numbers, one of them name "PricePerKG" exists in the dictionary's root, 
# as well as inside each element of the object: homonimy is not a problem in this case.
Given that I have a 'string dictionary' named 'TransactionsBatchA'
Given that I have a 'string dictionary' named 'TransactionsBatchB'

Given that I have a 'string dictionary' named 'TransactionAmountsA'
Given that I have a 'string dictionary' named 'TransactionAmountsB'
Given that I have a 'string dictionary' named 'PowerData'

Given that I have a 'string dictionary' named 'notPrunedDictionary'


# Loading other stuff here
Given that I have a 'number' named 'referenceTimestamp'
Given that I have a 'number' named 'PricePerKG'
Given that I have a 'number' named 'otherPricePerKG'
Given that I have a 'string' named 'dictionaryToBeFound'
Given that I have a 'string' named 'objectToBeCopied'
Given that I have a 'string' named 'myVerySecretPassword'

# Setting my identity
Given my name is in a 'string' named 'myUserName'
```

Note that along with the dictionaries, we are also loadin two ***numbers*** where the one named *PricePerKG* exists as well as inside each element of the object: this homonimy is not a problem in this case.
You can use the *debug* statement everytime you are not sure about what is being loaded and what note, just read on to find out how.


# Corner cases


## Enjoy the silence: *Given nothing*
 
 This statement sets a pre-condition to the execution of the script: *Given nothing* will halt the execution if data is passed to Zenroom via *--data* and *--keys* parameters, you want to use it when you want to be sure that no data is being passed to Zenroom. You may want to use it when you generate random objects or the keyring. 
 
 
## Homonymy

Now let's look at corner cases: what would happen if I load two differently named objects, that contain objects with the same name? Something like this: 

```json
{
   "myFirstObject":{
      "myNumber":11223344,
      "myString":"Hello World!",
      "myStringArray":[
         "String1",
         "String2",
         "String3",
         "String4"
      ]
   },
   "mySecondObject":{
      "mySecondNumber":1234567890,
	  "mySecondString":"Oh, hello again!",
      "myStringArray":[
         "anotherString1",
         "anotherString2",
         "anotherString3",
         "anotherString4"
      ]
   },
	 "Alice":{
		  "keyring":{
			 "ecdh":"AxLMXkey00i2BD675vpMQ8WhP/CwEfmdRr+BtpuJ2rM="
		  }
	   }
   
   
   
}
```

We could try using the following script:


```gherkin
Scenario 'ecdh': let us load some stuff cause it is fun!
Given I am 'Alice'
And I have my 'keyring'
And I have a 'string array' named 'myStringArray' inside 'myFirstObject' 
#
# # # Uncomment the line below to enjoy the fireworks
# And I have a 'string array' named 'myStringArray' inside 'mySecondObject' 
Then print all data
```

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


## Numbers in complex objects

When loading a complex objects, say a ***string dictionary***, that contains a ***number***, a fuzzy logic is applied to the dictionary. Let see it with an example.
Suppose to have the following data:

```json
{
    "dictionary": {
        "str": "hello world!",
        "num": 12345678910,
        "time": 1702474699
    }
}
```

and to load the dictionary as in the following script:

```gherkin
Given I have the 'string dictionary' named 'dictionary'
Then print all data
```

the reuslt will be:

```
{"dictionary":{"num":1.234568e+10,"str":"hello world!","time":1702474699}}
```

This happens because when Zenroom encounters a number during the loading phase does not look at the encoding specified in the statement, but it import it as a ***float*** or a ***time*** data type.
By deafult it will import numbers that are integers in the range from 1500000000 (included) to 2000000000 (not included) as ***time***, while all the others as ***floats***.

Be careful, ***time*** and ***floats*** data type are not comparable and the only operations that can be done between two ***time*** variables are comparison (equal, less then, more than and not equal).

To avoid importing ***floats*** as ***time*** you can use [Rule input number strict](/pages/zencode-rules.md?id=rule-input-number-strict).


<!-- Temp removed, 

 
# Comprehensive list of *Given* statements

Let's use an even larger object this time, named *myLargeNestedObject.json*: 

```json
{
   "myFirstObject":{
      "myFirstNumber":1.23456,
	  "myFirstString":"Hello World!",
      "myFirstHex": "616e7976616c7565",
      "myFirstBase64": "SGVsbG8gV29ybGQh",
	  "myFirstUrl64": "SGVsbG8gV29ybGQh",
	  "myFirstBinary": "0100100001101001",
	  "myFirstArray":[
         "String1",
		 "String2"
      ]
   },
   "mySecondObject":{
      "mySecondNumber":2,
      "mySecondArray":[
         "anotherString1",
         "anotherString2"
      ]
   },
   "myThirdObject":{
      "myThirdNumber":3,
      "myThirdArray":[
         "oneMoreString1",
         "oneMoreString2",
         "oneMoreString3"
      ]
   },
   "myFourthObject":{
      "myFourthArray":[
         "oneExtraString1",
         "oneExtraString2",
         "oneExtraString3",
		 "oneExtraString4"
      ]
   }
}
```

Below is a list of most of the *Given* statements you will need to load data in Zenroom:

```gherkin
# Load Arrays
Given I have a 'string array' named 'myFirstArray' inside 'myFirstObject' 
# Remember that you can load arrays of other types, just 
# like writing the encoding before the word array, for example 
# you could load a 'number array' or 'base64 array'
# 
# Load Numbers
Given I have a 'number' named 'mySecondNumber' inside 'mySecondObject'
# Load Strings
Given I have a 'string' named 'myFirstString' inside 'myFirstObject' 
# Different data types
Given I have an 'hex' named 'myFirstHex' inside 'myFirstObject' 
Given I have a  'base64' named 'myFirstBase64' inside 'myFirstObject' 
Given I have a  'binary' named 'myFirstBinary' inside 'myFirstObject' 
Given I have an 'url64' named 'myFirstUrl64' inside 'myFirstObject' 
Then print all data
```
-->

# The script used to create the material in this page

All the smart contracts and the data you see in this page are generated by the script [cookbook_given.sh](https://github.com/dyne/Zenroom/blob/master/test/zencode/cookbook_given.bats) and [cookbook_dictionaries.sh](https://github.com/dyne/Zenroom/blob/master/test/zencode/cookbook_dictionaries.bats) If you want to run the script (on Linux) you should: 
 - *git clone https://github.com/dyne/Zenroom.git*
 - install  **jq**
 - download a [zenroom binary](https://zenroom.org/#downloads) and place it */bin* or */usr/bin* or in *./Zenroom/src*


<!-- Unused files
 
givenDebugOutputVerbose.json
givenLongOutput.json
 

Link file with relative path: <a href="./_media/examples/zencode_cookbook/givenArraysLoadInput.json">givenArraysLoadInput.json</a>
 
-->




# The *When* statements: all operations with data

The *When* keyword introduces the phase of Zencode execution, where data can be manipulated. The statemens executed in this phase allow you to: 
 - Manipulate objects: rename, append, cut, insert, remove, etc.
 - Create objects: different schemas can be created in different ways (including random objects), and values assigned to them.
 - Execute cryptography: this is where all the crypto-magic happens: creating keyring, hashing points...
 - Comparisons: compare value of numbers, strings and complex objects.
 
## First, let's get a nice JSON 
 
We've done this already: let's start with create a file named *myLargeNestedObjectWhen.json*. This file contains everything we need for every part of this chapter and - along  with the *Given* part of the script, you can use this JSON to later make your own experiments with Zencode.

```json
{
  "myFirstObject": {
    "myFirstNumber": 1.2345,
    "myFirstString": "Hello World!",
    "myFirstHex": "616e7976616c7565",
    "myFirstBase64": "SGVsbG8gV29ybGQh",
    "myFirstUrl64": "SGVsbG8gV29ybGQh",
    "myFirstBinary": "0100100001101001",
    "myFirstArray": [
      "Hello World! myFirstObject, myFirstArray[0]",
      "Hello World! myFirstObject, myFirstArray[1]",
      "Hello World! myFirstObject, myFirstArray[2]"
    ],
    "myFirstNumberArray": [
      10,
      20,
      30,
      40,
      50
    ],
    "myOnlyEcpArray": [
      "Awz+ogtsf9xRn7hIw/6B1xvwoBNRgNFJOPYqSdPd+OAHXgDVuLWuKEvIsynbdWBJIw==",
      "A05tQgcTdT7+OAvfWZMIYI9G2owWBBR3/KqRBL/KPh2rPknbW1FBbRcee3P+7hpOoQ==",
      "AzijxD9GRztPcRtEXjdpXIPTzzmv0dvCdQNcmToC09pOw1ZLg/eAHdgEFV6oWhionQ==",
      "Ak8k6etvJjUPfSTFZFtQiRKaX1gIs3lUMzti+BQZW1XhUl8OOAOa/LrCRWyV1fpLwg=="
    ],
    "myOnlyEcp2Array": [
      "QTQcWNiZgxQSyk7z0Zuy7GSF7kfrvahtaKFfgWsQeZurOpSSEiA81amccUi6S0LEIozhraN8aL+S8X7cPoqg7s1ftnC/S/MH3kwRwJ0jscACVvf+1Y/XEtngBZ0g1frPBNe6CVuaoQiXuda0g5t4mZzItGt6hgtsn7f/iHyO+Iwe1+9vUEzfysxNmFVjEq8ADEeFLqnltHbrI2H3vVZTc5g5IWxAJF00wE7n0kKb4AF59bqxbBN62dIqmVEodMDH",
      "Anq3ieAxAEGfNzzQYUuQD1NPZuaojS6Fd3/nr3GFKqTPJmdEFTYamiGAN5nN5N5mMBMxE2sub/I39sqFKjDF22Iu/jZWsT+grD5E3PDuiaR4Ugr7V/WOdY3iiY5tfZm4AlWiNYSVR3KIcZe81E5q/GucEvAeC0VuGDgrTvTZ3/e7qxSxsi6aoqlLl2dD3AjABVQHfdY0BZ4gL1xYCmF7TYPs6LNeVb1+9buFZk3I7mskgGjrzgdKgm7IH3rL3Hsl",
      "SQn5DHPbQTPmxfQirsxZ28uJu6PKv54UDXUzAqqUliAmc52+yFhwgeJpBWwpGfUPP04m8eNUo0hIO3EA2MKDaVxc78HS4PM2nm8ngyX/fTcg1WheaNIkrF4yycGeIEByB3NsYm36CvrJmfKQMtbON0yMpjD6vTfG6C82xaF+vRSieXgXDqh0e3e0deWkWo2vAQht5aqMDX0hGub01gk6tv/IeboIfr3fva80g4XPoiyfI23VZpRP65LdjnAS1seQ",
      "FcLlzyRlrLBCQAEKs6d+WCtV4awcogoGiGlWKStiuPR+1ms4ZBGKmwW+bniPcAQ3PEUqLBsy+SGmWA0IdkeGRyoJA/gsjZFYr8s8L5ZBd+zIk6ycjuK1fINyfXif3efmR0K2gjSQvptlzmggTr0SLoA3qO1vRZ2ZjPJLa4ehyhZaqx3rxqNWSxK/WzviPHfsAnYQVIOmJGsMl8lGpaJdHWh7XiMDUqJLu2B9OfE4O4pTE8eARR10oSaaNovDzkF+"
    ],
    "myNestedArray": [
      [
        "hello World! myFirstObject, myNestedArray[0][0]",
        "hello World! myFirstObject, myNestedArray[0][1]"
      ],
      [
        "hello World! myFirstObject, myNestedArray[1][0]"
      ]
    ],
    "myNestedDictionary": {
      "1": {
        "1-first": "hello World!  myFirstObject, 1-first",
        "1-second": "hello World!  myFirstObject, 1-second"
      },
      "2": {
        "2-first": "hello World!  myFirstObject, 2-first"
      }
    }
  },
  "mySecondObject": {
    "mySecondNumber": 2,
    "mySecondString": "...and hi everybody!",
    "mySecondArray": [
      "anotherString1",
      "anotherString2"
    ]
  },
  "myThirdObject": {
    "myThirdNumber": 3,
    "myThirdString": "...and good morning!",
    "myThirdArray": [
      "Hello World! myThirdObject, myThirdArray[0]",
      "Hello World! myThirdObject, myThirdArray[1]",
      "Hello World! myThirdObject, myThirdArray[2]",
      "Hello World! myThirdObject, myThirdArray[3]"
    ],
    "myCopyOfFirstArray": [
      "Hello World!, myThirdObject, myCopyOfFirstArray[0]",
      "Hello World!, myThirdObject, myCopyOfFirstArray[1]",
      "Hello World!, myThirdObject, myCopyOfFirstArray[2]"
    ]
  },
  "myFourthObject": {
    "myFourthArray": [
      "Hello World! inside myFourthObject, inside myFourthArray[0]",
      "Hello World! inside myFourthObject, inside myFourthArray[1]",
      "Will this string be found inside an array?",
      "Hello World! inside myFourthObject, inside myFourthArray[2]",
      "Hello World! inside myFourthObject, inside myFourthArray[3]",
      "Will this string be found inside an array at least 3 times?",
      "Will this string be found inside an array at least 3 times?",
      "Will this string be found inside an array at least 3 times?"
    ],
    "myFourthString": "...and good evening!",
    "myFifthString": "We have run out of greetings.",
    "mySixthString": "So instead we'll tell the days of the week...",
    "mySeventhString": "...Monday,",
    "myEightEqualString": "These string is equal to another one.",
    "myNinthEqualString": "These string is equal to another one.",
    "myFourthNumber": 3,
    "myTenthString": "Will this string be found inside an array?",
    "myEleventhStringToBeHashed": "hash me to kdf",
    "myTwelfthStringToBeHashedUsingPBKDF2": "hash me to pbkdf2",
    "myThirteenStringPassword": "my funky password",
    "myFourteenthStringToBeHashedUsingHMAC": "hash me to HMAC",
    "myFifteenthString": "Hello World again!",
    "mySixteenthString": "Hello World! myThirdObject, myThirdArray[2]",
    "mySeventeenthString":"Will this string be found inside an array at least 3 times?",
    "myOnlyBIGArray": [
      "7dcd7392a9dea33b145a03279af78b1adf1c0549f5121ec28dd3dc136c0ca693",
      "8bd877e84538380c455448239f04d817e9657ecf2786442f11c98248ca8178a2",
      "d2cfc1b31b087d0d7137e3f5d45fc6a9cf33025fdba6f9cad40a04e36b420763",
      "554e2fcf3a4a1d872446febb81a91d910e772a4cf4c5e36a3569b159cb5ff439"
    ]
  },
  "myUserName": "User1234",
  "User1234": {
    "keyring": {
      "ecdh": "AxLMXkey00i2BD675vpMQ8WhP/CwEfmdRr+BtpuJ2rM="
    }
  },
  "ABC-Transactions1Data": {
    "timestamp": 1597573139,
    "TransactionValue": 1000,
    "PricePerKG": 2,
    "TransferredProductAmount": 500,
    "UndeliveredProductAmount": 100,
    "ProductPurchasePrice": 1
  },
  "mySecondNumberArray": [
    567,
    748,
    907,
    876,
    34,
    760,
    935
  ]
}
```

 

### Loading the content of the JSON 

Since the *When* phase contains many statements, we did split the scripts in four parts. The part of script that loads the JSON can be used for all the scripts below.


```gherkin
# We're using scenario 'ecdh' cause we are loading a keypair
Scenario 'ecdh': using keypair and signing
Given my name is in a 'string' named 'myUserName'
Given that I have my 'keyring'
# Load Arrays
Given I have a 'string array' named 'myFirstArray'  inside 'myFirstObject'
Given I have a 'string array' named 'myNestedArray' inside 'myFirstObject'
Given I have a 'string array' named 'mySecondArray' inside 'mySecondObject'
Given I have a 'string array' named 'myThirdArray' inside 'myThirdObject' 
Given I have a 'string array' named 'myFourthArray' inside 'myFourthObject'
Given I have a 'number array' named 'myFirstNumberArray' inside 'myFirstObject'
Given I have a 'string array' named 'myCopyOfFirstArray' inside 'myThirdObject'
Given I have a 'base64 array' named 'myOnlyEcpArray' inside 'myFirstObject'
Given I have a 'base64 array' named 'myOnlyEcp2Array' inside 'myFirstObject'
Given I have a 'number array' named 'mySecondNumberArray'

# Load Numbers
Given I have a 'number' named 'myFirstNumber' in 'myFirstObject'
Given I have a 'number' named 'mySecondNumber' in 'mySecondObject'
Given I have a 'number' named 'myFourthNumber' inside 'myFourthObject'
Given I have a 'number' named 'myThirdNumber' inside 'myThirdObject' 
# Load Strings
Given I have a 'string' named 'myFirstString' in 'myFirstObject'
Given I have a 'string' named 'mySecondString' inside 'mySecondObject'
Given I have a 'string' named 'myThirdString' inside 'myThirdObject' 
Given I have a 'string' named 'myFourthString' inside 'myFourthObject'
Given I have a 'string' named 'myFifthString' inside 'myFourthObject'
Given I have a 'string' named 'mySixthString' inside 'myFourthObject'
Given I have a 'string' named 'mySeventhString' inside 'myFourthObject'
Given I have a 'string' named 'myNinthEqualString' inside 'myFourthObject'
Given I have a 'string' named 'myEightEqualString' inside 'myFourthObject'
Given I have a 'string' named 'myTenthString' inside 'myFourthObject'
Given I have a 'string' named 'myEleventhStringToBeHashed' inside 'myFourthObject'
Given I have a 'string' named 'myTwelfthStringToBeHashedUsingPBKDF2' inside 'myFourthObject' 
Given I have a 'string' named 'myThirteenStringPassword' inside 'myFourthObject'
Given I have a 'string' named 'myFourteenthStringToBeHashedUsingHMAC' inside 'myFourthObject'
Given I have a 'string' named 'myFifteenthString' inside 'myFourthObject'
Given I have a 'string' named 'mySixteenthString' inside 'myFourthObject'
Given I have a 'string' named 'mySeventeenthString' inside 'myFourthObject'
# Load dictionaries
Given I have a 'string dictionary' named 'myNestedDictionary' inside 'myFirstObject'
Given I have a 'string dictionary' named 'ABC-Transactions1Data'
# Different data types
Given I have an 'hex' named 'myFirstHex' inside 'myFirstObject' 
Given I have a  'base64' named 'myFirstBase64' in 'myFirstObject'
Given I have a  'binary' named 'myFirstBinary' in 'myFirstObject'
Given I have an 'url64' named 'myFirstUrl64' in 'myFirstObject'
# Here we're done loading stuff 
```



## Manipulation: sum/subtract, rename, remove, append... 

We grouped together all the statements that perform object manipulation, so: 


 ***Math operations***: sum, subtraction, multiplication, division and modulo, between numbers
 
 ***Invert sign*** invert the sign of a number 
 
 ***Append*** a simple object to another
 
 ***Rename*** an object
  
 ***Delete*** an object from the memory stack
 
 ***Copy*** an object into new object
 
 ***Split string*** using leftmost or rightmost bytes
 
 ***Randomize*** the elements of an array
 
 ***Create string/number*** (statement "write in")
 
 ***Pick a random element*** from an array

 ***Create random dictionary*** from another dictionary

 ***Create flat array*** of contents or keys of a dictionary or an array
 
 
In the script below, we've put together a list of this statement and explained in the comments how each statement works: 
 

```gherkin
# WRITE IN (create string or number)
# the "write in" statement create a new object, assigns it an encoding but 
# only "number" or "string" (if you need any other encoding, 
# use the "set as" statement) and assigns it the value you define.
When I write number '10' in 'nameOfFirstNewVariable'
When I write string 'This is my lovely new string!' in 'nameOfSecondNewVariable'


# SUM, SUBTRACTION
# You can use the statement 'When I create the result of ... " to 
# sum, subtract, multiply, divide, modulo with values, see the examples below. The output of the 
# statement will be an object named "result" that we immediately rename.
# The operators allowed are: +, -, *, /, %.
When I create the result of 'mySecondNumber' + 'myThirdNumber'
and I rename the 'result' to 'resultOfmyFirstSum'
When I create the result of 'mySecondNumber' - 'myThirdNumber'
and I rename the 'result' to 'resultOfmyFirstSubtraction'
When I create the result of 'mySecondNumber' * 'myThirdNumber'
and I rename the 'result' to 'resultOfmyFirstMultiplication'
When I create the result of 'mySecondNumber' / 'myThirdNumber'
and I rename the 'result' to 'resultOfmyFirstDivision'
When I create the result of 'mySecondNumber' % 'myThirdNumber'
and I rename the 'result' to 'resultOfmyFirstModulo'

# Now let's do some math with the number that we just created: 

When I create the result of 'mySecondNumber' + 'nameOfFirstNewVariable'
and I rename the 'result' to 'resultOfmySecondSum'
When I create the result of 'mySecondNumber' * 'nameOfFirstNewVariable'
and I rename the 'result' to 'resultOfmySecondMultiplication'

# INVERT SIGN
# you can invert the sign of a number using this statement
# in this example, we create an inverted version of 'myFirstNumber' 
# that goes from '1.2345' to '-1.2345'
When I create the result of 'myFirstNumber' inverted sign
and I rename the 'result' to 'myFirstNumberInvertedSign'


# APPEND
# The "append" statement are pretty self-explaining: 
# append a simple object of any encoding to another one
When I append 'mySecondString' to 'myFifteenthString' 
When I append 'mySecondNumber' to 'myThirdNumber' 

# RENAME
# The "rename" statement: we've been hinting at this for a while now,
# pretty self-explaining, it works with any object type or schema.
When I rename the 'myThirdArray' to 'myJustRenamedArray'

# DELETE
# You can delete an object from the memory stack at runtime
# this is useful if, for example, you have copied an object to perform an operation
# and you don't need the copy anymore
When I delete 'myFourthNumber'

# COPY
# You can copy a an object into a new one
# it works for simple objects (number, string, etc) or complex
# ones (arrays, dictionaries, schemes)
When I copy 'mySixteenthString' to 'copyOfMySixteenthString'
When I copy 'myFirstArray' to 'copyOfMyFirstArray'

# You can copy a certain element from an array, to a new object named "copy", with the
# same encoding of the array, in the root level of the data. 
# We are immeediately renaming the outout for your convenience.
When I create the copy of element '3' from array 'myFourthArray'
and I rename the 'copy' to 'copyOfElement3OfmyFourthArray'

# SPLIT (leftmost, rightmost)
# The "split" statements, take as input the name of a string and a numeric value,
# the statement removes the leftmost/outmost characters from the string 
# and places the result in a newly created string called "leftmost" or "rightmost"
# which we immediately rename
When I split the leftmost '4' bytes of 'mySecondString'
And I rename the 'leftmost' to 'myFirstStringLeftmost'
When I split the rightmost '6' bytes of 'myThirdString'
And I rename the 'rightmost' to 'myThirdStringRightmost'

# RANDOMIZE
# The "randomize" statements takes the name of an array as input and shuffles it. 
When I randomize the 'myFourthArray' array


# PICK RANDOM
# The "pick a random object in" picks randomly an object from the target array
# and puts into a newly created object named "random_object".
# The name is hardcoded, the object can be renamed.
When I pick the random object in 'myFirstArray'
and I rename the 'random_object' to 'myRandomlyPickedObject'

# CREATE RANDOM DICTIONARY 
# If you need several objects from a dictionary, you can use this statement
# it will create a new dictionary with the defined amount of objects,
# picked from the original dictionary 
When I create the random dictionary with 'mySecondNumber' random objects from 'myOnlyEcpArray'
and I rename the 'random_dictionary' to 'myNewlyCreatedRandomDictionary'

# CREATE FLAT ARRAY
# The "flat array" statement, take as input the name of an array or a dictionary,
# the statement flat the input contents or the input keys
# and places the result in a newly created array called "flat array"
When I create the flat array of contents in 'myNestedArray'
and I rename the 'flat array' to 'myFlatArray'
When I create the flat array of contents in 'myNestedDictionary'
and I rename the 'flat array' to 'myFlatDictionaryContents'
When I create the flat array of keys in 'myNestedDictionary'
and I rename the 'flat array' to 'myFlatDictionaryKeys'

Then print all data
```


To play with the script, first save it into the file *whenCompleteScriptPart1.zen*. Then run it while loading the data, using the command line:

```bash
zenroom -a myLargeNestedObjectWhen.json -z whenCompleteScriptPart1.zen | jq | tee whenCompleteOutputPart1.json
``` 

The output should look like <a href="../_media/examples/zencode_cookbook/cookbook_when/whenCompleteOutputPart1.json" download>whenCompleteOutputPart1.json</a>. Remember that the output gets sorted alphabetically, because in Zenroom *determinism is King*.

## Create the "(name of schema)"

Let's have a look at at the statement "Create", first focusing to a special use case.

The statement *Create the* works only to create different both **simple objects** as well as **schemas**, which are particular objects, whose names and structures are predefined.

in *Zencode*, *the* is a keyword indicating that a **schema** is about to be created. In case a **schema** created by the statement, its structure will matche the word(s) following the keyword "the", and the name of object created will also be the same.

A general version of the statement looks like this: 

```gherkin
When I create the <name of the schema>
``` 

Some schemas need no **scenario** to work, and those are all listed on this page. Other schemas are typically described in the manual pages of the scenarios they belong to. Some examples are: 

A statement we have use extensively already from the scenario 'ecdh'
```gherkin
When I create the ecdh key
``` 

We'll look at two way to generate keyring (from a random or from a known seed in the next chapter).

As you probably know by now, this statement outputs something looking like this: 

```json
{    "keyring": {
      "ecdh": "AxLMXkey00i2BD675vpMQ8WhP/CwEfmdRr+BtpuJ2rM="
    }
  }
``` 


Another examples of the statement, from the scenario 'credential':

```gherkin
When I create the credential key
``` 

An example, from the scenario 'petition':

```gherkin
When I create the petition signature 'nameOfThePetitionIWantToSign'
``` 

A statement is available also to transform a binary object to a JSON string: 

```gherkin
When I create the escaped string of 'myObject'
``` 

We're sparing you the full list of **schemas** that you can create, but the best place to see a full and updated list is <a href="https://apiroom.net">https://apiroom.net</a>. 


## Create regular or random objects and render them

In the second group we gathered the *When* statements that can create new objects and assign values to them.

 The "create" statements can ***generate random numbers*** (or arrays thereof), with different parameters.

 The "set" statements allow you to ***create an object and assign a value to it***. 
 
 The "create the create the escaped string of" statement allows you ***render an object to a JSON string***, which at the end can be printed as a string and is internal to the main JSON output returned by Zencode: it is a JSON string inside a JSON dictionary value.
 
 A special case is the stament "create key", which we see in two flavours, one ***creates a key from a random seed***, one ***from a known seed***.
 

 See our example script below: 
 

```gherkin
# CREATE RANDOM
# The "create random" creates a random object with a default set of parameters
# The name of the generate objected is defined between the ' '  
# The parameters can be modified by passing them to Zenroom as configuration file
When I create the random 'newRandomObject'

# Below is a variation that lets you create a random number of configurable length.
# This statement doesn't let you choose the name of the name of the newly created object,
# which is hardcoded to "random_object". We are immediately renaming it.
When I create the random object of '128' bits
and I rename the 'random_object' to 'my128BitsRandom'
When I create the random object of '16' bytes
and I rename the 'random_object' to 'my16BytesRandom'

# The "create array of random" statement, lets you create an array of random objects, 
# and you can select the length in bits. The first statement uses the default lenght of 512 bits.
# Like the previous one, this statement outputs an object whose name is hardcoded into "array".
# Since we're creating three arrays called "array" below, Zenroom would simply overwrite 
# the first two, so we are renaming the output immediately. 
When I create the array of '4' random objects
and I rename the 'array' to 'my4RandomObjectsArray'
When I create the array of '5' random objects of '256' bits
and I rename the 'array' to 'my256BitsRandomObjectsArray'
When I create the array of '6' random objects of '16' bytes
and I rename the 'array' to 'my16BytesRandomObjectsArray'

# You can generate an array of random numbers, from 0 o 65355, with this statement.
When I create the array of '10' random numbers 
and I rename the 'array' to 'my10RandomNumbersArray'
# A variation of the statement above, allows you to use the "modulo" function to cap the max value
# of the random numbers. In the example below, the max value will be "999".
When I create the array of '16' random numbers modulo '1000'
and I rename the 'array' to 'my16RandomNumbersModulo1000Array'

# SET
# The 'set' statement creates a new variable and assign it a value.
# Overwriting variables discouraged in Zenroom: if you try to overwrite an existing variable, 
# you will get an error, that you can override the error using a rule 
# in the beginning of the script.
# The 'set' statement can generate different kind of schemas, as well as to create variables 
# containing numbers in different bases. 
# When working with strings, remember that spaces are converted to underscores.
When I set 'myNewlyCreatedString' to 'call me The Pink Panther!' as 'string'
When I set 'myNewlyCreatedBase64' to 'SGVsbG8gV29ybGQh' as 'base64'
When I set 'myNewlytCreatedNumber' to '42' as 'number'
When I set 'myNewlyCreatedNumberInBaseSomething' to '42' base '16'

# CREATE KEYRING
# Keys inside keyrings can be created from a random seed or from a known seed

# Below is the standard keyring generation statement, which uses a random seed
# The random seed can in fact be passed to Zenroom and last for the whole 
# smart contract execution session, via the "config" parameter. 
# Note that, in order to create a keyring, you'll need to declare the identity of the script
# executor, which is done in the Given phase

# Note: we're renaming the created keyrings exclusively cause we're generating 2 keyringss 
# in the same script, so the second would overwrite the first. In reality you never want to 
# rename a keyring, as its schema is hardcoded in Zenroom and cryptographically it doesn't make sense
# to use more than one keyring in the same script.
When I rename the 'keyring' to 'GivenKeyring'
When I create the ecdh key
and I rename the 'keyring' to 'keyringFromRandom'

# Below is a statement to create a keyring from a known seed.
# The seed has to be passed to Zenroom via a string, that can have an arbitrary size
When I create the ecdh key with secret 'myThirteenStringPassword'
and I rename the 'keyring' to 'keyringFromSeed'

Then print all data
```



The output should look like <a href="../_media/examples/zencode_cookbook/cookbook_when/whenCompleteOutputPart2.json" download>whenCompleteOutputPart2.json</a>.



## Basic cryptography: hashing

Here we have grouped together the statements that perform: 


 ***Basic hashing***

```
When I create the hash of 'source' using 'sha512'
```

Works with any source data named as first argument and one of the hashing algorithms supported. At the time of writing they are:
- the default SHA2 `sha256` (32 bytes long)
- and the SHA2 `sha512` (64 bytes long)
- the new SHA3 class `sha3_256` (32 bytes)
- the new SHA3 class `sha3_512` (64 bytes)
- the SHA3 class `shake256` (also 32 bytes)
- the SHA3 class `keccak256` used in Ethereum

 ***Multihash encoded hash***
 
If needed it can be easy to encode hashed results in Zencode using [Multihash](https://multiformats.io/multihash/). Just use a similar statement:
```
When I create the multihash of 'source' using 'sha512'
```

This way the multihash content will be usable in its pure binary form while being in the `When` phase, but will be printed out in multihash format by the `Then` phase.

 ***Key derivation function (KDF)***
 
 ***Password-Based Key Derivation Function (pbKDF)***
 
 ***Hash-based message authentication code (HMAC)***
 
 ***Aggregation of ECP or ECP2 points***

Hashing works for any data type, so you can hash simple objects (strings, numbers etc.) as well as hashes and dictionaries.

Keep in mind that in order to use more advanced cryptography like encryption, zero knowledge proof, zk-SNARKS, attributed based credential or the [Credential](https://dev.zenroom.org/#/pages/zencode-scenario-credentials) flow you will need to select a *scenario* in the beginning of the scripts. We'll write more about scenarios later, for now we're using the "ecdh" scenario as we're loading an ecdh key from the JSON. See our example below:




```gherkin
# HASH

# Output objects: as overwriting variables is discouraged in Zenroom, all the hashing
# and cryptography statements will output a new object with a hardcoded name, listed
# along with the statement. It's a good practice to rename the object immediately after
# its creation, both to make it more readable and as well to avoid overwriting in case you
# are using a statement with similar output more than once in the same script.

# The "create hash" statement hashes a string, but it does not hash an array!
# The default algorythm for the hash can be modified by passing them to Zenroom as config file. 
# Note that the object produced, containing the hashing of the string, will be named "hash", 
# which we promptly rename. The same is true for the two following statements.
When I create the hash of 'myFifthString'
And I rename the 'hash' to 'hashOfMyFifthString'

# In the same fashion, we can hash arrays 
When I create the hash of 'myFirstArray'
And I rename the 'hash' to 'hashOf:MyFirstArray'

# or we can hash every element in the array
When I create the hashes of each object in 'myFirstArray'
And I rename the 'hashes' to 'hashOf:ObjectsInMyFirstArray'

# and we can as well hash dictionaries
When I create the hash of 'ABC-Transactions1Data'
And I rename the 'hash' to 'hashOfDictionary:ABC-Transactions1Data'

# Following is a version of the statement above that takes the hashing algorythm as parameter, 
# it accepts sha256 or sha512 as hash types
When I create the hash of 'mySixthString' using 'sha256'
And I rename the 'hash' to 'hashOfMySixthString'
When I create the hash of 'mySeventhString' using 'sha512'
And I rename the 'hash' to 'hashOfMySeventhString'

# Again, you can hash with sha256 or sha512 also arrays and dictionaries
When I create the hash of 'myFirstArray' using 'sha512'
And I rename the 'hash' to 'sha512HashOf:MyFirstArray'

When I create the hash of 'ABC-Transactions1Data' using 'sha512'
And I rename the 'hash' to 'sha512HashOfDictionary:ABC-Transactions1Data'

# Key derivation function (KDF)
# The output object is named "key_derivation":
When I create the key derivation of 'myEleventhStringToBeHashed'
And I rename the 'key_derivation' to 'kdfOfMyEleventhString'

# Password-Based Key Derivation Function (pbKDF) hashing, 
# this also outputs an object named "key_derivation":
When I create the key derivation of 'myTwelfthStringToBeHashedUsingPBKDF2' with password 'myThirteenStringPassword'
And I rename the 'key_derivation' to 'pbkdf2OfmyTwelfthString'

# Hash-based message authentication code (HMAC)
When I create the HMAC of 'myFourteenthStringToBeHashedUsingHMAC' with key 'myThirteenStringPassword'
And I rename the 'HMAC' to 'hmacOfMyFourteenthString'

# AGGREGATE
# The "create the aggregation" statement takes as input an array of numers
# and sums then it into a new object called "aggregation" that we'll rename immediately.
# It works on both arrays and dictionaries, the data type needs to be 
# specified as in the example.
When I create the aggregation of array 'myFirstNumberArray'
And I rename the 'aggregation' to 'aggregationOfMyFirstNumberArray'

# Now let's print out everything
Then print all data
```



The output should look like this: <a href="../_media/examples/zencode_cookbook/cookbook_When/whenCompleteOutputPart3.json" download>whenCompleteOutputPart3.json</a>.




## Comparing strings, numbers, arrays 

This group includes all the statements to compare objects, you can:


 ***Compare*** if objects (strings, numbers or arrays) are equal
 
 See if a ***number is more, less or equal*** to another 
 
 See ***if an array contains an element*** of a given value.


See our script below:


```gherkin
# VERIFY EQUAL
# The "verify equal" statement checks that the value of two ojects is equal.
# It works with simple objects of any encoding.
When I verify 'myEightEqualString' is equal to 'myNinthEqualString'         
When I verify 'myThirdNumber' is equal to 'myFourthNumber'

# LESS, MORE, EQUAL
# Number comparisons: those are pretty self explaining.
When I verify number 'myFourthNumber' is less or equal than 'myThirdNumber'
When I verify number 'myFirstNumber' is less than  'myThirdNumber'
When I verify number 'myThirdNumber' is more or equal than 'mySecondNumber'
When I verify number 'myThirdNumber' is more than 'mySecondNumber'

# FOUND, NOT FOUND, FOUND AT LEAST n TIMES
# The "is found" statement, takes two objects as input: 
# the name of a variable and the name of an array. It reads its content of the variable 
# and matches it against each element of the array.
# It works with any kind of array, as long as the element of the array are of the same schema
# as the variable.
When I verify the 'myTenthString' is found in 'myFourthArray'
When I verify the 'myFirstString' is not found in 'myFourthArray'
When I verify the 'mySeventeenthString' is found in 'myFourthArray' at least 'myFourthNumber' times
Then print all data
```



The output should look like 
<a href="../_media/examples/zencode_cookbook/cookbook_when/whenCompleteOutputPart4.json" download>whenCompleteOutputPart4.json</a>. 


## Operations with arrays

Here are the statements to work with arrays. Arrays can be of any type (number, string, base64... etc). The statements can do 

***Insert*** a simple object into an array

***Length*** creates an object containing the array length
 
***Sum*** creates the arithmetic sum of a 'number array'

***Average***  creates the average of a 'number array'

***Standard deviation***  creates the standard deviation of a 'number array'

***Variance***  creates the variance of a 'number array'
 
***Copy element of array*** to a new simple object

***Remove*** an element from an array



See our script below:


```gherkin
# CREATE
# These creates a new empty array named 'array'
When I create the new array

# MOVE
# The "move" statement is used to append a simple object to an array.
# It's pretty self-explaining. 
When I move 'myFirstString' in 'myFirstArray'

# SIZE
# These two statements create objects, named "size"
# containing the size of the array
When I create the size of 'mySecondNumberArray'

# SUM 
# These two statements create objects, named "aggregation" and "sum value" containing the 
# arithmetic sum of the array, they work only with "number array"
When I create the aggregation of array 'mySecondNumberArray'
When I create the sum value of elements in array 'mySecondNumberArray'

# STATISTICAL INFORMATIONS
# These statements perform some statistical operations on the arrays
# These statements compute the average, the standard deviation and the
# variance of the elements of the array, saving them in three object named
# respectively "average", "standard deviation" and "variance", and
# they work only with "number array"
When I create the average of elements in array 'mySecondNumberArray'
When I create the standard deviation of elements in array 'mySecondNumberArray'
When I create the variance of elements in array 'mySecondNumberArray'

# COPY ELEMENT
# This statement creates a an object named "copy" containing
# the given element of the array
When I create the copy of element '2' from array 'mySecondNumberArray'

# REMOVE
# The "remove" statement does the opposite of the one above:
# Use it remove an element from an array, it takes as input the name of a string, 
# and the name of an array - we don't mix code and data! 
When I rename the 'myThirdArray' to 'myJustRenamedArray'
When I remove the 'mySixteenthString' from 'myJustRenamedArray'

Then print the 'mySecondNumberArray'
Then print the 'myFirstArray'
Then print the 'myJustRenamedArray'

Then print the 'size'

Then print the 'aggregation'
Then print the 'sum value'

Then print the 'average'
Then print the 'standard deviation'
Then print the 'variance'

Then print the 'copy'

```



The output should look like 
<a href="../_media/examples/zencode_cookbook/cookbook_when/whenCompleteOutputPart5.json" download>whenCompleteOutputPart5.json</a>. 


## Operations with dictionaries

The last group includes all the statements that are exclusive to ***dictionary*** objects. A dictionary is a ***complex object*** that can be nested under another dictionary to create a ***list*** (that is still referred to as dictionary). Dictionaries can have ***different internal structure***. You can use dictionaries for examples when you have a list of transactions, a list of accounts, a list of data entries.

Operations with dictionaries allow you to:



***Find maximum and minimum***: compare the homonym elements in each dictionary, and find the one with the highest/lowest value. 

***Sum*** and ***Conditioned sum***: sum homonym elements in each dictionary, you can also add homonym elements in each dictionary only if a certain element in that dictionary is higher/lower than a certain value. 

***Find dictionaries containing an element of a certain value***: match homonym elements in each dictionary with a certain value, and return all those that match (the statement returns an array). 

***Find dictionary in list***: browse the list of see if a dictionary name matches or not a certain string.

***Create a dictionary***: create a dictionary on the fly, using values computed in the script and insert elements into it.

***Copy a dictionary or element***: copy a dictionary that is nested into another dictionary or copy an element to the root level of the data, to manipulate it more easily.

***Math operations***: sum, subtraction, multiplication, division and modulo, between numbers found in dictionaries and numbers loaded individiually.

***Prune***: remove all the empty strings ("") and the empty dictionaries (dictionaries that contain only empty strings).


In the script we'll use as example we'll load a complex dataset, containing dictionaries that mimic records of transactions. Note that the dictionaries do not always have the same exact structure:

```json
{
   "TransactionsBatchB":{
      "Information":{
         "Metadata":"TransactionsBatchB6789",
         "Buyer":"John Doe"
      },
      "ABC-Transactions1Data":{
         "timestamp":1597573139,
         "TransactionValue":1000,
         "PricePerKG":2,
         "TransferredProductAmount":500,
         "UndeliveredProductAmount":100,
         "ProductPurchasePrice":1
      },
      "ABC-Transactions2Data":{
         "timestamp":1597573239,
         "TransactionValue":1000,
         "PricePerKG":2
      },
      "ABC-Transactions3Data":{
         "timestamp":1597573339,
         "TransactionValue":1000,
         "PricePerKG":2,
         "TransferredProductAmount":500
      },
      "ABC-Transactions4Data":{
         "timestamp":1597573439,
         "TransactionValue":2000,
         "PricePerKG":4,
         "TransferredProductAmount":500
      },
      "ABC-Transactions5Data":{
         "timestamp":1597573539,
         "TransactionValue":2000,
         "PricePerKG":4,
         "TransferredProductAmount":500
      },
      "ABC-Transactions6Data":{
         "timestamp":1597573639,
         "TransactionValue":2000,
         "PricePerKG":4,
         "TransferredProductAmount":500
      }
   },
   "TransactionsBatchA":{
      "Information":{
         "Metadata":"TransactionsBatchA12345",
         "Buyer":"Jane Doe"
      },
      "ABC-Transactions1Data":{
         "timestamp":1597573040,
         "TransactionValue":1000,
         "PricePerKG":2,
         "TransferredProductAmount":500
      },
      "ABC-Transactions2Data":{
         "timestamp":1597573140,
         "TransactionValue":1000,
         "PricePerKG":2,
         "TransferredProductAmount":500
      },
      "ABC-Transactions4Data":{
         "timestamp":1597573240,
         "TransactionValue":2000,
         "PricePerKG":4,
         "TransferredProductAmount":500
      },
      "ABC-Transactions5Data":{
         "timestamp":1597573340,
         "TransactionValue":1000
      },
      "ABC-Transactions6Data":{
         "timestamp":1597573440,
         "TransactionValue":1000,
         "PricePerKG":2,
         "TransferredProductAmount":510
      },
      "ABC-Transactions7Data":{
         "timestamp":1597573440,
         "TransactionValue":1000,
         "PricePerKG":2,
         "TransferredProductAmount":520
      },
      "ABC-Transactions8Data":{
         "timestamp":1597573440,
         "TransactionValue":2000,
         "PricePerKG":4
      }
   },
   "TransactionAmountsA":{
      "InitialAmount":20,
      "LaterAmount":30,
      "Currency":"EUR"
   },
   "TransactionAmountsB":{
      "InitialAmount":50,
      "LaterAmount":60,
      "Currency":"EUR"
   },
   "PowerData":{
      "Active_power_imported_kW":4.85835600,
      "Active_energy_imported_kWh":53.72700119,
      "Active_power_exported_kW":0.0,
      "Apparent_energy_imported_kVAh":0,
      "Apparent_power_exported_kVA":0.00000000,
      "Apparent_energy_exported_kVAh":0.00000000,
      "Power_factor":0.71163559,
      "Application_data":"Application_data_string",
      "Application_UID":"Application_UID_string",
      "Currency":"EUR",
      "Expected_annual_production":0.00000000
   },
   "dictionaryToBeFound":"ABC-Transactions1Data",
   "objectToBeCopied":"LaterAmount",
   "referenceTimestamp":1597573340,
   "PricePerKG":3,
   "otherPricePerKG":5,
   "myUserName":"Authority1234",
   "myVerySecretPassword":"password123",
   "notPrunedDictionary": {
      "empty1": "",
      "notEmpty": "Hello World!",
      "empty2": "",
      "emptyDictionary": {
         "empty3": "",
	 "empty4": ""
      }
   }
}
```

Moreover we will also upload an ecdh public key:

```json
{"Authority1234":{"keyring":{"ecdh":"B4rYTWx6UMbc2YPWRNpl4w2M6gY9jqSa637n8Kr2pPc="}}}
```

In the script below we will: 
 - Find the *timestamp* of the latest *transaction* (and older transaction)
 - Sum the *amount of product transferred* for all the *transactions* occurred after a certain *timestamp*, for two lists of dictionaries
 - Sum the results of the above sum
 - Find the *transactions* occurred at a certain *timestamp* 
 - Check if a *transaction* with certain name is found in the list
 - Creating a new dictionary 
 - Inserting in the newly created dictionary, the output of the computation above
 - Singning the newly created dictionary using ECDSA cryptography
 - Printing out the newly created dictionary, its signature and a couple more objects
 - Various sums, subtractions, multiplications, divisions
 - Create an array that contains all the objects named *timestamp* in *TransactionsBatchA*
 - Prune a string dictionary

```gherkin
# rule check version 1.0.0
Scenario ecdh: dictionary computation and signing 

# LOAD DICTIONARIES
# Here we load the two dictionaries and import their data.
# Later we also load some numbers, one of them name "PricePerKG" exists in the dictionary's root, 
# as well as inside each element of the object: homonimy is not a problem in this case.
Given that I have a 'string dictionary' named 'TransactionsBatchA'
Given that I have a 'string dictionary' named 'TransactionsBatchB'

Given that I have a 'string dictionary' named 'TransactionAmountsA'
Given that I have a 'string dictionary' named 'TransactionAmountsB'
Given that I have a 'string dictionary' named 'PowerData'

Given that I have a 'string dictionary' named 'notPrunedDictionary'


# Loading other stuff here
Given that I have a 'number' named 'referenceTimestamp'
Given that I have a 'number' named 'PricePerKG'
Given that I have a 'number' named 'otherPricePerKG'
Given that I have a 'string' named 'dictionaryToBeFound'
Given that I have a 'string' named 'objectToBeCopied'
Given that I have a 'string' named 'myVerySecretPassword'

# Loading the keyring afer setting my identity
Given my name is in a 'string' named 'myUserName'
Given that I have my 'keyring'

# FIND MAX and MIN values in Dictionaries
# All the dictionaries contain an internet date 'number' named 'timestamp' 
# In this statement we find the most recent transaction in the dictionary "TransactionsBatchA" 
# by finding the element that contains the number 'timestamp' with the highest value in that dictionary.
# We also save the value of this 'timestamp' in an object that we call "Theta"
When I find the max value 'timestamp' for dictionaries in 'TransactionsBatchA'
and I rename the 'max value' to 'Theta'
When I find the min value 'timestamp' for dictionaries in 'TransactionsBatchA'
and I rename the 'min value' to 'oldestTransaction'

# CREATE SUM, SUM with condition
# Here we compute the sum of the "TransactionValue" numbers,
# in the elements of the dictionary "TransactionsBatchB".
# We also rename the sum into "sumOfTransactionsValueFirstBatch"
When I create the sum value 'TransactionValue' for dictionaries in 'TransactionsBatchB'
and I rename the 'sum value' to 'sumOfTransactionsValueFirstBatch'

# Here we compute the sum of the "TransactionValue" numbers, 
# in the elements of the dictionary "TransactionsBatchB", 
# that have a 'timestamp' higher than "Theta". 
# We also rename the sum into "sumOfTransactionsValueFirstBatchAfterTheta"
When I create the sum value 'TransactionValue' for dictionaries in 'TransactionsBatchB' where 'timestamp' > 'Theta'
and I rename the 'sum value' to 'sumOfTransactionsValueFirstBatchAfterTheta'

# Here we do something similar to the statements above, but using the numbers
# named "TransferredProductAmount" in the same dictionary 
# We rename the sum to "sumOfTransactionsValueFirstBatchAfterTheta"
When I create the sum value 'TransferredProductAmount' for dictionaries in 'TransactionsBatchB' where 'timestamp' > 'Theta'
and I rename the 'sum value' to 'TotalTransferredProductAmountFirstBatchAfterTheta'

# FIND VALUE inside Dictionary's object
# In the statements below we are looking for the transaction(s) happened at time "Theta", 
# in both the dictionaries, and saving their "TransactionValue" into a new object (and renaming the object)
When I find the 'TransactionValue' for dictionaries in 'TransactionsBatchA' where 'timestamp' = 'Theta'
and I rename the 'TransactionValue' to 'TransactionValueSecondBatchAtTheta'

When I find the 'TransferredProductAmount' for dictionaries in 'TransactionsBatchA' where 'timestamp' = 'Theta'
and I rename the 'TransferredProductAmount' to 'TransferredProductAmountSecondBatchAtTheta'

# Here we create a simple sum of the new aggregated values from recent transactions
When I create the result of 'sumOfTransactionsValueFirstBatchAfterTheta' + 'TransactionValueSecondBatchAtTheta'
and I rename the 'result' to 'SumTransactionValueAfterTheta'

When I create the result of 'TotalTransferredProductAmountFirstBatchAfterTheta' + 'TransferredProductAmountSecondBatchAtTheta'
and I rename the 'result' to 'SumTransactionProductAmountAfterTheta'

# FOUND, NOT FOUND
# Here we search for a dictionary what a certain name in a list. 
# This could be useful when searching for a certain transaction in different data sets
# We are loading the string to match from the dataset.
#When I verify the 'dictionaryToBeFound' is found in 'TransactionsBatchA'
#When I verify the 'dictionaryToBeFound' is found in 'TransactionsBatchA'

# Here we are doing the opposite, so check the a dictionary is not in the list
# and we ar ecreating the string not to be match inline in the script, just for the fun of it
When I write string 'someRandomName' in 'not.there'
and I verify the 'not.there' is not found in 'TransactionsBatchA'

# CREATE Dictionary
# You can create a new dictionary using a similar syntax to the one to create an array 
# in the case below we're create a "number dictionary", which is key value storage where 
# the values we want to move are all numbers
When I create the 'number dictionary'
and I rename the 'number dictionary' to 'ABC-TransactionsAfterTheta'

# COPY
# You can copy a dictionary that is nested into a list of dictionaries
# to the root level of the data, to make manipulation and visibility easier.
When I create the copy of 'Information' from dictionary 'TransactionsBatchA'
And I rename the 'copy' to 'copyOfInformationBatchA'

# You can also copy an element of a dictionary, to the root level.
# We're then renaming the object and we're using the notation "element<<dictionary"
# just for convenience, the name of the newly created object is just a string.
When I create the copy of 'InitialAmount' from dictionary 'TransactionAmountsA'
And I rename the 'copy' to 'InitialAmount<<TransactionAmountsA'

# You can also copy an element of a dictionary, which is named from another variable.
When I create the copy of object named by 'objectToBeCopied' from dictionary 'TransactionAmountsA'
And I rename the 'copy' to 'LaterAmount<<TransactionAmountsA'

# PICKUP
# And you can also pickup an element of a dictionary, that is nested 
# into another dictionaries, to the root level:
When I pickup from path 'TransactionsBatchA.Information.Buyer'
and I rename the 'Buyer' to 'Buyer<<Information<<TransactionsBatchA'

# MOVE in Dictionary
# We can use the "move" statement to add an element to a dictionary, as we would do with an array
When I move 'SumTransactionValueAfterTheta' in 'ABC-TransactionsAfterTheta'
When I move 'SumTransactionProductAmountAfterTheta' in 'ABC-TransactionsAfterTheta'
When I move 'TransactionValueSecondBatchAtTheta' in 'ABC-TransactionsAfterTheta'
When I move 'TransferredProductAmountSecondBatchAtTheta' in 'ABC-TransactionsAfterTheta'
When I move 'referenceTimestamp' in 'ABC-TransactionsAfterTheta'

# ECDSA SIGNATURE of Dictionaries
# sign the newly created dictionary using ECDSA cryptography
When I create the signature of 'ABC-TransactionsAfterTheta'
and I rename the 'signature' to 'ABC-TransactionsAfterTheta.signature'

# PRINT the results
# Here we're printing just what we need, but a whole list of dictionaries can be printed 
# in the usual fashion, just uncomment the last line to print all the dictionaries
# contained into 'TransactionsBatchA' and 'TransactionsBatchB' 

# HASH
# we can hash the dictionary using any hashing algorythm
When I create the hash of 'ABC-TransactionsAfterTheta' using 'sha512'
And I rename the 'hash' to 'sha512hashOf:ABC-TransactionsAfterTheta' 

When I create the key derivation of 'ABC-TransactionsAfterTheta' with password 'myVerySecretPassword'
And I rename the 'key_derivation' to 'pbkdf2Of:ABC-TransactionsAfterTheta'

# MATH OPERATIONS
# Like with regular numbers, you can sum, subtract, multiply, divide, modulo with values, 
# see the examples below. The output of the statement will be an object named "result" 
# that we immediately rename.
# The operators allowed are: +, -, *, /, %.
# MATH with numbers found in dictionaries, at root level of the dictionary

When I create the result of 'InitialAmount' in 'TransactionAmountsA' + 'InitialAmount' in 'TransactionAmountsB'
and I rename the 'result' to 'NumbersInDicts-Sum'
When I create the result of 'InitialAmount' in 'TransactionAmountsA' - 'InitialAmount' in 'TransactionAmountsB'
and I rename the 'result' to 'NumbersInDicts-Subtraction'
When I create the result of 'InitialAmount' in 'TransactionAmountsA' * 'InitialAmount' in 'TransactionAmountsB'
and I rename the 'result' to 'NumbersInDicts-Multiplication'
When I create the result of 'InitialAmount' in 'TransactionAmountsA' / 'InitialAmount' in 'TransactionAmountsB'
and I rename the 'result' to 'NumbersInDicts-Division'
When I create the result of 'InitialAmount' in 'TransactionAmountsA' % 'InitialAmount' in 'TransactionAmountsB'
and I rename the 'result' to 'NumbersInDicts-Modulo'


# MATH between numbers loaded individually and numbers found in dictionaries
When I create the result of 'InitialAmount' in 'TransactionAmountsA' + 'PricePerKG'
and I rename the 'result' to 'NumbersMixed-Sum'
When I create the result of 'InitialAmount' in 'TransactionAmountsA' - 'PricePerKG'
and I rename the 'result' to 'NumbersMixed-Subtraction'
When I create the result of 'InitialAmount' in 'TransactionAmountsA' * 'PricePerKG'
and I rename the 'result' to 'NumbersMixed-Multiplication'
When I create the result of 'InitialAmount' in 'TransactionAmountsA' / 'PricePerKG'
and I rename the 'result' to 'NumbersMixed-Division'
When I create the result of 'InitialAmount' in 'TransactionAmountsA' % 'PricePerKG'
and I rename the 'result' to 'NumbersMixed-Modulo'

# REMOVE ZERO values
# Use this statement to clean up a dictionary by removing all the object whose value is 0
# In this case we're using the dictionary 'PowerData' which has several 0 objects.
When I remove zero values in 'PowerData'

# CREATE ARRAY of elements with the same key
# You can group all the elements in a dictionary that have the same key
# value inside a fresh new generated array named array
When I write string 'timestamp' in 'Key'
When I create the array of objects named by 'Key' found in 'TransactionsBatchA'
and I rename the 'array' to 'TimestampArray'

# PRUNE dictionaries
# Given a string dictionary the prune operation removes all the
# empty strings ("") and the empty dictionaries (dictionaries that
# contain only empty strings).
When I create the pruned dictionary of 'notPrunedDictionary'


# Let's print it all out!
Then print the 'ABC-TransactionsAfterTheta'
and print the 'sumOfTransactionsValueFirstBatch'
and print the 'Theta'
and print the 'ABC-TransactionsAfterTheta.signature'
and print the 'Information' from 'TransactionsBatchA'
and print the 'sha512hashOf:ABC-TransactionsAfterTheta'
and print the 'pbkdf2Of:ABC-TransactionsAfterTheta'
and print the 'copyOfInformationBatchA'

and print the 'NumbersInDicts-Sum'
and print the 'NumbersInDicts-Subtraction'
and print the 'NumbersInDicts-Multiplication'
and print the 'NumbersInDicts-Division'
and print the 'NumbersInDicts-Modulo'

and print the 'NumbersMixed-Sum'
and print the 'NumbersMixed-Subtraction'
and print the 'NumbersMixed-Multiplication'
and print the 'NumbersMixed-Division'
and print the 'NumbersMixed-Modulo'

and print the 'PowerData'
and print the 'InitialAmount<<TransactionAmountsA'
and print the 'LaterAmount<<TransactionAmountsA'
and print the 'Buyer<<Information<<TransactionsBatchA'

and print the 'TimestampArray'

and print the 'pruned dictionary'

```


The output should look like this: 

```json
{"ABC-TransactionsAfterTheta":{"SumTransactionProductAmountAfterTheta":2030,"SumTransactionValueAfterTheta":9000,"TransactionValueSecondBatchAtTheta":[1000,1000,1000,2000],"TransferredProductAmountSecondBatchAtTheta":[510,520],"referenceTimestamp":1.597573e+09},"ABC-TransactionsAfterTheta.signature":{"r":"d2tYw0FFyVU7UjX+IRpiN8SLkLR4S8bYZmCwI2rzurI=","s":"8W5XyNQ3NCUVmzzXFUMDgTEML++SOLINfPM8vEbaHVM="},"Buyer<<Information<<TransactionsBatchA":"Jane Doe","Information":{"Buyer":"Jane Doe","Metadata":"TransactionsBatchA12345"},"InitialAmount<<TransactionAmountsA":20,"LaterAmount<<TransactionAmountsA":30,"NumbersInDicts-Division":0.4,"NumbersInDicts-Modulo":20,"NumbersInDicts-Multiplication":1000,"NumbersInDicts-Subtraction":-30,"NumbersInDicts-Sum":70,"NumbersMixed-Division":6.666667,"NumbersMixed-Modulo":2,"NumbersMixed-Multiplication":60,"NumbersMixed-Subtraction":17,"NumbersMixed-Sum":23,"PowerData":{"Active_energy_imported_kWh":53.727,"Active_power_imported_kW":4.858356,"Application_UID":"Application_UID_string","Application_data":"Application_data_string","Currency":"EUR","Power_factor":0.711636},"Theta":1.597573e+09,"TimestampArray":[1.597573e+09,1.597573e+09,1.597573e+09,1.597573e+09,1.597573e+09,1.597573e+09,1.597573e+09],"copyOfInformationBatchA":{"Buyer":"Jane Doe","Metadata":"TransactionsBatchA12345"},"pbkdf2Of:ABC-TransactionsAfterTheta":"5YK1gM0Tu1l5BU7bgs+K8mwO5q8GdA3CnndHdnm3Pi4=","pruned_dictionary":{"notEmpty":"Hello World!"},"sha512hashOf:ABC-TransactionsAfterTheta":"eFkIkViHbPiNBwpMLTZadc2PUJvDKlRsNlh8TSgcI3ElRADnM57PGp7PZYUi9oazy5Uw7aDyz32mXXZjCUV8xQ==","sumOfTransactionsValueFirstBatch":9000}
```




# The script used to create the material in this page

All the smart contracts and the data you see in this page are generated by the scripts [cookbook_when.bats](https://github.com/dyne/Zenroom/blob/master/test/zencode/cookbook_when.bats) and [cookbook_dictionaries.bats](https://github.com/dyne/Zenroom/blob/master/test/zencode/cookbook_dictionaries.bats). If you want to run the scripts (on Linux) you should: 
 - *git clone https://github.com/dyne/Zenroom.git*
 - install  **jq**
 - download a [zenroom binary](https://zenroom.org/#downloads) and place it */bin* or */usr/bin* or in *./Zenroom/src*









<!-- Temp removed, 


-->
### 
<!-- Unused files
 
givenDebugOutputVerbose.json
givenLongOutput.json
 

Link file with relative path downloadable: 
<a href="./_media/examples/zencode_cookbook/thenExhaustiveScript.zen" download>thenExhaustiveScript.zen</a>
 
-->



# The ***Then*** phase: processing the output

In the ***Then*** phase, the output is shaped, processed, sorted and printed out. This is where you can decide what output you want to see and if you want to encode your data into something else. 

# The basics

Let's see two basic examples, where let's say that we are loading this object: 

```json
{
"myNumber":123456789 }
```

In the first example, we'll simply print an object *as it is*, meaning using the default encoding of its ***schema*** or the encoding defined in a ***rule output encode*** statement (if present), along with the default file format (JSON): 

```gherkin
Then print the 'myNumber' 
```

The output should simply be *123456789*.

In the second example, we wanna spice things up a bit and print the number as something else (with a different encoding), lets say as an *hex*:

```gherkin
Then print the 'myNumber' as 'hex'
```

The output here will be the *hex* value of *123456789*, which is *75BCD15*

You can also print with a different encoding an object that, at the output, is nested into something else, which is often the case when you are using ***schemas*** for example if you have:

```json
{
"petition": {"uid" : "TW9yZV9wcml2YWN5X2Zvcl9hbGwh"} }
```

You may want to print the *uid* as string, instead of the default base64 encoding. You can do this by: 

```gherkin
Then print the 'uid' from 'petition' as 'string'
```

And the output shoul be:

```json
{
"uid": "More_privacy_for_all!" }
```


## Printing nested objects

When working with ***dictionaries*** or ***schemas*** you may want to print out just a part of the data you're working with. The statement that comes to help here is: 

```gherkin
Then print the 'childObject' from 'parentObject'
```

And you can as well print an object from a parent with a different encoding:

```gherkin
Then print the 'childObject' from 'parentObject' as 'hex'
```


Here are a couple examples, keep in mind that **in** and **inside** are interchangeable:

```gherkin
When I create the issuer key
When I create the issuer public key
# This prints a child of dictionary, which can be a string (like here) or another dictionary
Then print the 'maxPricePerKG' from 'salesReport'

# This prints the "verifier", that is the cryptographical object produced by an issuer that is publicly accessible
# in order to match it with the proofs. 
Then print the 'issuer public key'
```

The output should look like this:

```json
{"issuer_public_key":{"alpha":"DCVR1myU23U3freVJYRhzFy20WPOhzqn/JyEZMNN/y+gj7KvdEDKfuVjBMy6z7O4AbU9noh14cse4Dxs06XyQW7skeIDzX8r1P1Ldf4D6w6/xI2tbpdC65LeZYkKpTe0ABWqN14boyg0tZhdFaXti3+MKbZx4A6isA+c9tGoDLhVbFtvvXAY3gyzD4paCwG/AL5yjOcrIqiTiOaHJbEtwkQ/OfC3j/xfuPR1yTTq7sgTlk0HbiTemeopEn10F5pO","beta":"FwWLOfRBAoZKfykEvq26iNn2D64gvwgCfinWWZnG4HotCuomB6EB9qJ0sinpV5LNB6GdkrKU3wvYMUU+fBMX8mtR77E3x/ljbqpwwpcmjB9YtONG1peywJvRhXqhIBJSALFTXAB2Y1XtM63Uw5/CBex8zH3wXyYU6sv/ctKi5bUZ2Zzqua9Q8LMqtgLsrrB9GDKbmPT1einkXVMLX0kuJV/AOTnA57q91HKXMCvlvlKs/sr5mJ70FchdEZl0UHIV"},"maxPricePerKG":100}
```


## The ***my*** and ***all*** operators

We have already learned how the ***my*** operator works to load data in the ***Given*** phase.

In a similar fashion, we can selectively print out only the data loaded using the ***Given I am*** and ***Given I have my ...*** statements, but using the statement:

```gherkin
Then print my data
```

In the same fashion, you can print all the data using the statement

```gherkin
Then print all data
```

<!-- template 

## Sorting data output

We've learned that when using the ***Then print all data*** or ***Then print my data*** statements, Zenroom will automatically sort the output alphabetically, because *Determinism is King*. 

In case you need to have your output sorted differently, you can do this by explicitly printing every data object in the order you need. Assuming to have three strings, whose content match their name, we could for example need and inverse sorting, which we would achieve doing  something like: 

```gherkin
Then print 'C-String' 
Then print 'B-String' 
Then print 'A-String' 
```
-->

## Overwriting values

As in the ***When*** phase, if you print multiple times the same object with a different encoding (or different file format), the only output that will see will be the last one in the script. So for example by doing:

```gherkin
Then print 'myNumber' 
And print 'myNumber' as 'hex'
```

The output will be *75BCD15*.

# Printing text 

By now we have mastered the ***Then print*** statement, by stating the name of the object to be printed out.
What happens if the object doesn't exist? Zenroom would simply print the name of the object or, if you prefer, it would print whatever you enclose in the single quotes. For example the line:

```gherkin
Then print 'This variable does not exist anywhere!' 
```

Would print out: 

```JSON
"This_variable_does_not_exist_anywhere!" 
```




# Comprehensive list of *Then* statements

In the large script <a href="./_media/examples/zencode_cookbook/cookbook_then/thenExhaustiveScript.zen" download>thenExhaustiveScript.zen</a> you can find a comprehensive list of most of the combinations you'll ever need to print out the output of Zenroom, that you can test using the JSON <a href="./_media/examples/zencode_cookbook/cookbook_then/myLargeNestedObjectThen.json" download>myLargeNestedObjectThen.json</a> and by adding the following given part to the file <a href="./_media/examples/zencode_cookbook/cookbook_then/thenCompleteScriptGiven.zen" download>thenCompleteScriptGiven.zen</a>. Your output should look like this: <a href="./_media/examples/zencode_cookbook/cookbook_then/thenExhaustiveScriptOutput.json" download>thenExhaustiveScriptOutput.json</a> 

# The script used to create the material in this page

All the smart contracts and the data you see in this page are generated by the script [cookbook_then.bats](https://github.com/dyne/Zenroom/blob/master/test/zencode/cookbook_then.bats). If you want to run the script (on Linux) you should: 
 - *git clone https://github.com/dyne/Zenroom.git*
 - install  **jq**
 - download a [zenroom binary](https://zenroom.org/#downloads) and place it */bin* or */usr/bin* or in *./Zenroom/src*
 


# Branching: If/Endif statements

Zenroom allows branching, done using the **If** and **Endif** Statements.

The *conditional branch* starts with a **If** statement and ends when the corresponding **EndIf** is found,
the **EndIf** close always only the latest opened **If**. For example

```gherking
If (condition1)
  When (do something)
  If (condition2)
    If (condition3)
      When (do something else)
      Then (print something)
    EndIf # ends conditional branching of condition 3
    Then (print something else)
  EndIf  # ends conditional branching of condition 2
Endif # ends conditional branching of condition 1
```

Inside a **If** you can use:
* **If** statements
* [**When**](zencode-cookbook-when) statements
* [**Then**](zencode-cookbook-then) statements
* [**Foreach**](zencode-foreach-endforeach) statementes (any of them must have a corresponding **EndForeach**
inside the conditional branch), pay attention that inside a **Foreach** you can not use the **Then** statements,
even if it is inside a **If** branching.

## Simple If/Endif example

We'll use a simple JSON file with two numbers as input:

```json
{ "number_lower": 10,
  "number_higher": 50
}
```

And in this script we can see some simple comparisons between numbers:
* simple conditions, that will fail
* simple conditions, that will succeed
* two stacked conditions, where the second one will fail
* a simple condition, based on output from a the previous branch, that will succeed

The script goes:

```gherkin
# Here we're loading the two numbers we have just defined
Given I have a 'number' named 'number_lower'
and I have a 'number' named 'number_higher'

# Here we try a simple comparison between the numbers
# if the condition is satisfied, the 'When' and 'Then' statements
# in the rest of the branch will be executed, which is not the case here.
If I verify number 'number_lower' is more than 'number_higher'
When I create the random 'random_left_is_higher'
Then print string 'number_lower is higher'
Endif

# A simple comparison where the condition is satisfied, the 'When' and 'Then' statements are executed.
If I verify number 'number_lower' is less than 'number_higher'
When I create the random 'just a random'
Then print string 'I promise that number_higher is higher than number_lower'
Endif

# We can also check if a certain number is less than or equal to another one
If I verify number 'number_lower' is less or equal than 'number_higher'
Then print string 'the number_lower is less than or equal to number_higher'
Endif
# or if it is more than or equal to
If I verify number 'number_lower' is more or equal than 'number_higher'
Then print string 'the number_lower is more than or equal to number_higher, imposssible!'
Endif

# Here we try a nested comparison: if the first condition is
# satisfied, the second one is evaluated too. Given the conditions,
# they can't both be true at the same time, so the rest of the branch won't be executed.
If I verify number 'number_lower' is less than 'number_higher'
If I verify 'number_lower' is equal to 'number_higher'
When I create the random 'random_this_is_impossible'
Then print string 'the conditions can never be satisfied'
Endif
EndIf

# You can also check if an object exists at a certain point of the execution, with the statement:
# If I verify 'objectName' is found
If I verify 'just a random' is found
Then print string 'I found the newly created random number, so I certify that the condition is satisfied'
Endif

When I create the random 'just a random in the main branch'
Then print all data
```

You should expect an output like this:

```json
{"just_a_random":"XdjAYj+RY95+uyYMI8fR3+fmP5LyQaN54vyTTVKxZyA=","just_a_random_in_the_main_branch":"VyJ47aH6+hysFuthAZJP+LyFxmZs6L56Ru0P+JlCbDs=","number_higher":50,"number_lower":10,"output":["I_promise_that_number_higher_is_higher_than_number_lower","the_number_lower_is_less_than_or_equal_to_number_higher","I_found_the_newly_created_random_number,_so_I_certify_that_the_condition_is_satisfied"]}
```

## More complex If/Endif example

We can compare also elements different from numbers. For example in the following we will compare strings. We will use the following JSON as input:

```json
{ "string_hello": "hello",
  "string_world": "world",
  "dictionary_equal" : { "1": "hello",
                         "2": "hello",
                         "3": "hello" },
  "dictionary_not_equal": { "1": "hello",
                            "2": "hello",
                            "3": "world" }
}
```

And in the following script we will:
* check if two strings are *equal* or *not equal*
* check if a string is *equal* or *not equal* to a dictionary element
* check if all the elements in a dictionary are equal
* check if at least two elements in a dictionary are different

```gherkin
# Here we're loading the two strings and the two arrays we have just defined
Given I have a 'string' named 'string_hello'
Given I have a 'string' named 'string_world'
Given I have a 'string dictionary' named 'dictionary_equal'
Given I have a 'string dictionary' named 'dictionary_not_equal'

# Here we try a simple comparison between the strings
If I verify 'string_hello' is equal to 'string_world'
Then print string 'string_hello is equal to string_world, impossible!'
Endif

# Here we try a simple comparison between the strings
If I verify 'string_hello' is not equal to 'string_world'
Then print string 'string_hello is not equal to string_world'
Endif

# Here we compare a string with an element of the dictionary
If I verify 'string_hello' is equal to '1' in 'dictionary equal'
Then print string 'string_hello is equal to the element with key equal to 1 in dictionary_equal'
Endif
If I verify 'string_hello' is not equal to '1' in 'dictionary equal'
Then print string 'string_hello is not equal to the element with key equal to 1 in dictionary_equal, impossible!'
Endif

# Here we check if all the elements in the dictionary are equal
# (it works also with arrays)
If I verify the elements in 'dictionary_equal' are equal
Then print string 'all elements inside dictionary_equal are equal'
Endif

# Here we check if at least two elements in the dictionary are different
# (it works also with arrays)
If I verify the elements in 'dictionary_not_equal' are not equal
Then print string 'all elements inside dictionary_not_equal are different'
Endif

```

You should expect an output like this:

```json
{"output":["string_hello_is_not_equal_to_string_world","string_hello_is_equal_to_the_element_with_key_equal_to_1_in_dictionary_equal","all_elements_inside_dictionary_equal_are_equal","all_elements_inside_dictionary_not_equal_are_different"]}
```

## Statements that can be used as a condition

Only a subset of the **When** statements can be used to create a conditional branch, that are the one that,
after the `When I` part, start with the **verify** keyword. They can be both cryptographic statements
like a singature verification

```gherkin
When I verify '' has a eddsa signature in '' by ''
```

or, as seen above, more simpler check, like number comparison

```gherkin
When I verify number '' is less than ''
```

# The script used to create the material in this page

All the smart contracts and the data you see in this page are generated by the scripts [branching.bats](https://github.com/dyne/Zenroom/blob/master/test/zencode/branching.bats). If you want to run the scripts (on Linux) you should:
 - *git clone https://github.com/dyne/Zenroom.git*
 - install  **jq**
 - download a [zenroom binary](https://zenroom.org/#downloads) and place it */bin* or */usr/bin* or in *./Zenroom/src*

# Looping: Foreach/EndForeach statements

Zenroom allows looping, done using the **Foreach** and **EndForeach** statements.
There are few possible way of looping that are:
* over an array
```gherkin
Foreach 'element' in 'array'
```
* over two or multiple arrays in parallel
```gherkin
# two arrays
Foreach value prefix 'loop variable ' at same position in arrays 'first array' and 'second array'
# equal to
Foreach value prefix 'loop variable ' across arrays 'first array' and 'second array'
# multiple arrays
Foreach value prefix 'loop variable ' at same position in arrays 'list of array names'
# equal to
Foreach value prefix 'loop variable ' across arrays 'list of array names'
```
* or from a number to another with certain step
```gherkin
Foreach 'i' in sequence from 'zero' to 'ten' with step 'one'
```

As can be seen the keyword **Foreach** is the one that indicates the start of a loop, while
the statement **EndForeach** indicates the ends of loop.
When reaching it if the condition of the foreach is still valid the loop is performed again.

Inside a **Foreach** you can use:
* **Foreach** statements (any of them must have a corresponding **EndForeach**)
* [**If**](zencode-if-endif) statements that must be closed before the loop end. Morever, even if the basic **If** support
the use of **Then** in it, when it is inside a loop this last property is not true anymore, only **When** statements can be used.
* [**When**](zencode-cookbook-when) statements

## Simple Foreach/EndForeach example

In the following script we are looping over all the elements of an array and simply copying them into a new one.

```gherkin
Given I have a 'string array' named 'xs'
When I create the 'string array' named 'new array'
Foreach 'x' in 'xs'
When I move 'x' in 'new array'
EndForeach
Then print 'new array'
```

Indeed if run with data

```
{
  "xs": ["a", "b"]
}
```

the result will be

```
{"new_array":["a","b"]}
```

## Parallel Foreach over multiple arrays

Parallel loops allow you to iterate over multiple arrays simultaneously, processing corresponding
elements from each array in parallel. The loop ends as soon as the shortest array is exhausted,
ensuring that you only process elements up to the point where all arrays have corresponding values.
This feature is useful when you need to combine or process elements from multiple arrays that are structured similarly.

### Parallel Foreach over two arrays

If you want to loop over two arrays, let's say

```json
{
    "x": [
        "a",
        "b"
    ],
    "y": [
        "c",
        "d"
    ]
}
```

at the same time you can use the following syntax:

```gherkin
Given I have a 'string array' named 'x'
Given I have a 'string array' named 'y'

# create the array that will contains the result of the foreach
When I create the 'string array' named 'res'

# loop in parallel over x and y
# equal to: Foreach value prefix 'loop variable ' across arrays 'x' and 'y'
Foreach value prefix 'loop variable ' at the same position in arrays 'x' and 'y'
    # append the array values
    When I append 'loop variable y' to 'loop variable x'
    # insert result in res
    When I move 'loop variable x' in 'res'
EndForeach

Then print 'res'
```

In this simple code we just concatenated the values in `x` and `y` arrays that occupies the same position, indeed the result is

```
{"res":["ac","bd"]}
```

### Parallel Foreach over multiple arrays

When iterating over three or more arrays, you can extend the same logic by referencing an additional array
that holds the names of the arrays you want to loop over.

Let's change a bit the above example to concatenate the values that occupies the same position in three 
different arrays. The data in input will be

```json
{
    "x": [
        "a",
        "b"
    ],
    "y": [
        "c",
        "d"
    ],
    "z": [
        "e",
        "f"
    ],
    "arrays": [
        "x",
        "y",
        "z"
    ]
}
```

where `arrays` is the string array containing the names of the array on which we want to iterate. The zencode will be

```gherkin
Given I have a 'string array' named 'x'
Given I have a 'string array' named 'y'
Given I have a 'string array' named 'z'

Given I have a 'string array' named 'arrays'

# create the array that will contains the result of the foreach
When I create the 'string array' named 'res'

# loop in parallel over x, y and z (specified in arrays)
Foreach value prefix 'loop variable ' across arrays 'arrays'
    # append the array values
    When I append 'loop variable z' to 'loop variable y'
    When I append 'loop variable y' to 'loop variable x'
    # insert result in res
    When I move 'loop variable x' in 'res'
EndForeach

Then print 'res'
```

that would result in

```
{"res":["ace","bdf"]}
```

## Break from a Foreach loop

The
```gherkin
When I break the foreach
# or equivalently
When I exit the foreach
```
statements allow you to exit a foreach loop prematurely. When executed, it immediately terminates the loop's iteration, skipping
any remaining items in the collection or sequence. The program then continues with the first statement following the loop.

The break statement is typically used when a specific condition is met within the loop,
and further iteration is unnecessary or undesirable. An example to understand the foreach and the break can be the following:

Display only those numbers from the list:

```json
{
    "numbers": [12, 75, 150, 180, 145, 525, 50]
}
```

that satisfy the following conditions:
1. The number must be divisible by five
1. If the number is greater than 150, then skip it and move to the following number
1. If the number is greater than 500, then stop the loop

We start by defineing some usefull variables in a file that we will use as keys file

```json
{
    "0": 0,
    "5": 5,
    "150": 150,
    "500": 500
}
```

then the code will be

```gherkin
# Problem:
# display only those numbers from a list that satisfy the following conditions
# 1. The number must be divisible by five
# 2. If the number is greater than 150, then skip it and move to the following number
# 3. If the number is greater than 500, then stop the loop

Given I have a 'number array' named 'numbers'
Given I have a 'number' named '0'
Given I have a 'number' named '5'
Given I have a 'number' named '150'
Given I have a 'number' named '500'

When I create the 'number array' named 'res'

Foreach 'num' in 'numbers'
    # point 3
    If I verify number 'num' is more than '500'
        When I break foreach
    EndIf
    # point 2
    If I verify number 'num' is less or equal than '150'
        When I create the result of 'num' % '5'
        # point 1
        If I verify 'result' is equal to '0'
            When I copy 'num' in 'res'
        EndIf
        When I remove 'result'
    EndIf
EndForeach

Then print the 'res'
```

resulting in

```json
{"res":[75,150,145]}
```

## More complex Foreach/EndForeach example

You can play with them as much as you want, like:

```gherkin
Given I have a 'string array' named 'my_array'
Given I have a 'number' named 'one'
Given I have a 'string' named 'filter'
When I create the 'string array' named 'res'
When I create the 'string array' named 'res_foreach'
If I verify 'my_array' is found
    If I verify size of 'my_array' is more than 'one'
        Then print the string 'long array'
    EndIf
    Foreach 'el' in 'my_array'
        If I verify 'data' is found in 'el'
            When I pickup from path 'el.data'
            If I verify 'other_key' is found in 'data'
                When I pickup from path 'data.other_key'
                Foreach 'e' in 'other_key'
                    When I copy 'e' in 'res_foreach'
                EndForeach
                When I remove 'other_key'
            EndIf
            If I verify 'key' is found in 'data'
                When I move 'key' from 'data' in 'res'
            EndIf
            When I remove 'data'
        EndIf
        If I verify 'other_data' is found in 'el'
            When I pickup from path 'el.other_data'
            If I verify 'other_key' is found in 'other_data'
                When I pickup from path 'other_data.other_key'
                Foreach 'e' in 'other_key'
                    If I verify 'e' is equal to 'filter'
                        When I copy 'e' in 'res_foreach'
                    EndIf
                    When done
                EndForeach
                When I remove 'other_key'
            EndIf
            If I verify 'key' is found in 'other_data'
                When I move 'key' from 'other_data' in 'res'
            EndIf
            When I remove 'other_data'
        EndIf
    EndForeach
EndIf

Then print 'res'
Then print 'res_foreach'
```

that with input data

```json
{
    "my_array": [
        {
            "data": {
                "key": "value"
            }
        },
        {
            "other_data": {
                "other_key": [
                    "other_value_1",
                    "other_value_2"
                ]
            }
        }
    ],
    "one": 1,
    "filter": "other_value_2"
}
```

will result in

```json
{"output":["long_array"],"res":["value"],"res_foreach":["other_value_2"]}
```

# The script used to create the material in this page

All the smart contracts and the data you see in this page are generated by the scripts [branching.bats](https://github.com/dyne/Zenroom/blob/master/test/zencode/branching.bats),
[foreach.bats](https://github.com/dyne/Zenroom/blob/master/test/zencode/foreach.bats) and
[branching.bats](https://github.com/dyne/Zenroom/blob/master/test/zencode/educational.bats).
If you want to run the scripts (on Linux) you should:
 - *git clone https://github.com/dyne/Zenroom.git*
 - install  **jq**
 - download a [zenroom binary](https://zenroom.org/#downloads) and place it */bin* or */usr/bin* or in *./Zenroom/src*
# The *debug* operators

Looking back at the previous paragraphs, you may be wondering what happens exactly inside Zenroom's virtual machine and - more important - how to peep into it. The *Debug operators* address this precise issue: they are a wildcard, meaning that they can be used in any phase of the process. You may for example place it at the end of the Given phase, in order to see what data has the virtual machine actually imported. These are the *Debug operators* that you can use:

- *backtrace*
- *codec*
- *config*
- *debug*
- *schema*
- *trace*

In order to understand better in what they differ we will test them on the same script and with the same input:
- input:

```json
{
	"keyring": {
		   "eddsa": "CbAbexaForJ4ES27FR9SMCiNr33aG92CKH7qZG84tHa5",
		   "schnorr": "XdjAYj+RY95+uyYMI8fR3+fmP5LyQaN54vyTTVKxZyA="
	}
}
```

- script:

```gherkin
Scenario 'eddsa': Generate the public key
Scenario 'schnorr': Generate the public key

Given I have the 'keyring'
When I create the eddsa public key
When I create the schnorr public key
Then print the data
```

## Backtrace and Trace
The **backtrace** and **trace** operators are the same commands. These commands print, as warning, the stack traces, i.e. a report of Zenroom's internal processing operations. In order to understand it better let see an example.

```gherkin
Scenario 'eddsa': Generate the public key
Scenario 'schnorr': Generate the public key

Given I have the 'keyring'
When I create the eddsa public key
When I create the schnorr public key
and backtrace

Then print the data
```

And at screen we can see the following warnings messages:
```bash
[W]  .  Scenario 'eddsa'
[W]  .  Scenario 'schnorr'
```
That means that Zenroom has loaded the [EdDSA](zencode-scenarios-eddsa.md) and [Schnorr](zencode-scenarios-schnorr.md)'s scenarios. This result is obtained by using the [debug level](zenroom-config.md) equal to 1, increasing it to 2 we will also see if the loading of the objects in the *Given phase* was successful.


## Codec
The **codec** command print to screen the encoding specification for each item specified from the beginning of the script to the point where it is deployed. For example the following script:

```gherkin
Scenario 'eddsa': Generate the public key
Scenario 'schnorr': Generate the public key

Given I have the 'keyring'
When I create the eddsa public key
When I create the schnorr public key
and codec

Then print the data
```

will prompt to the screen the following warning message:
```bash
[W] {
    CODEC = {
        eddsa_public_key = {
            encoding = "base58",
            name = "eddsa_public_key",
            zentype = "element"
        },
        keyring = {
            encoding = "complex",
            name = "keyring",
            zentype = "schema"
        },
        schnorr_public_key = {
            name = "schnorr_public_key",
            zentype = "element"
        }
    }
}
```

From these information for example we can see that the EdDSA public key is encoded as base58, while the Keyring as a complex encoding because the keys inside it have different encoding, finally we can see that the Schnorr public key has no encoding and this is due to the fact that it uses base64 encoding that is the default inside Zenroom so there is no need to specify it.

## Config

The **config** command print to screen the configuration under which Zenroom is running. For example the following script:

```gherkin
Scenario 'eddsa': Generate the public key
Scenario 'schnorr': Generate the public key

Given I have the 'keyring'
When I create the eddsa public key
When I create the schnorr public key
and config

Then print the data
```

will prompt to the screen the following warning message:
```bash
[W] {
    debug = {
        encoding = {
            fun = <function 1>,
            name = "hex"
        }
    },
    hash = "sha256",
    heap = {
        check_collision = true
    },
    heapguard = true,
    input = {
        encoding = {
            check = <function 2>,
            encoding = "base64",
            fun = <function 3>
        },
        format = {
            fun = <function 4>,
            name = "json"
        },
        tagged = false
    },
    output = {
        encoding = {
            fun = <function 5>,
            name = "base64"
        },
        format = {
            fun = <function 4>,
            name = "json"
        },
        versioning = false
    },
    parser = {
        strict_match = true
    }
}
```

This, for example, tell us that the default settings are:
- the output of the debug command is encoded as hex;
- the hash function is SHA256;
- the input and output encoding is base64 and in JSON format.


## Schema

The **schema** command print to screen all the schemes in the heap and the keys inside it, but not the value. For example the following script:

```gherkin
Scenario 'eddsa': Generate the public key
Scenario 'schnorr': Generate the public key

Given I have the 'keyring'
When I create the eddsa public key
When I create the schnorr public key
and debug

Then print the data
```

will prompt to the screen the following warning message:

```bash
[W] {
    SCHEMA = {
        ACK = {
            eddsa_public_key = octet[32] ,
            keyring = {
                eddsa = octet[32] ,
                schnorr = octet[32] 
            },
            schnorr_public_key = octet[48] 
        },
        IN = {},
        KIN = {},
        OUT = {},
        TMP = {}
    }
}
```

Where **IN** and **KIN** represent the *Given phase* (respectively data and keys), **ACK** the *When phase*, **OUT** the *Then phase* and **TMP** is a temporary memory where data in input is allocated before being validated and moved to the **ACK** memory. In the above example we can see that in the *When phase* we have a 32 bytes EdDSA public key, the keyring containing the 32 bytes EdDSA and Schnorr keys and a 32 bytes Schnorr public key. They are all stored as octet because Zenroom converts all data to an internal encoding, called *octet*, when processing it and converts it back to the data original encoding when the output is being generated. Moreover you can see that the **IN** and **KIN** memories are empty, this is due to the fact that as soon as the *When phase* is reached the *Zenroom Garbage collector* clears this two piece of memory since they will not be used anymore.


## Debug

The **debug** command is the most powerful one, it performs the *backtrace* command and a version of the *schema* command that print also the value and not only the keys. For example the following script:

```gherkin
Scenario 'eddsa': Generate the public key
Scenario 'schnorr': Generate the public key

Given I have the 'keyring'
When I create the eddsa public key
When I create the schnorr public key
and debug

Then print the data
```

will prompt to the screen the following warning messages:

```bash
[W]  .  Scenario 'eddsa'
[W]  .  Scenario 'schnorr'
[W] {
    a_GIVEN_in = {},
    b_GIVEN_in = {},
    c_WHEN_ack = {
        eddsa_public_key = octet[32] a53e7a70bd4002f76734039399a1b57322ed7c8295576d0ee14a9430e3fa4ab0,
        keyring = {
            eddsa = octet[32] ac3127d66c12bd6635a6d3486d48ee83616d053e78b3a2b0b4e4af947a9ea806,
            schnorr = octet[32] 5dd8c0623f9163de7ebb260c23c7d1dfe7e63f92f241a379e2fc934d52b16720
        },
        schnorr_public_key = octet[48] 051f7c0e1e97325df15f074b0f6fac9a1390c828c19449cbc4c57a574b51581501a092c05acd56100819da76e1768521
    },
    d_THEN_out = {}
}

```

# The script used to create the material in this page

All the smart contracts and the data you see in this page are generated by the scripts [cookbook_debug.sh](https://github.com/dyne/Zenroom/blob/master/test/zencode/cookbook_debug.sh) . If you want to run the scripts (on Linux) you should: 
 - *git clone https://github.com/dyne/Zenroom.git*
 - install  **jq**
 - download a [zenroom binary](https://zenroom.org/#downloads) and place it */bin* or */usr/bin* or in *./Zenroom/src*


# Symmetric cryptography

This is a simple technique to hide a secret using a common password known to all participants.

The algorithm used is
[AES-GCM](https://en.wikipedia.org/wiki/Galois/Counter_Mode) with a random IV and an optional authenticated header ([AEAD](https://en.wikipedia.org/wiki/Authenticated_encryption))



<!-- Old stuff

```gherkin
Scenario simple: Encrypt a message with the password
Given nothing
# only inline input, no KEYS or DATA passed
When I write string 'my secret word' in 'password'
and I write string 'a very short but very confidential message' in 'whisper'
and I write string 'for your eyes only' in 'header'
# header is implicitly used when encrypt
and I encrypt the secret message 'whisper' with 'password'
# anything introduced by 'the' becomes a new variable
Then print the 'secret message'
```

The output is returned in `secret message` and it looks like:

```json
{"secret_message":{"checksum":"gbSxJsL9OwhTRPhKhmSifQ","header":"Zm9yX3lvdXJfZXllc19vbmx5","iv":"mhB5tXJZEWegGMqez9fZ6fKvrYcdrZ4ukCLjNGGovHc","text":"QumzAyDEmmeRiYtIxrwVKq-F46O6YWyOt4b-DNIN6t8962W3JFcGAhm9"}}
```

To decode make sure to have that secret password and that a valid `secret message` is given, then use:

```gherkin
Scenario simple: Decrypt the message with the password
Given I have a valid 'secret message'
When I write string 'my secret word' in 'password'
and I decrypt the secret message with 'password'
Then print as 'string' the 'text' inside 'message'
and print as 'string' the 'header' inside 'message'
```

-->

So let's imagine I want to share a secret with someone and send secret messages encrypted with it:

```mermaid
sequenceDiagram
        participant A as Anon1
        participant B as Anon2
        A->>A: Think of a secret password
    A->>B: Tell the password to a friend
        A->>A: Encrypt a secret message with the password
    A->>B: Send the secret message to the friend
    B->>B: Decrypts the secret message with the password
```

The encryption is applied using 3 arguments:

- `password` can be any string (or file) used to lock and unlock the secret
- `message` can be any string (or file) to be encrypted and decrypted
- `header` is a fixed name and optional argument to indicate an authenticated header

These 3 arguments can be written or imported, but must given before using the `I encrypt` statement, explained in [scenario 'ecdh' manual](/pages/zencode-scenarios-ecdh?id=symetric-cryptography-encrypt-with-password).



Of course the password must be known by all participants and that's the dangerous part, since it could be stolen. We mitigate this risk using **public-key cryptography**, also known as **a-symmetric encryption**, explained below.


# Asymmetric cryptography

We use [asymmetric encryption (or public key
cryptography)](https://en.wikipedia.org/wiki/Public-key_cryptography)
when we want to introduce the possession of **keypairs** (public and private) both by
Alice and Bob: this way there is no need for a single secret to be known to both.

Fortunately it is pretty simple to do using Zencode in 2 steps

- Key generation and exchange ([SETUP](https://en.wikipedia.org/wiki/Key_exchange))
- Public-key Encryption or signature ([ECDH](https://en.wikipedia.org/wiki/Elliptic-curve_Diffie%E2%80%93Hellman) and [ECDSA](https://en.wikipedia.org/wiki/Elliptic_Curve_Digital_Signature_Algorithm))

## Key generation and exchange

In this phase each participant will create his/her own keypair, store it and communicate the public key to the other. First the private key will be generated from from a random number, and then public key, which is usually a longer octet and actually an [Elliptic Curve Point](/lua/modules/ECP.html) coordinate.

<!-- Old stuff

The statement to generate a keypair (public and private keys) is simple:

```gherkin
Scenario 'simple': Create the keypair
Given that I am known as 'Alice'
When I create the keypair
Then print my data
```

It will produce something like this:

```json
{"Alice":{"keypair":{"private_key":"LTdWzNtAsS78kzoDuMD7eSBSMnaHMiwo3Id4oXgLXmSGXuknTtVWv23NQ00nFMYI6sLCZhblR7E","public_key":"BGBnu4XiCA0LlrCzNf2HLY-a12tzMXXP5rRrHRhmpraPW0leLWLkkNtI54oGxnmNWLy-f-dXEfNzQUosO-86CW82NkUB5VTdvaA_oaMTZAKDdweDJlYGegbjSlXrM9CibVIbErDTuWTwUaWkHpHmVME"}}}
```

There is nothing preventing an host application to separate these JSON
fields and store them in any secure way.

-->

Here we demonstrate how to create keypairs as well separate them using Zencode:

- 2 contracts to create Alice and Bob keypairs
- 2 contracts to separate the public key from the private key for each

After both Alice and Bob have their own keypairs and they both know each other public key we can move forward to do asymmetric encryption and signatures.

```mermaid
sequenceDiagram
    participant A as Alice
    participant B as Bob
    A->>A: create the keypair
    A->>B: publish the public key
    B->>B: create the keypair
    B->>A: publish the public key
```


One of the advantage of using Zencode here is the use of the `valid` keyword which effectively parses the `public key` object and verifies it as valid, in this case as being a valid point on the elliptic curve in use. This greatly reduces the possibility of common mistakes.

They keypair generation is detailed in [scenario 'ecdh' manual](/pages/zencode-scenarios-ecdh?id=generate-a-keypair).



## Public-key Encryption (ECDH)

Public key encryption is similar to the asymmetric encryption explained in the previous section, with a difference: the `from` and `for` clauses indicating the public
key of the recipient.

Before getting to the encryption 2 other objects must be given:

- `keypair` is one's own public and private keys
- `public key` from the intended recipient

<!-- Old stuff

So with an input separated between DATA and KEYS or grouped together in an array like:

```json
{"Bob":{"keypair":{"private_key":"P6kCGGJWXyGbQd6B3V0Y54sI_k7K_ks182JGyAd79S4V203Tl5liYiLrPW8Es3TxKJZ2szXbSy8","public_key":"BMyAnSg9zP_rxbEMNLYgWBTbmvieqXO6uCt6Tyh9jnJxvYcmZa01sPdRY4Qialnwty9Ms44-TRXAOLmFsi8PEAJ9y6W2XM4Gt5XzTg_wAtVZyoB-PhjN-qaR9cWZo1ol_1d1DIFzHStgcEl2gUz95NA"}},"public_key":{"Alice":"BGBnu4XiCA0LlrCzNf2HLY-a12tzMXXP5rRrHRhmpraPW0leLWLkkNtI54oGxnmNWLy-f-dXEfNzQUosO-86CW82NkUB5VTdvaA_oaMTZAKDdweDJlYGegbjSlXrM9CibVIbErDTuWTwUaWkHpHmVME"}}
```

```gherkin
Rule check version 1.0.0
Scenario 'simple': Alice encrypts a message for Bob
	Given that I am known as 'Alice'
	and I have my valid 'keypair'
	and I have a valid 'public key' from 'Bob'
	When I write string 'This is my secret message.' in 'message'
	and I write string 'This is the header' in 'header'
	and I encrypt the message for 'Bob'
	Then print the 'secret message'
```

which encrypts and stores results in `secret message`; also in this case `header` may be given, then is included in the encryption as an authenticated clear-text section.

-->

```mermaid
sequenceDiagram
        participant A as Alice
        participant B as Bob
    A->>A: prepare the keyring
    A->>A: encrypt the message
#    Note over A,B: Given that I am known as 'Alice'<br/>and I have my 'keypair'<br/>and I have a 'public key' from 'Bob'<br/>When I write 'my secret' in 'draft'<br/>and I encrypt the 'draft' to 'secret message' for 'Bob'<br/>Then print the 'secret message'<br/>
        A->>B: send the secret message
#       Note over A,B: Given that I am 'Bob'<br/>and I have my valid 'keypair'<br/>and I have a 'public key' from 'Alice'<br/>Then print my 'keypair'<br/>and print the 'public key'
    B->>B: prepare the keyring
#       Note over A,B: Given that I am known as 'Bob'<br/>and I have my valid 'keypair'<br/>and I have a 'public key' from 'Alice'<br/>and I have a valid 'secret message'<br/>When I decrypt the 'secret message' from 'Alice' to 'clear text'<br/>Then print as 'string' the 'clear text'<br/>and print the 'header' inside 'secret message'<br/>
        B->>B: decrypt the message
```


The decryption will always check that the header hasn't changed, maintaining the integrity of the string which may contain important public information that accompany the secret.

They asymetric encryption is detailed in [scenario 'ecdh' manual](/pages/zencode-scenarios-ecdh?id=encrypt-a-message-with-a-public-key).


## Public-key Signature (ECDSA)

Public-key signing allows to verify the integrity of a message by
knowing the public key of all those who have signed it.

It is very useful when in need of authenticating documents: any change
to the content of a document, even one single bit, will make the
verification fail, showing that something has been tampered with.

The one signing only needs his/her own keypair, so the key setup will
be made by the lines:

```gherkin
	Given that I am known as 'Alice'
	and I have my valid 'keypair'
```

then assuming that the document to sign is in `draft`, Alice can
proceed signing it with:

```gherkin
	and I create the signature of 'draft'
```

which will produce a new object `signature` to be printed along the
draft: the original message stays intact and the signature is detached.

On the other side Bob will need Alice's public key to verify the
signature with the line:

```gherkin
	When I verify the 'draft' is signed by 'Alice'
```

which will fail in case the signature is invalid or the document has
been tampered with.

```mermaid
sequenceDiagram
        participant A as Alice
        participant B as Bob
#    Note over A,B: Given that I am known as 'Alice'<br/>and I have my 'keypair'<br/>When I write 'This is my signed message to Bob.' in 'draft'<br/>and I sign the 'draft' as 'signed message'<br/>Then print my 'signed message'
    A->>A: sign the message     as Alice
        A->>B: send the signed message
#       Note over A,B: Given that I am 'Bob'<br/>and I have my valid 'keypair'<br/>and I have a 'public key' from 'Alice'<br/>Then print my 'keypair'<br/>and print the 'public key'
    B->>B: prepare the keyring
#       Note over A,B: Given that I am known as 'Bob'<br/>and I have inside 'Alice' a valid 'public key'<br/>and I have a draft inside 'Alice'<br/>and I have a valid 'signed message'<br/>When I verify the 'signed message' is authentic<br/>Then print 'signature' 'correct'<br/>and print as 'string' the 'text' inside 'signed message'
        B->>B: verify the signature by Alice
```


They asymetric encryption is detailed in [scenario 'ecdh' manual](/pages/zencode-scenarios-ecdh?id=create-the-signature-of-an-object): there we have an example where Alice uses her private key to sign and authenticate a message. Bob or anyone else can use Alice's public key to prove that the integrity of the message is kept intact and that she signed it.

# Zero Knowledge Proof and Attribute Based Credentials

In this chapter we'll look at some more advanced cryptography, namely the 'Attribute Based Credentials' and the 'Zero Knowledge Proof': this is powerful and complex feature
implemented using the [Coconut crypto scheme](https://arxiv.org/pdf/1802.07344.pdf). 

Zencode supports several features based on pairing elliptic curve
arithmetics and in particular:

- non-interactive zero knowledge proofs (also known as ZKP or ZK-Snarks)
- threshold credentials with multiple decentralised issuers
- homomorphic encryption for numeric counters

These are all very useful features for architectures based on the
decentralisation of trust, typical of **DLT and blockchain based
systems, as well for off-line and non-interactive authentication**.

The Zencode language leverages two main scenarios, more will be
implemented in the future.

1. Attribute Based Credentials (ABC) where issuer verification keys
   represent specific credentials
2. A Petition system based on ABC and homomorphic encryption

Three more are in the work and they are:

1. Anonymous proxy validation scheme
2. Token thumbler to privately transfer numeric assets
3. Private credential revocation

**Zero knowledge proof** and **attribute based credential** cryptography are detailed in [scenario 'credential' manual](/pages/zencode-scenario-credentials)


# DP3T: Proximity Tracing


Following up [this popular post on how to make decentralized privacy-preserving proximity tracing using zencode](https://medium.com/@jaromil/decentralized-privacy-preserving-proximity-tracing-cryptography-made-easy-af0a6ae48640) this documentation will go through implementation details.

The Decentralized Privacy-Preserving Proximity Tracing (DP-3T) protocol is described in the [DP-3T Whitepaper](https://github.com/DP-3T/documents/).

If you are a mobile app developer or a tech-savvy person in general, someone that can read and experiment with a shell script or javascript or someone curious enough to know more how applied cryptography works, then read on and you’ll be surprised how easy this is.

![Processing and storing of observed ​Ephemeral IDs (artwork by Wouter Lueks)](https://github.com/DP-3T/documents/raw/master/graphics/decentralized_contact_tracing/whitepaper_figureAA_processing_storing_ephIDs.png)

The scenario **dp3t** is detailed in the [scenario 'dp3t' manual](/pages/zencode-scenario-dp3t).
# Scenario 'credentials': Zero knowledge Proof and Attribute Based Credentials

![Alice in Wonderland](../_media/images/alice_with_cards-sm.jpg) 

Let's imagine 3 different subjects for our scenarios:

1. **Mad Hatter** is a well known **credential issuer** in Wonderland
2. **Wonderland** is an open space (a blockchain!) and all inhabitants can check the validity of **proofs**
3. **Alice** just arrived: to create **proofs** she'll request a **credential** to the issuer **MadHatter**

When **Alice** is in possession of **credentials** then she can
create a **proof** any time she wants using as input:

- the **credentials**
- her **credential key**
- the **issuer public key** by MadHatter

```gherkin
Scenario credential: create proof
Given that I am known as 'Alice'
and I have my 'keyring'
and I have a 'issuer public key' inside 'MadHatter'
and I have my 'credentials'
When I aggregate all the issuer public keys
and I create the credential proof
Then print the 'credential proof'
```

All these "things" (credentials, proofs, etc.) are data structures that can be used as input and received as output of Zencode functions. For instance a **proof** can be print in **JSON** format and looks a bit list this:

```json
{"credential_proof":{"kappa":"GNZ+cD1N6IMaqUCtC7028XITDJ3UWdHgGlkDsgqybKRvYxEokDzLNxF10KvPEr3qFvnH37QcaGP76R++yLjlFmKoxX8fol6HwXZWM7EEXd1tHm5ALtOb8LSR+KNNZVo+FACA/9R14D7QaiO8pBSxO5Xtb30J1c+Zamsr5eQuY8m6NvzA1teVH5wjwBDvnubtCmCKN86mcQWp7Y3gZCyprp11fp7MMV2YYf0i39hS8kOa9kDzIypmqXFitqXtC80q","nu":"AwaXYNSgY36mGkPXO832lfzqKKmc309ZuhQBWQPB2ABqi0EOwEk/ENBZ5/biLXpuHA==","pi_v":{"c":"FwleJBD8AqhHHVNSXOrhuyXgkmksJWljF2Tvpm6bv/A=","rm":"UTmcAbKE4Uzj8vbncJpk9O6fuJUmaiHRElOLHIMOy0g=","rr":"PZ6Kdd3vSF2jn1qMALSinm4v0Zk1NFgfn/qWfJXLD9o="},"sigma_prime":{"h_prime":"AhClGrLHKllUz2+RcrIKAWAmfsCzz2OwERAl6ssXOZV1shH781APwR27jyd8MqmBXA==","s_prime":"AgR2e2s17otCJ3MF1X2OO3RMzVoShKseY9nL192nGzWf1YbQp6Lmtjl2hMM4ZrJBWQ=="}}}
```

Anyone can verify proofs using as input:

- the **credential proof**
- the **issuer public key** by MadHatter

```gherkin
Scenario credential: verify proof
Given that I have a 'issuer public key' inside 'MadHatter'
and I have a 'credential proof'
When I aggregate all the issuer public keys
When I verify the credential proof
Then print the string 'the proof matches the public_key! So you can add zencode after the verify statement, that will execute only if the match occurs.'
```

What is so special about these proofs? Well!  Alice cannot be followed
by her trail of proofs: **she can produce an infinite number of
proofs, always different from one another**, for anyone to recognise
the credential without even knowing who she is.

![even the MadHatter is surprised](../_media/images/madhatter.jpg)

Imagine that once **Alice** is holding **credentials** she can enter
any room in Wonderland and drop a **proof** in the chest at its
entrance: this proof can be verified by anyone without disclosing
Alice's identity.

The flow described above is pretty simple, but the steps to setup the
**credential** are a bit more complex. Lets start using real names
from now on:

- Alice is a credential **Holder**
- MadHatter is a credential **Issuer**
- Wonderland is a public **Blockchain**
- Anyone is any peer connected to the blockchain

```mermaid
graph LR
          subgraph Sign
                           iKP>issuer key] --- I(Issuer)
                           hRQ --> I
                           I --> iSIG
          end
          subgraph Blockchain
                           iKP --> Verifier
                           Proof
          end
          subgraph Request
                           H --> hKP> credential key]
                           hKP --> hRQ[request]
          end
          iSIG[signature] --> H(Holder)
          H --> CRED(( Credential ))
          CRED --> Proof
          Proof --> Anyone
      Verifier --> Anyone
```

---- 

To add more detail, the sequence is:

```mermaid
sequenceDiagram
        participant H as Holder
        participant I as Issuer
        participant B as Blockchain
        I->>I: 1 create a issuer key
        I->>B: 1a publish the issuer public key
        H->>H: 2 create a credential key
        H->>I: 3 send a credential request
        I->>H: 4 reply with the credential signature
        H->>H: 5 aggregate the credentials
        H--xB: 6 create and publish a blind credential proof
        B->>B: 7 anyone can verify the proof
```

## The 'Coconut' credential flow in Zenroom


1 **MadHatter** generates an **issuer key**

***Input:*** none

***Smart contract:*** credentialIssuerKeygen.zen

```gherkin
Scenario credential: issuer keygen
Given that I am known as 'MadHatter'
When I create the issuer key
Then print my 'keyring'
```


***Output:*** credentialIssuerKeyring.json

```json
{"MadHatter":{"keyring":{"issuer":{"x":"CKGied4Ww03qmsUM/vnOMDodgwPp9Fc3QJuiFcBGQ/k=","y":"abYTJShT0ZBKU+ZwJlEIPNinT6TFU+unaKMEZ+u3kbs="}}}}
```

----

1a **MadHatter** publishes the **issuer public key**

***Input:*** credentialIssuerKeyring.json

***Smart contract:*** credentialIssuerPublishpublic_key.zen

```gherkin
Scenario credential: publish public_key
Given that I am known as 'MadHatter'
and I have my 'keyring'
When I create the issuer public key
Then print my 'issuer public key'
```

***Output:*** credentialIssuerpublic_key.json

```json
{"MadHatter":{"issuer_public_key":{"alpha":"DCVR1myU23U3freVJYRhzFy20WPOhzqn/JyEZMNN/y+gj7KvdEDKfuVjBMy6z7O4AbU9noh14cse4Dxs06XyQW7skeIDzX8r1P1Ldf4D6w6/xI2tbpdC65LeZYkKpTe0ABWqN14boyg0tZhdFaXti3+MKbZx4A6isA+c9tGoDLhVbFtvvXAY3gyzD4paCwG/AL5yjOcrIqiTiOaHJbEtwkQ/OfC3j/xfuPR1yTTq7sgTlk0HbiTemeopEn10F5pO","beta":"FwWLOfRBAoZKfykEvq26iNn2D64gvwgCfinWWZnG4HotCuomB6EB9qJ0sinpV5LNB6GdkrKU3wvYMUU+fBMX8mtR77E3x/ljbqpwwpcmjB9YtONG1peywJvRhXqhIBJSALFTXAB2Y1XtM63Uw5/CBex8zH3wXyYU6sv/ctKi5bUZ2Zzqua9Q8LMqtgLsrrB9GDKbmPT1einkXVMLX0kuJV/AOTnA57q91HKXMCvlvlKs/sr5mJ70FchdEZl0UHIV"}}}
```


----

2 **Alice** generates her **credential key**

***Input:*** none

***Smart contract:*** credentialParticipantKeygen.zen

```gherkin
Scenario credential: credential keygen
Given that I am known as 'Alice'
When I create the credential key
Then print my 'keyring'
```


***Output:*** credentialParticipantKeyring.json

```json
{"Alice":{"keyring":{"credential":"CKGied4Ww03qmsUM/vnOMDodgwPp9Fc3QJuiFcBGQ/k="}}}
```

You can also generate the key elsewhere and then import it into Zenroom. To do that you can use one of the following statements:

```gherkin
When I create the credential key with secret key 'myKey'
When I create the credential key with secret 'myKey'
```
where **myKey** is the credential key generated outside of Zenroom.

----

3 **Alice** sends her **credential signature request**

***Input:*** credentialParticipantKeyring.json 

***Smart contract:*** credentialParticipantSignatureRequest.zen

```gherkin
Scenario credential: create request
Given that I am known as 'Alice'
and I have my valid 'keyring'
When I create the credential request
Then print my 'credential request'
```


***Output:*** credentialParticipantSignatureRequest.json

```json
{"Alice":{"credential_request":{"commit":"AhL6ktfHJ1U3m80PNAvj+9qqimlBQSP7Jm8kqRl/cQSdQj729BljAAqjwGx9RSVsmg==","pi_s":{"commit":"GudcgN/bvlqYF/+XhtR8h3mHytJ2GAQWTe7OeQ7KZw0=","rk":"NNRuCDqBDa/6mifTh7uRe6iGJYHRBtrpenV1oogoPKE=","rm":"Wly+eTmSM40uM7HkUmKB4PZmRFX7Ajua6ZZdylW4eKg=","rr":"HfDYOAJCh49v4NQsVzXbTuzju1vPiet1AGkb8U2Q79c="},"public":"AhI6Hg/QJKYeF1E3O50Wwr1mYHs8rCHX+7HfDRM9zrr/Y2bw6rQiip+EGP1PrOOMXw==","sign":{"a":"Ahn2OgUGQd/EAU7DgTY9mq0HaDfxFFajWSA463x8E8H5Xoks2TdaP+WlokFQSeH4BA==","b":"AhhFCFOlnjkjlZdFzTKtiIoc9ibm0MezXYTpqnMzjwv7fRJP60qgLinjxnDYRg0w4g=="}}}}
```

----

4 **MadHatter** decides to sign a **credential signature request**

***Input:*** credentialParticipantSignatureRequest.json ***and*** credentialIssuerKeyring.json 

***Smart contract:*** credentialIssuerSignRequest.zen

```gherkin
Scenario credential: issuer sign
Given that I am known as 'MadHatter'
and I have my valid 'keyring'
and I have a 'credential request' inside 'Alice'
When I create the credential signature
and I create the issuer public key
Then print the 'credential signature'
and print the 'issuer public key'
```


***Output:*** credentialIssuerSignedCredential.json

```json
{"credential_signature":{"a_tilde":"AwfpaOQwAjjfD7Z7/rXrv3F+qqw3R1JvhQJFrBvLCN52k8FcwtVIXWUaQ+D9cGiaaA==","b_tilde":"AggzyoZNliGTjzGvYoT/1z0YvIACmnLv5/+PSjEmvM0SZQFtYv2elSVKC4p+lEPTOQ==","h":"AhL6ktfHJ1U3m80PNAvj+9qqimlBQSP7Jm8kqRl/cQSdQj729BljAAqjwGx9RSVsmg=="},"issuer_public_key":{"alpha":"DCVR1myU23U3freVJYRhzFy20WPOhzqn/JyEZMNN/y+gj7KvdEDKfuVjBMy6z7O4AbU9noh14cse4Dxs06XyQW7skeIDzX8r1P1Ldf4D6w6/xI2tbpdC65LeZYkKpTe0ABWqN14boyg0tZhdFaXti3+MKbZx4A6isA+c9tGoDLhVbFtvvXAY3gyzD4paCwG/AL5yjOcrIqiTiOaHJbEtwkQ/OfC3j/xfuPR1yTTq7sgTlk0HbiTemeopEn10F5pO","beta":"FwWLOfRBAoZKfykEvq26iNn2D64gvwgCfinWWZnG4HotCuomB6EB9qJ0sinpV5LNB6GdkrKU3wvYMUU+fBMX8mtR77E3x/ljbqpwwpcmjB9YtONG1peywJvRhXqhIBJSALFTXAB2Y1XtM63Uw5/CBex8zH3wXyYU6sv/ctKi5bUZ2Zzqua9Q8LMqtgLsrrB9GDKbmPT1einkXVMLX0kuJV/AOTnA57q91HKXMCvlvlKs/sr5mJ70FchdEZl0UHIV"}}
```

----

5 **Alice** receives and aggregates the signed **credential**

***Input:*** credentialIssuerSignedCredential.json ***and*** credentialParticipantKeyring.json

***Smart contract:*** credentialParticipantAggregateCredential.zen

```gherkin
Scenario credential: aggregate signature
Given that I am known as 'Alice'
and I have my 'keyring'
and I have a 'credential signature'
When I create the credentials
Then print my 'credentials'
and print my 'keyring'
```


***Output:*** credentialParticipantAggregatedCredential.json

```json
{"Alice":{"credentials":{"h":"AhL6ktfHJ1U3m80PNAvj+9qqimlBQSP7Jm8kqRl/cQSdQj729BljAAqjwGx9RSVsmg==","s":"AhQPFzhhDn7kJioh1DTXPs4zfm2iIAkX3zhqj92tjZeIRIWdZaaet+hBmpqMMRnKNg=="},"keyring":{"credential":"CKGied4Ww03qmsUM/vnOMDodgwPp9Fc3QJuiFcBGQ/k="}}}
```

----

6 **Alice** produces an anonymized version of the **credential** called **proof**

***Input:*** credentialParticipantAggregatedCredential.json ***and*** credentialIssuerpublic_key.json 

***Smart contract:*** credentialParticipantCreateProof.zen

```gherkin
Scenario credential: create proof
Given that I am known as 'Alice'
and I have my 'keyring'
and I have a 'issuer public key' inside 'MadHatter'
and I have my 'credentials'
When I aggregate all the issuer public keys
and I create the credential proof
Then print the 'credential proof'
```

***Output:*** credentialParticipantProof.json

```json
{"credential_proof":{"kappa":"GNZ+cD1N6IMaqUCtC7028XITDJ3UWdHgGlkDsgqybKRvYxEokDzLNxF10KvPEr3qFvnH37QcaGP76R++yLjlFmKoxX8fol6HwXZWM7EEXd1tHm5ALtOb8LSR+KNNZVo+FACA/9R14D7QaiO8pBSxO5Xtb30J1c+Zamsr5eQuY8m6NvzA1teVH5wjwBDvnubtCmCKN86mcQWp7Y3gZCyprp11fp7MMV2YYf0i39hS8kOa9kDzIypmqXFitqXtC80q","nu":"AwaXYNSgY36mGkPXO832lfzqKKmc309ZuhQBWQPB2ABqi0EOwEk/ENBZ5/biLXpuHA==","pi_v":{"c":"FwleJBD8AqhHHVNSXOrhuyXgkmksJWljF2Tvpm6bv/A=","rm":"UTmcAbKE4Uzj8vbncJpk9O6fuJUmaiHRElOLHIMOy0g=","rr":"PZ6Kdd3vSF2jn1qMALSinm4v0Zk1NFgfn/qWfJXLD9o="},"sigma_prime":{"h_prime":"AhClGrLHKllUz2+RcrIKAWAmfsCzz2OwERAl6ssXOZV1shH781APwR27jyd8MqmBXA==","s_prime":"AgR2e2s17otCJ3MF1X2OO3RMzVoShKseY9nL192nGzWf1YbQp6Lmtjl2hMM4ZrJBWQ=="}}}
```

----

7 **Anybody** matches Alice's **proof** to the MadHatter's **issuer public key**

***Input:***  credentialParticipantProof.json ***and***credentialIssuerpublic_key.json 

***Smart contract:*** credentialAnyoneVerifyProof.zen

```gherkin
Scenario credential: verify proof
Given that I have a 'issuer public key' inside 'MadHatter'
and I have a 'credential proof'
When I aggregate all the issuer public keys
When I verify the credential proof
Then print the string 'the proof matches the public_key! So you can add zencode after the verify statement, that will execute only if the match occurs.'
```

***Output:*** "Success" or else Zenroom throws an error


## Centralized credential issuance

Lets see how flexible is Zencode.

The flow described above is for a fully decentralized issuance of
**credentials** where only the **Holder** is in possession of the
**credential key** needed to produce a **credential proof**.

But let's imagine a much more simple use-case for a more centralized
system where the **Issuer** provides the **Holder** with everything
ready to go to produce zero knowledge credential proofs.

The implementation is very, very simple: just line up all the **When**
blocks where the different operations are done at different times and
print the results all together!

```gherkin
Scenario credential: Centralized credential issuance
Given that I am known as 'MadHatter'
and I have my 'keyring'
When I create the credential key
and I create the credential request
and I create the credential signature
and I create the credentials
When I remove the 'issuer' from 'keyring'
Then print the 'credentials'
and print the 'keyring'
```

This will produce **credentials** that anyone can take and run. Just
beware that in this simplified version of ABC the **Issuer** may
maliciously keep the **credential key** and impersonate the
**Holder**.

# The script used to create the material in this page

All the smart contracts and the data you see in this page are generated by the script [credential.bats](https://github.com/dyne/Zenroom/blob/master/test/zencode/credential.bats). If you need to setup credentials for other flows (such as *petition* and *reflow*), you can use the script  that creates multiple participants at once [zkp_multi_credentials.sh](https://github.com/dyne/Zenroom/blob/master/test/zencode/zkp_multi_credentials.sh)

If you want to run the script (on Linux) you should: 
 - *git clone https://github.com/dyne/Zenroom.git*
 - install  **jq**
 - download a [zenroom binary](https://zenroom.org/#downloads) and place it */bin* or */usr/bin* or in *./Zenroom/src*

Error: File './pages/zencode-scenarios-ecdh' not found.
Error: File './pages/zencode-scenarios-eddsa' not found.
Error: File './pages/zencode-scenarios-bbs' not found.
Error: File './pages/zencode-scenarios-petition' not found.
Error: File './pages/zencode-scenario-dp3t' not found.
Error: File './pages/zencode-scenario-secShare' not found.
# Scenario 'pvss': sharing a secret in parts with publicly verifiable proofs

This scenario contains statements to cryptographically share a secret in parts, to publicly check the validity of the parts, and to recompose it. In the scenario, we assume we have an issuer and some participants. The cryptography is based on Lagrange's interpolation and on the BLS12-381 elliptic curve. It offers:

 - A configurable amount *total* of shares which the secret has to be split into (it corresponds to the number of participants);
 - A configurable *quorum*, which is the minimum amount of shares needed to recompose the secret.

## Initialization

In the first phase of the protocol, each participant needs to create a keypair.
The following script generates a private key:

```gherkin
Scenario pvss
Given I am known as 'Alice'
When I create the keyring
and I create the pvss key
Then print my 'keyring'
```

After executing the script above, the participant creates the public key like so:

```gherkin
Scenario pvss
Given I am known as 'Alice'
Given I have my 'keyring'
When I create the pvss public key
Then print my 'pvss public key'
```

The output should look like:

```json
{"Alice":{"pvss_public_key":"gY5faNGNe4KTnOABxR2xjUcsWAGhaLj0czskvjfYtPbpw/GaBcgMChV+CwjAbo2t"}}
```

## Distribution of the public shares

In the second phase of the protocol, the issuer does the following actions:

- it collects all the public keys of the participants;
- it defines the *secret*;
- it defines *total* and *quorum*;
- it creates a public share for each participant;
- it creates a proof for the validity of all the public shares.

### Issuer creates the public shares

Once the issuer collects all the public keys, it should have an input which looks like:

```json
{
    "pvss_participant_pks": [
        "iNt3+0VE0QWWahdEIQ14t4dpO4/Pw3J6g0LfSUQAbG14kDQN/Pe1dyc6/+0ja94H",
        "tXZ7QIy8dZKRzNNzx1msrj4BMS1H5DXKPNQWdxHLWCUKdYbhEuEg26auYQ7LpDnh",
        "h+HF0NNhVEbW6tcFi7+O6h/gAjehwQol0U+g+IF+Zc3kcuU5EAKkI9GHQc75oTvG",
        "lQkUlMc6lDVWrNy0zihv2QlOgnJjYs+9htrNaPJjyw/MBeIunlSFx4i3rCmzNPFU",
        "luZHQDAd3MQitDIBqu/rrC27mP3sFwGrmuD1sIqs7mr40Z57wRwe5Q4/CCkhRgrT",
        "jUc/GHUYbEaY6L8mCFnJYtUP8s2sqRwxph4d3q7Yj8auSY8G3dTFYSnTLZZdKhHy",
        "mFAEK9EIvzKsMw3/HwF34aNpRtm3nzOxaS9+9qzGXUQT7WnwQnGhhfR0EMDCfU07",
        "hivaOVnaIRBhBgvE95RFA2UIMOlxpjDNuOpbnD4pZuxZgRrYsd1LrDigN6qxa437",
        "uYOkK6sAwyupym4FTG26Ddw/Rv8Yw0TJKdpu56va//9biltYaSUxmBlcgvsWLah/",
        "tIdHaimPwaX/YTx+w71MVSSOpze1ytmNodG/7duQCvSV/kuc/rm2gpJlUuBvazRa"
    ],
    "pvss_s": "TubTlydO4PIGfFROYCFkRtt6mWeDP1o2/G3r8Uv4iBo=",
    "pvss_total" : "10",
    "pvss_quorum" : "6"
}
```

In order to create the public shares and the proof, the issuer executes the following script:

```gherkin
Scenario pvss
Given I have a 'base64' named 'pvss s'
Given I have a 'integer' named 'pvss total'
Given I have a 'integer' named 'pvss quorum'
Given I have a 'pvss public key array' named 'pvss participant pks'
When I create the pvss public shares of 'pvss s' with 'pvss total' quorum 'pvss quorum' using the public keys 'pvss participant pks'
Then print the 'pvss public shares'
and print the 'pvss quorum'
and print the 'pvss total'
```

The output should look like:

```json
{"pvss_public_shares":{"commitments":["tmcEnfihciVABHCScX7Dts3sTAI2r2XGk8+vKXDdzEpulMKG3SDLLJGdt76F3Cvf","og/fTqjfVYVsWwLqph0QFdaosZb1JR/ultMk2s2KWg2zQoChZgZe9y/wdf4mw2Kq","i6o+wy/cPUHr7xjvYXWfi5x+c6FqtSXrHsE+a9CKVZYpFkf6HtHkWMXmntISJbeP","gsdxzO7AbZ0z83vJFGR8CHdzylS0r5tb/QxWCqAd33ZnjaBBdaZZqqq7CgT0+uVw","hfWiGy/JBkmu6A0dFf+YmT4/72dE1xVU/8BCHYczap6HvR2hRxS4+5yjWMcFN8pv","kLmayAZ+B/5Y8eZ/dRLPWQdx9z2XtDRziCC+rIX18mhNcI0afDA0zSjEuT63XS31"],"encrypted_shares":["iRvERL/sxxi4xtKgw2nShMNJ47Q/gspR326ZdC3/xuHjx1meLng8XrLrA7eGrbWQ","tL57o4ouad+3S1ArBP1KbIWXxLNJ9nay0AhpRYywl7VrfrADeftBN/syMpZYG1AZ","pGgI0dLU1ZwFJ0FUiqrebuX12FnVzPbgTd2XHB606mINxq0F0AM8vFkNmwb+QHMo","uLq/otZep2uqB8uP1sczcQmfg2J9alVZQZrIBkKeYxKkGpaPLmF2tbxCrGNW40H7","ol26jmN/BAx2Fl3xt7mCbr2tKRocWn1Z2qEcDA0iZGj46OUf2WNXiwiH/lAB0djX","gA2Sjhtnh0X63nCfxr09TpgnZMXAZu1yZvnFn3Yje6K5wop25gAreHSwUarSPOtX","rnjuuo84qG0UUYacpMJ6oMoAukdWoCWu+0umRLFj//ko6OBVEGxnwPuZpByqBD0S","hizreRLh6cdLGZF+3n3iy2zzrgeamPBBagcHiTSRGvN8SzMQ9FWA1B9WEwSSlqR+","gXO4sk+M8/FttVbV3oxad0lKynMat9v93izZkjr/I9DrbS8S2WSxhz0eLs1qJpMd","tzqHq/qxs52DejnZhlgM9IIxTghbYsVdMDt/bNNbRB7tdcFHyfy6EKQFrBPQjtoD"],"proof":["CpI2oFgj4aEdurV2C4kV8GTzzTeGy96UQr67DgpWVl8=","KKx9WzsCKTTTz3Fs26xl8vruCha6eEPyDnMledsOL8Q=","X3AosByLN5t8jjSbdcD0efJf+m3czCNzq90Wd/qZjZQ=","Tz+Evp+Es6lC9rwzDMR2bbM6nNo68FYfxHCO3YEaQwk=","aP1HPzm7R+9WHjMqyCOKxaoxiD2j5/aQjdHj3f0NiPU=","Mo3KDitqa16yRA30ti5H5OaD2HoVkW1BfVTsftpnU3c=","Rw2FFEYhnrUM9WVR4KKFsbRGSRp9g44pRxtGE8BRPf8=","QjTl8zLMu4MAnX8V1CzGtI2BG+OXsg6ARWDVlJ3ph/M=","TVEQfDBxQV1gshHD1cjRISwMCvcizgQ8yYFAzGnWyug=","ZpfyV6+z7vbTVALmgoP7HspgUelgin1uZb+6DDLQN/E=","FlAzOJgBe6FVUQKxFl86CjB78lFcasZLuEgCRFYFT4Q="],"public_keys":["iNt3+0VE0QWWahdEIQ14t4dpO4/Pw3J6g0LfSUQAbG14kDQN/Pe1dyc6/+0ja94H","tXZ7QIy8dZKRzNNzx1msrj4BMS1H5DXKPNQWdxHLWCUKdYbhEuEg26auYQ7LpDnh","h+HF0NNhVEbW6tcFi7+O6h/gAjehwQol0U+g+IF+Zc3kcuU5EAKkI9GHQc75oTvG","lQkUlMc6lDVWrNy0zihv2QlOgnJjYs+9htrNaPJjyw/MBeIunlSFx4i3rCmzNPFU","luZHQDAd3MQitDIBqu/rrC27mP3sFwGrmuD1sIqs7mr40Z57wRwe5Q4/CCkhRgrT","jUc/GHUYbEaY6L8mCFnJYtUP8s2sqRwxph4d3q7Yj8auSY8G3dTFYSnTLZZdKhHy","mFAEK9EIvzKsMw3/HwF34aNpRtm3nzOxaS9+9qzGXUQT7WnwQnGhhfR0EMDCfU07","hivaOVnaIRBhBgvE95RFA2UIMOlxpjDNuOpbnD4pZuxZgRrYsd1LrDigN6qxa437","uYOkK6sAwyupym4FTG26Ddw/Rv8Yw0TJKdpu56va//9biltYaSUxmBlcgvsWLah/","tIdHaimPwaX/YTx+w71MVSSOpze1ytmNodG/7duQCvSV/kuc/rm2gpJlUuBvazRa"]},"pvss_quorum":"6","pvss_total":"10"}
```

### Anyone verifies the public shares

Given the output found in the previous step, anyone can verify the public shares using the following script:

```gherkin
Scenario pvss
Given I have a 'integer' named 'pvss quorum'
Given I have a 'integer' named 'pvss total'
Given I have a 'pvss public shares'
When I verify the pvss public shares with 'pvss total' quorum 'pvss quorum'
Then print the string 'pvss public shares verification successful'
```

If no errors are returned, then the public shares have been correctly verified.

## Reconstruction of the secret

In the third and last phase of the protocol, each participant does the following actions:

- it computes its own secret share starting from its public one;
- it creates a proof of the validity of its secret share;
- it collects (some of) the secret shares provided by the other participants and it verifies them;
- if it collects at least *quorum* verified secret shares, then it reconstructs the *secret*.

### Participant creates one secret share

In this step, the participant loads all the public shares together with its own keypair, which looks like:

```json
{
    "keyring" : {
        "pvss" : "K+QxIAYwFcdLNq8E3JoQ6f9QpQS2FX7Z6uiuuEaTzBg="
    },
    "pvss_public_key": "iNt3+0VE0QWWahdEIQ14t4dpO4/Pw3J6g0LfSUQAbG14kDQN/Pe1dyc6/+0ja94H"
}
```

Then, the participant executes the following script:

```gherkin
Scenario pvss
Given I have a 'keyring'
Given I have a 'pvss public key'
Given I have a 'pvss public shares'
When I create the secret share with public key 'pvss public key'
Then print the 'pvss secret share'
```

The output should look like:

```json
{"pvss_secret_share":{"dec_share":"gjoMbXIE6XgyqhxHDnKn2T5DfpgEfSfgvNGgoAvio8+foUW4zM4Ngb+K1+fMeaqj","enc_share":"iRvERL/sxxi4xtKgw2nShMNJ47Q/gspR326ZdC3/xuHjx1meLng8XrLrA7eGrbWQ","index":"1","proof":["VhUX6OilGEI1MSng9312NQn+EXNGVZFswARNDvt/hC0=","Q1mIWMWs63jkk41Slc8tahOYfBRnMtjIOAHbX+cp5Lg="],"pub_key":"iNt3+0VE0QWWahdEIQ14t4dpO4/Pw3J6g0LfSUQAbG14kDQN/Pe1dyc6/+0ja94H"}}
```

### Participant verifies secret shares of the others

Each participant now collects some secret shares provided by other participants in a json which looks like:

```json
{
"pvss_secret_shares" : [
    {"dec_share":"gTJ3xhArivens+O+uOT9nj6QoeHW7qVl7f+Q9eCX/Ko9wvtm5YOhFmHW6LepXAlq","enc_share":"gXO4sk+M8/FttVbV3oxad0lKynMat9v93izZkjr/I9DrbS8S2WSxhz0eLs1qJpMd","index":"9","proof":["YknKionYWDaIUYRxQKBHImQoZa+/2SyIqtlXKtwP8po=","G2Jam5rHeMPStUoDRUFcj2qs79sW21jO4VZSE6erGP4="],"pub_key":"uYOkK6sAwyupym4FTG26Ddw/Rv8Yw0TJKdpu56va//9biltYaSUxmBlcgvsWLah/"},
    {"dec_share":"qXIBaWuWTEylR5yP1e8EYLwyhG0dNz80kZ7qXu/4s8m7s4T5eDZWLt0hLsyU+alB","enc_share":"tzqHq/qxs52DejnZhlgM9IIxTghbYsVdMDt/bNNbRB7tdcFHyfy6EKQFrBPQjtoD","index":"10","proof":["bVjHOmtNox3VgA6C3VB8UQD8TicFPCxyNeasB4CKpVY=","RqcYBaTfmz446V0Ns2J3phRMXWmZASOsBONMG8+tKkY="],"pub_key":"tIdHaimPwaX/YTx+w71MVSSOpze1ytmNodG/7duQCvSV/kuc/rm2gpJlUuBvazRa"},
    {"dec_share":"gjoMbXIE6XgyqhxHDnKn2T5DfpgEfSfgvNGgoAvio8+foUW4zM4Ngb+K1+fMeaqj","enc_share":"iRvERL/sxxi4xtKgw2nShMNJ47Q/gspR326ZdC3/xuHjx1meLng8XrLrA7eGrbWQ","index":"1","proof":["VhUX6OilGEI1MSng9312NQn+EXNGVZFswARNDvt/hC0=","Q1mIWMWs63jkk41Slc8tahOYfBRnMtjIOAHbX+cp5Lg="],"pub_key":"iNt3+0VE0QWWahdEIQ14t4dpO4/Pw3J6g0LfSUQAbG14kDQN/Pe1dyc6/+0ja94H"},
    {"dec_share":"rZGJ+iXuRT92oXhBJlatVtPmFb6pe7CSu0Iy47Z1kJnIA/LQUxiPsGuS+y2O+Hm3","enc_share":"tL57o4ouad+3S1ArBP1KbIWXxLNJ9nay0AhpRYywl7VrfrADeftBN/syMpZYG1AZ","index":"2","proof":["MfoFfP2Vdlk3jSDpU3AMEpGxdw4oInT38qREUjjezWw=","WTFphl5I8DbsTP+7v0dSHl1Z/iqWQRoWOQ60K+82f0s="],"pub_key":"tXZ7QIy8dZKRzNNzx1msrj4BMS1H5DXKPNQWdxHLWCUKdYbhEuEg26auYQ7LpDnh"},
    {"dec_share":"ht5U2Y+HxaDZH0d+DK2ao8r+HhSMKKfRS6ois7fVoOYpcnQIYb0gi7AFBJS1Se15","enc_share":"pGgI0dLU1ZwFJ0FUiqrebuX12FnVzPbgTd2XHB606mINxq0F0AM8vFkNmwb+QHMo","index":"3","proof":["BCHGhyutkqeUP/V6HAQ7fcZmYAOj1Em46WHVk7oRdzk=","LrdBBK9VbSBnBOY1AGH8TBDtnt5Dhcuf4yaDLrj4DJ4="],"pub_key":"h+HF0NNhVEbW6tcFi7+O6h/gAjehwQol0U+g+IF+Zc3kcuU5EAKkI9GHQc75oTvG"},
    {"dec_share":"mP3mLreKRVe/7bQHyxmNW7nNPYzk0E0YXwaeb9qEBUcVTZWkL9gG7JoyVXpZkUgi","enc_share":"uLq/otZep2uqB8uP1sczcQmfg2J9alVZQZrIBkKeYxKkGpaPLmF2tbxCrGNW40H7","index":"4","proof":["C8opO1p5eMDMNLVgMpnc/5og7uvGjbGP/PA0UQovPME=","VFat/LT/n78HQZbvXmal4psjuNWAsiIrrafE0bApv1Y="],"pub_key":"lQkUlMc6lDVWrNy0zihv2QlOgnJjYs+9htrNaPJjyw/MBeIunlSFx4i3rCmzNPFU"},
    {"dec_share":"qmN7TaCej/IBVj+0npR0Fz/OM966Kb+Da9uiHXwCCxxqCt4Bmybx46zKtm000d1h","enc_share":"ol26jmN/BAx2Fl3xt7mCbr2tKRocWn1Z2qEcDA0iZGj46OUf2WNXiwiH/lAB0djX","index":"5","proof":["U4iwNH4SAZ7B37roQOghVr5ga17Tzs/TxILErew2fzk=","QlagPeEGHgP+sESy0w0cKjLcHegQhteNyKXz6Mp6omk="],"pub_key":"luZHQDAd3MQitDIBqu/rrC27mP3sFwGrmuD1sIqs7mr40Z57wRwe5Q4/CCkhRgrT"},
    {"dec_share":"snH4Ic2dAnu1la0ltHKzAN925Tb+bkNIQNynTCuInyy9nu2Qyiaze8JZ2rFq77mw","enc_share":"gA2Sjhtnh0X63nCfxr09TpgnZMXAZu1yZvnFn3Yje6K5wop25gAreHSwUarSPOtX","index":"6","proof":["BYdXA1izaZDsT86YGpoaa1PWJoj8/sK/jQ3+1Znvrm8=","YWbDhNeawOaMdVYNUaPyBuyNhMH5S0UhFI9ldMiw1gI="],"pub_key":"jUc/GHUYbEaY6L8mCFnJYtUP8s2sqRwxph4d3q7Yj8auSY8G3dTFYSnTLZZdKhHy"},
    {"dec_share":"pzR4kf73TnFXv17XktP9ayKKmVWw9gEVzpk8WGnt+QtOLm7OJUcLBbMiT5ulH+sl","enc_share":"rnjuuo84qG0UUYacpMJ6oMoAukdWoCWu+0umRLFj//ko6OBVEGxnwPuZpByqBD0S","index":"7","proof":["WSk4JjbmqBmRlYub6LJisKno7FY6Yc2ljSYFfSLn06k=","TDmXrnuKGH45pFER4PshDU34XML06Pn9hcuKIwujpeY="],"pub_key":"mFAEK9EIvzKsMw3/HwF34aNpRtm3nzOxaS9+9qzGXUQT7WnwQnGhhfR0EMDCfU07"},
    {"dec_share":"sMxqKdrZpmP0VKjvDI2u4W4n/UJcVDwEnvZrtS866oAOh3rUtL2Ra3/T2LL2EIjD","enc_share":"hizreRLh6cdLGZF+3n3iy2zzrgeamPBBagcHiTSRGvN8SzMQ9FWA1B9WEwSSlqR+","index":"8","proof":["Ee2o8XVYl0GkADaD0/S/KZj9AbI00hrVNciSSEDFOX8=","NShq0xZjqprBwV4M3IvYhijYUoQ2j7mJBzCtlp1obaQ="],"pub_key":"hivaOVnaIRBhBgvE95RFA2UIMOlxpjDNuOpbnD4pZuxZgRrYsd1LrDigN6qxa437"}
]
}
```

With such input, the participant can now execute the following script:

```gherkin
Scenario pvss
Given I have a 'pvss secret share array' named 'pvss secret shares'
When I create the pvss verified shares from 'pvss secret shares'
Then print the 'pvss verified shares'

```

The output should look like:

```json
{"pvss_verified_shares":{"valid_indexes":["9","10","1","2","3","4","5","6","7","8"],"valid_shares":["gTJ3xhArivens+O+uOT9nj6QoeHW7qVl7f+Q9eCX/Ko9wvtm5YOhFmHW6LepXAlq","qXIBaWuWTEylR5yP1e8EYLwyhG0dNz80kZ7qXu/4s8m7s4T5eDZWLt0hLsyU+alB","gjoMbXIE6XgyqhxHDnKn2T5DfpgEfSfgvNGgoAvio8+foUW4zM4Ngb+K1+fMeaqj","rZGJ+iXuRT92oXhBJlatVtPmFb6pe7CSu0Iy47Z1kJnIA/LQUxiPsGuS+y2O+Hm3","ht5U2Y+HxaDZH0d+DK2ao8r+HhSMKKfRS6ois7fVoOYpcnQIYb0gi7AFBJS1Se15","mP3mLreKRVe/7bQHyxmNW7nNPYzk0E0YXwaeb9qEBUcVTZWkL9gG7JoyVXpZkUgi","qmN7TaCej/IBVj+0npR0Fz/OM966Kb+Da9uiHXwCCxxqCt4Bmybx46zKtm000d1h","snH4Ic2dAnu1la0ltHKzAN925Tb+bkNIQNynTCuInyy9nu2Qyiaze8JZ2rFq77mw","pzR4kf73TnFXv17XktP9ayKKmVWw9gEVzpk8WGnt+QtOLm7OJUcLBbMiT5ulH+sl","sMxqKdrZpmP0VKjvDI2u4W4n/UJcVDwEnvZrtS866oAOh3rUtL2Ra3/T2LL2EIjD"]}}
```

### Participant reconstructs the secret

At this step, using the output of the last step and the *quorum* extracted from the public shares, the participant can execute the following script:

```gherkin
Scenario pvss
Given I have a 'integer' named 'pvss quorum'
Given I have a 'pvss verified shares'
When I compose the pvss secret using 'pvss verified shares' with quorum 'pvss quorum'
Then print the 'pvss secret'
```

The output should look like:

```json
{"pvss_secret":"rLSMxqqNGVZ2IEOIrN1xBDbOh5VNgNzM24qc+jI7hCV9ycP3xBSjeH1m8gOSkqVR"}
```

# The script used to create the material in this page

All the scripts and the data you see in this page are generated by the pvss script [pvss.bats](https://github.com/dyne/Zenroom/blob/master/test/zencode/pvss.bats). If you want to run the script (on Linux) you should: 
 - *git clone https://github.com/dyne/Zenroom.git*
 - install  **jq**
 - download a [zenroom binary](https://zenroom.org/#downloads) and place it */bin* or */usr/bin* or in *./Zenroom/src*
Error: File './pages/zencode-cookbook-w3c-vc' not found.
Error: File './pages/zencode-scenario-reflow' not found.




This scenario enables the creation of HTTP GET requests, by appending parameters to base URLs.
The formed GET requests can be called using [Restroom-mw's http statements](https://dyne.github.io/restroom-mw/#/packages/http), using **curl** or other. 
 


You would load a base url:

```json
{ 
     	"base-url": "http://www.7timer.info/bin/api.pl"
}
```


And then load the parameters: 

```json
{ 
	"lon": "113.17",
	"lat": "23.09",
	"product": "astro",
	"output": "json"
}
```

The basic script to generate the GET looks like this:

```gherkin
Scenario 'http': create a GET request concatenating values on a HTTP url

# The base URL and the parameters are loaded as strings
Given I have a 'string' named 'base-url'
Given I have a 'string' named 'lon'
Given I have a 'string' named 'lat'
Given I have a 'string' named 'product'
Given I have a 'string' named 'output'

# The statement 'create the url' creates an object to which parameters 
# can be appended to create a valid GET request
When I create the url from 'base-url'

# And here are the parameters to be appended to the query
# They are appended as 'key=value&'
When I append 'lon'     as http request to 'url'
When I append 'lat'     as http request to 'url'
When I append 'product' as http request to 'url'
When I append 'output'  as http request to 'url'

Then print the 'url'

```


Note that the parameters are added in the order they're appended in the script. The result should look like: 

```json
{"url":"http://www.7timer.info/bin/api.pl?lon=113.17&lat=23.09&product=astro&output=json"}
```


# The script used to create the material in this page

All the smart contracts and the data you see in this page are generated by the script [http.bats](https://github.com/dyne/Zenroom/blob/master/test/zencode/http.bats). If you want to run the script (on Linux) you should: 
 - *git clone https://github.com/dyne/Zenroom.git*
 - install  **jq**
 - download a [zenroom binary](https://zenroom.org/#downloads) and place it */bin* or */usr/bin* or in *./Zenroom/src*
 
 



The Schnorr signature is a digital signature algorithm which was described by Claus Schnorr in 1989 and it was patented until February 2008. The scheme security is based on the supposed intractability of the Discrete Logarithm problem. In 2018 its Elliptic-curve version was proposed to substitue ECDSA in the bitcoin universe, this was done in the [BIP-340](https://github.com/bitcoin/bips/blob/master/bip-0340.mediawiki). In **Zenroom** you can find its implementation over BLS12-381 Elliptic-curve.

# Key generation

On this page we prioritize security over easy of use, therefore we have chosen to keep some operations separated. Particularly the generation of private and public key, which can indeed be merged into one script, but you would end up with both the keys in the same output. 

## Private key
The script below generates a **schnorr** private key. 

```gherkin
Rule check version 2.0.0
Scenario schnorr: Create the schnorr private key
Given I am 'Alice'
When I create the schnorr key
Then print the 'keyring'
```

The output should look like this: 

```
{"keyring":{"schnorr":"XdjAYj+RY95+uyYMI8fR3+fmP5LyQaN54vyTTVKxZyA="}}
```

### Generate a private key from a known seed 

Key generation in Zenroom uses by default a pseudo-random as seed, that is internally generated. 

You can also opt to use a seed generated elsewhere, for example by using the [keypairoom](https://github.com/ledgerproject/keypairoom) library or it's [npm package](https://www.npmjs.com/package/keypair-lib). Suppose you end with a **Schnorr private key**, like:

```
{
"private_key": "WNChjG0F+Rc11221ua4NI3p8yMKNVHb9macGAgTA3YI="
}
```

Then you can upload it with a script that look like the following script:

```gherkin
Rule check version 2.0.0 
Scenario schnorr : Create and publish the schnorr public key
Given I am 'Alice'
and I have a 'base64' named 'private key'

# here we upload the key
When I create the schnorr key with secret key 'private key'
# an equivalent statement is
# When I create the schnorr key with secret 'private key'

Then print the 'keyring'
```

Here we simply print the *keyring*.

## Public key 

Once you have created a private key, you can feed it to the following script to generate the **public key**:

```gherkin
Rule check version 2.0.0 
Scenario schnorr : Create and publish the schnorr public key
Given I am 'Alice'
and I have the 'keyring'
When I create the schnorr public key
Then print my 'schnorr public key' 
```

The output should look like this: 

```json
{"Alice":{"schnorr_public_key":"BR98Dh6XMl3xXwdLD2+smhOQyCjBlEnLxMV6V0tRWBUBoJLAWs1WEAgZ2nbhdoUh"}}
```

# Signature

In this example we'll sign three objects: a string, a string array and a string dictionary, that we'll verify in the next script. Along with the data to be signed, we'll need the private key. The private key is in the file we have generate with the first script, while the one with the messages that we will sign is the following:

```json
{
"message": "Dear Bob, this message was written by Alice, you can verify it!" ,
"message array":[
	"Hello World! This is my string array, element [0]",
    	"Hello World! This is my string array, element [1]",
    	"Hello World! This is my string array, element [2]"
	],
"message dict": {
	"sender":"Alice",
	"message":"Hello Bob!",
	"receiver":"Bob"
	}
}
```

The script to **sign** these object look like this:

```gherkin
Rule check version 2.0.0 
Scenario schnorr : Alice signs the message

# Declearing who I am and load all the stuff
Given I am 'Alice'
and I have the 'keyring'
and I have a 'string' named 'message'
and I have a 'string array' named 'message array'
and I have a 'string dictionary' named 'message dict'

# Creating the signatures and rename them
When I create the schnorr signature of 'message'
and I rename the 'schnorr signature' to 'string schnorr signature'
When I create the schnorr signature of 'message array'
and I rename the 'schnorr signature' to 'array schnorr signature'
When I create the schnorr signature of 'message dict'
and I rename the 'schnorr signature' to 'dictionary schnorr signature'

# Printing both the messages and the signatures 
Then print the 'string schnorr signature'
and print the 'array schnorr signature'
and print the 'dictionary schnorr signature'
and print the 'message'
and print the 'message array'
and print the 'message dict'
```

And the output should look like this:

```json
{"array_schnorr_signature":"EkJHXWssdxcgnsq3WGhEJsz4ZKAae6o4gM9d5DYzZ+u0BD2ZQkrkci2UKba5OntNaXIPAO34/5YvOy6fIKRqWfHnaWVkYyTbCQsFrcIA8do=","dictionary_schnorr_signature":"CmjYfc64tnfTcxssg6pN85jUQhmTeBs53IdLNLK2GmWoAIgcq9igMuoIr+r9MDV2R07hBJUrnvFJ0l1wtvMd6LwJ7PrU9ED118Nkx7qpXLY=","message":"Dear Bob, this message was written by Alice, you can verify it!","message_array":["Hello World! This is my string array, element [0]","Hello World! This is my string array, element [1]","Hello World! This is my string array, element [2]"],"message_dict":{"message":"Hello Bob!","receiver":"Bob","sender":"Alice"},"string_schnorr_signature":"FZIUilXZ7y+6JM6uGhQqfRhHmPGlqWRadcIVD1c8xKeIYMcpodRf6CsqYYk2ZZkOO9zeH/nXKqIyApSxw76b4GsY1lbG5lX1rMWBjM30mQ8="}
```

You can now merge this file with the one where your schnorr public key is, so that the verifier has everything he needs in one file. You can do it by either use the bash command:

```bash
jq -s '.[0]*[1]' pubkey.json signature.json | tee data.json
```

where pubkey.json contains the output of the third script and signature.json the output of the above script, or by adding two rows in the previous script, one where you compute the schnorr public key and the other where you print it.

# Verification

In this section we will verify the signatures produced in the previous step. As mentioned above what we will need are the signatures, the messages and the signer public key. So the input file should look like:

```json
{
  "Alice": {
    "schnorr_public_key": "BR98Dh6XMl3xXwdLD2+smhOQyCjBlEnLxMV6V0tRWBUBoJLAWs1WEAgZ2nbhdoUh"
  },
  "array_schnorr_signature": "EkJHXWssdxcgnsq3WGhEJsz4ZKAae6o4gM9d5DYzZ+u0BD2ZQkrkci2UKba5OntNaXIPAO34/5YvOy6fIKRqWfHnaWVkYyTbCQsFrcIA8do=",
  "dictionary_schnorr_signature": "CmjYfc64tnfTcxssg6pN85jUQhmTeBs53IdLNLK2GmWoAIgcq9igMuoIr+r9MDV2R07hBJUrnvFJ0l1wtvMd6LwJ7PrU9ED118Nkx7qpXLY=",
  "message": "Dear Bob, this message was written by Alice, you can verify it!",
  "message_array": [
    "Hello World! This is my string array, element [0]",
    "Hello World! This is my string array, element [1]",
    "Hello World! This is my string array, element [2]"
  ],
  "message_dict": {
    "message": "Hello Bob!",
    "receiver": "Bob",
    "sender": "Alice"
  },
  "string_schnorr_signature": "FZIUilXZ7y+6JM6uGhQqfRhHmPGlqWRadcIVD1c8xKeIYMcpodRf6CsqYYk2ZZkOO9zeH/nXKqIyApSxw76b4GsY1lbG5lX1rMWBjM30mQ8="
}
```

The script to verify these signatures is the following:

```gherkin
Rule check version 2.0.0 
Scenario schnorr : Bob verifies Alice signature

# Declearing who I am and load all the stuff
Given that I am known as 'Bob'
and I have a 'schnorr public key' from 'Alice'
and I have a 'string' named 'message'
and I have a 'string array' named 'message array'
and I have a 'string dictionary' named 'message dict'
and I have a 'schnorr signature' named 'string schnorr signature'
and I have a 'schnorr signature' named 'array schnorr signature'
and I have a 'schnorr signature' named 'dictionary schnorr signature'

# Verifying the signatures
When I verify the 'message' has a schnorr signature in 'string schnorr signature' by 'Alice'
and I verify the 'message array' has a schnorr signature in 'array schnorr signature' by 'Alice'
and I verify the 'message dict' has a schnorr signature in 'dictionary schnorr signature' by 'Alice'

# Print the original messages and a string of success
Then print the 'message'
and print the 'message array'
and print the 'message dict'
Then print string 'Zenroom certifies that signatures are all correct!'
```

The result should look like:

```json
{"message":"Dear Bob, this message was written by Alice, you can verify it!","message_array":["Hello World! This is my string array, element [0]","Hello World! This is my string array, element [1]","Hello World! This is my string array, element [2]"],"message_dict":{"message":"Hello Bob!","receiver":"Bob","sender":"Alice"},"output":["Zenroom_certifies_that_signatures_are_all_correct!"]}
```


# The script used to create the material in this page

All the smart contracts and the data you see in this page are generated by the scripts [generic_schnorr.bats](https://github.com/dyne/Zenroom/blob/master/test/zencode/generic_schnorr.bats) . If you want to run the scripts (on Linux) you should: 
 - *git clone https://github.com/dyne/Zenroom.git*
 - install  **jq**
 - download a [zenroom binary](https://zenroom.org/#downloads) and place it */bin* or */usr/bin* or in *./Zenroom/src*

# Post-Quantum cryptography

The QP stands for [Post-Quantum](https://en.wikipedia.org/wiki/Post-quantum_cryptography) cryptography. The need for these cryptographic primitives is due to the threat posed by quantum computers, in particular from the [Schor's algorithm](https://en.wikipedia.org/wiki/Shor%27s_algorithm) and the [Grover's algorithm](https://en.wikipedia.org/wiki/Grover%27s_algorithm), to the modern cryptography. Regarding the symmetric cryptography this attack can be simply avoided by doubling the length of the secret key. On the other hand the situation for the public key cryptography is worst and the only way out is to use new cryptographic schemes resistant to Quantum computer, so we need new Signature and public key schemes.

In Zenroom, using the *Scenario qp*, you will have access to the following Post-Quantum algorithms:
- Signatures:
  - **Dilithium2** from the [NIST PQC Competition](https://csrc.nist.gov/Projects/post-quantum-cryptography/selected-algorithms-2022)
  - **ML-DSA-44** under standardization by NIST in [FIPS-204](https://csrc.nist.gov/pubs/fips/204/final)
- Key Encapsulation Mechanisms: 
  - **Kyber512** from the [NIST PQC Competition](https://csrc.nist.gov/Projects/post-quantum-cryptography/selected-algorithms-2022)
  - **Streamlined NTRU Prime 761** used by [OpenSSH](https://www.openssh.com/txt/release-9.0
  - **ML-KEM-512** under standardization by NIST in [FIPS-203](https://csrc.nist.gov/pubs/fips/203/final)

# Dilithium2

Dilithium2 is a Post-Quantum signature algorithm defined over lattices. From the user side it works as a modern signature scheme:
- **Key generation**: The *signer* create its private and public keys
- **Signature**: The *signer* use its private key to sign a certain message and sent it to the verifier
- **Verification**: The *verifier*, using the *signer* public key, can verify the authenticity of the message

## Key Generation

### Private key

The script below generates a **dilithium** private key.

```gherkin
Rule check version 2.0.0
Scenario qp : Create the dilithium private key
Given I am 'Alice'
When I create the dilithium key
Then print the 'keyring'
```

The output should look like this:

```
{"keyring":{"dilithium":"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"}}
```

### Public key

Once you have created a private key, you can feed it to the following script to generate the **public key**:

```gherkin
Rule check version 2.0.0 
Scenario qp : Create and publish the dilithium public key
Given I am 'Alice'
and I have the 'keyring'
When I create the dilithium public key
Then print my 'dilithium public key' 
```

The output should look like this:

```json
{"Alice":{"dilithium_public_key":"w0XwSGhAhDaLDOrIn63/diFlkTBoxg0XT7gljo6eGEQxeblRp7rq3Zvy+ykzJKu/31+CR3v2EK76xQjhXsnw6eA6/fP+b0qqHOzsOKzSOLSSWesYlidkt+yQtjYA3wEFD/BASU1URDie2vr3A6EQojsjHRdS6Dt7SL3PqZrAREnMx75b1RAWhdDr5EEtTGC7Bp8pV+R6ZB2M4cYqV4VnuX+eAFjAGyRVKJNW0zDXJiBfthuUU/qIoC5HwlrWKCw2r8KFCsVPzc/ssLYICWiapi0Kf65qHOfNRM5CzeBRIK3w990CSh7Q3RRXwYXj4b9uqXzhtEycmHI7RsYRTU4bOFervZ7BK2MmfWdWzHpLJGLesAAoyPT1YKqv+xmVvkT30Oy7gfSAjZMKWkTTqUG6weIhuD9XndYp25t8HarHqlk7OLdGQwR34mkhlP4wcvRGr0VQiiDITUbVlHw5cy9pirq/seUyqz+U4UqH5zykks3jOVr5cT0xoyhS0U6Rvu8IT62bDtbpyCSQf+dM0Vmn++7sydQ3y7r4MSqIzeJp7YN826lKj0jERusRA3p2Kl1Y0FFBgm6UV/cJ2gezPqu1jY0kLXFeuY7Tf2mKMes/F4Iz9VXmEkusn2rE+Suw89H+LYWU9NgxPwgQ9KJCgzcs4Fbgt7mzhMsuPoiArg/RhV9X72obutoCG23uWaHBdLb7thk3yD3i36Pf34rlf5dKreFXznDMVd69fI7CoEJP2DbBCTbOlVJFgItxUlWYw7MM0HxvxFe4xSkKkIbUKTuHnOtLgrgOMtD4pvpKjkAAYnJYsYWzHIgZv96d6DC5KoDg+UUBd2XeHELUaBnEwbfaxEegGqTlpECQC2r80r7/jP8nchaX/34yQQ1rnYZfXl8QcvvPOPjyxwKQrrnSPDw7hw6HBY+UmnQ4KWImxdhXaIS25XtjdKAALatSRAtSwqXNsb1ifSoqSvcb3FN+6WWFEjTFETchBPOi4mR6IN8OuRjh/VPh+kyg41R6HBqJB60WkmI6g1Ug+YARS6gAIydlgNZ6XCKKXcg968XwS5PvhXcCcIbK7+4sqJ8VMFhG17yjpwiwS4Dyju3Tq2tbKAaLKAQ+OCSrk4Uk+WKWDdqkEW1Af3DK9IAx+H0ihSpoWZQmnO3Rhw6OO6I5P1TDu601ZSu8I0X9PxI5ICGU48mhNies1icKJ4sqVPDkSR6L3oHYWb7AhgptuVTK5d4d9XpeG23JAEt8qBiIFQF3sDGcuJoMudsGavaM99tlfW6fOmIeXbhnqNq6jpbutOYTPm1mIhQ6rYFYhCoYwo/2HtL4WV+PIaBvzEg//JKPeQ9i0O4NgSkDV6NHMguoA0zhR5uvqt/d1DXhP14GWq9h4vB68GeIVVjGTcHpqcxLCqRfAGzrWJY7e8bHhhdSAUlDRH5KpJzqVURpOabh4VyookqcqRWrKdARKogXJlfKAP1k7Ju5ytJ3gzwmQuEaWA7eznMzLUv/tok7kOPbfLQjQ8+JuVq1nSYY4mWT/VkzR6F1zRwZK63zbppinmoxbspcz6KPrfCpGpZ4Xj9ZSB2RNUVwWodQZx3CWXq2tYgZiGip762aG+uEc+Fk70/TMRYIUxFhqiLxygnWooxCFxKBAS+Nk/SSt571ynYvGOAEDfU+agKa6Q1bRntH30rom7hsu0HgRqOyLt0WbOK8uQ9leAFp+b4zQtBQudHZTUKUAbwNIZlZK2rklL3efRfAKGGnvvnAcg=="}}
```

## Signature

In this example we'll sign three objects: a string, a string array and a string dictionary, that we'll verify in the next script. Along with the data to be signed, we'll need the private key. The private key is in the file we have generate with the first script, while the one with the messages that we will sign is the following:

```json
{
"message": "Dear Bob, this message was written by Alice and signed with Dilithium!" ,
"message array":[
	"Hello World! This is my string array, element [0]",
	"Hello World! This is my string array, element [1]",
	"Hello World! This is my string array, element [2]"
	],
"message dict": {
	"sender":"Alice",
	"message":"Hello Bob!",
	"receiver":"Bob"
	}
}
```

The script to **sign** these objects look like this:

```gherkin
Rule check version 2.0.0 
Scenario qp : Alice signs the message

# Declearing who I am and load all the stuff
Given I am 'Alice'
and I have the 'keyring'
and I have a 'string' named 'message'
and I have a 'string array' named 'message array'
and I have a 'string dictionary' named 'message dict'

# Creating the signatures and rename them
When I create the dilithium signature of 'message'
and I rename the 'dilithium signature' to 'string dilithium signature'
When I create the dilithium signature of 'message array'
and I rename the 'dilithium signature' to 'array dilithium signature'
When I create the dilithium signature of 'message dict'
and I rename the 'dilithium signature' to 'dictionary dilithium signature'

# Printing both the messages and the signatures
Then print the 'string dilithium signature'
and print the 'array dilithium signature'
and print the 'dictionary dilithium signature'
and print the 'message'
and print the 'message array'
and print the 'message dict'
```

And the output should look like this:

```json
{"array_dilithium_signature":"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","dictionary_dilithium_signature":"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","message":"Dear Bob, this message was written by Alice and signed with Dilithium!","message_array":["Hello World! This is my string array, element [0]","Hello World! This is my string array, element [1]","Hello World! This is my string array, element [2]"],"message_dict":{"message":"Hello Bob!","receiver":"Bob","sender":"Alice"},"string_dilithium_signature":"yyWHoPQL1xu/dpinV2hMfIqPWOYt0BZT+z5I/SXZ61El7zXLK/VpFF6CthgMiigUyVvSQ/RSWU55+L8k/4Ar9YXeLFWmkzoIYM84wFKh/r55AdzOxgpZvDaNvc6IkNkj3A8PgSg2o844ibgfPKszHzzcCF6sdWZhaAJpRZU+IO+Rko110bdXgQy3hvuQ2xkm3L4hNSmNCVBoG1wAkDqTVpXeHXy95l9hUQFuLwEL/tmMrtaja4R1t7ttaofUeSSlTUCq0ImhkGvlhNkwvfHWz8vdUpsHP/etW66+hDANEhXoszXHBkhOWyXoLvJuN5P0HLSuNjRhVnAyAW4C4OieJjIsYSz0H2WHxA8LtEhDeTUHxUELbPldv6/c/vFM0iRluCPsaEJEzkyaAeOZkM0MZwrVo+BwuOmgMt8eVzv80GKmrCBehsJc5qMoG8tr7SJGjlaoYfwU5EdxHxOojE6wCcA36dTD9YUWOQ+cmk1vNBrqTsjg5b++ki2f+pTwkKIA2pk/RdJveZUhbKnJdg03S1TzLdyWnjEI4v6jjE+CwaK0dmM66FP86/QopQZdvtnn+s69oMFew39ipbM7z73Xp2rpac8ytFR7Gztj0xrusAVnV8zLn8BnGGiwKBA++OgLgskix54c4lvimYmjoI1IiGI1L6/xiTYXBu/3fjfjljtUMzvwZzwBiNV09Q4pe2lsjV9FwAmuCmAbGWo9DV05mFMYPK7Q1gAtOQYhrg+kMidY64uBJq8xv24Udu7fezB78TLLaqP9FKlHdgX0Dm/iqnWDM0UiQETDTV2Pf4nUN2UlOBSMoTlszJPs2bShoJEk3di5m5lBL+kSjvwEBQvDkyrLMNzdGeEDDcVRnI4ByjR4dpfD/JTmyEazH2IMPwnF+KPsDTdFCDO4/jN8IHO/1vyL31/SobuhjL709P6wOf4PeK3OzE8l0wWaNyqKpMwgCSHJ1Xk4LWD/ZUCDS+7LCh/iPkJiTDFv/IVtpVq+xxB2pSnEeSYQ4iJtBDPJZNYpIAV1q/4tc5WWRT7eXIsClpG1bAQ1rjTVk7O8/rR4fYP8Oi9Iukzo+4sCEQqwHTCDyNLALGyYK7UDY3Vv529S951levhc6gS02D5iYV11tZ99MWlZeTJFBidN8hpwGsXdg0iO1fRkIQgsLDJARfh7Gn+fqwlGKDabuu1NwOv6Ce+qorMvp1mmjcSslM09P4ysCB5rlV8++kBI1b9KS8AK41/FRuzO2uCMAUN0ZYKVNCX+rYSZv9kRWIeotcvVN9Hyv06ArNe6ZVyYr/FNhxT3dsww9XjAMSCnaAfM6rSTdZastC4w9uEBbF+nb9E6SwkMvQfTmqRvtGgRU2nsASd83yFkjqbPJEDjKb9XPjut2rPw0Z+I9pzuPGBw+ShcyuUCZ3TCCcXnW51h2NxXYeCHa7y4+XeRE86tf30pvclb6A6f6fWz04NXA9KZ8cbvQP6qMP8zJQaL+3moq+K/a8gvfO1ZuPiu4aMj+TsSqMxAEteR9QdvjbFZ+j3w2ipg6PbNT6xH7dNIwBjvznylauFSozYYtpjpiUyjNG6Dil94YI4n2feTKkKA/R9sCuRA4B+/FPzymfbGdwYiKJRG9m2K6EkXdjFWlmovYnANujCd/2E1v6IEV0u4XqhR7IyiG210QqNwi5oFSTPtx0LQyW9lbLx7d9R10e17UVdfohf6xsMmabYZ0/R32Tvu/yBZIPRTCDJ90swx5DHFFr1Q/pbsTgiCbyiD0oevrcykZo6fZ/nHM8Y6ulceQoNo/p/DQ7hJBiOyQPwAtl1BXKUgL1/3mGG7wBpXb8gkJZ1+5Mq8S9qS2pK6gr15gK+NaMuP/c8KzyM9LvZGtPhndwJMQJzf8yEcKsk3r2dQ8p1d25ObKos/exogLrfvNN4DjwDlh0OFfC5eD2JiyqfvaPYKNnZehUkilc0xHuEx+pc191vtcTEHNsVezQ/fENH9Oad8AHYNAuU7zs4wbcpr7uLcsdZuvRDozTc2cvNXPTGLtBu/P08fuFMg2QMUBt0oN0NGCbjKvXunTHo8GqA31Cf8goELCiXTqUgpIBpQjo0JK9X/pKNliGoLBPoiWyljer4S/9s8I5Id9p96gVxjjZTEetJKTm6bMCUqYixzE3pj10KSFDN0B8XYIl126wBW8aG+Jm+Bi0FntTSlejoVe+mpcOh9zj2G/dPVQ2ctRjO/FNYKMmyD7pOpgYoE1SXYpN3uk+r+y/9Dzj2SnXhxK6CDmoSyoZnJjAUcskl0RfChZ4NrgZUMTbQnl8gWTBfIlneUan4pPmt8oshveOUgwCbT0KyZ8cWNlOY/NIcP9gJwx62gKk1hLGZC3EyKUfuO7yb0Ni3JM5MonlJ8rSoRJiBT5p0k6MO1PksJPyQReggJhxri0YwWHo3rM0+icHDwDcIsGdUZRdVuzcoY1uiPoJUMlV/v+SoFnhKQ/Da66RKgvzXa+0eE4VTopaI9Oazbl8h4XyoPO/X/Uhb5bhJ1ZbYieM9Nwdbl981ucfz97tKct0p/yXKK2tCChrJHSwbQlwGCm3j+yy9vjJCNS4Z0v4wGuuzPhimaBvFZ6HJp/ZqNGBwCTVYqSi+/gCE+m0dc9eO9joOhDDhBRcJ9BlvAZkfY2vazI7g2/V2qZNwGeeOzRR4osvjyFCgJvzF3Gas8rxWhZPqpHGINhSRNvUGgP4Go0gaa+zm3+iLAPeqJcZPkCOqjohdGdSp8taKGH8bbTpb/cDm22SbiD1uxTt6Z2ON5rqXLMG++T0HGipdR1rr9oslQj4UUQxc8vrL2hknfiqlyK8ay6ZhpntQicIQ41ccv27fpJ43sAIEdT6ElWO5NMayUUkeF8g9SkVPvMDkecXzY7iE2IYiR/Y8NRk1FIVOQNcBjz0QCpVEgKqLAcHIfomkHi6QYtOc4ieQpQA9/rQwOj+Nno/cRbrsgaQmvdjXMYTyEi8IZVHOuFPhRxjLEgvjflw8XxCE2m0tiu11+x1re0AmCinjJY26WX/J4cjd6JbJs27i2SDtpsdS0/pD0k7ZFZ9FoMCPwtbo8GO0WBhPio9OYhfDNahVzhQM731CjGSP7/OW0BuBNPK+Jz+Wcsbou6coGBxUYJTE2RWqTtQEjQE5acXKPlZafpq+0u9nwHDtYWnJ2la23u8nS4/UNbW55rbLAxunzAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAscKjQ="}
```

You can now merge this file with the one where your dilithium public key is, so that the verifier has everything he needs in one file. You can do it by either use the command:

```bash
jq -s '.[0]*[1]' pubkey.json signature.json | tee data.json
```

where pubkey.json contains the output of the second script and signature.json the output of the above script, or by adding two rows in the previous script, one where you compute the dilithium public key and the other where you print it.


## Verification

In this section we will **verify** the signatures produced in the previous step. As mentioned above what we will need are the signatures, the messages and the signer public key. So the input file should look like:

```json
{
  "Alice": {
    "dilithium_public_key": "w0XwSGhAhDaLDOrIn63/diFlkTBoxg0XT7gljo6eGEQxeblRp7rq3Zvy+ykzJKu/31+CR3v2EK76xQjhXsnw6eA6/fP+b0qqHOzsOKzSOLSSWesYlidkt+yQtjYA3wEFD/BASU1URDie2vr3A6EQojsjHRdS6Dt7SL3PqZrAREnMx75b1RAWhdDr5EEtTGC7Bp8pV+R6ZB2M4cYqV4VnuX+eAFjAGyRVKJNW0zDXJiBfthuUU/qIoC5HwlrWKCw2r8KFCsVPzc/ssLYICWiapi0Kf65qHOfNRM5CzeBRIK3w990CSh7Q3RRXwYXj4b9uqXzhtEycmHI7RsYRTU4bOFervZ7BK2MmfWdWzHpLJGLesAAoyPT1YKqv+xmVvkT30Oy7gfSAjZMKWkTTqUG6weIhuD9XndYp25t8HarHqlk7OLdGQwR34mkhlP4wcvRGr0VQiiDITUbVlHw5cy9pirq/seUyqz+U4UqH5zykks3jOVr5cT0xoyhS0U6Rvu8IT62bDtbpyCSQf+dM0Vmn++7sydQ3y7r4MSqIzeJp7YN826lKj0jERusRA3p2Kl1Y0FFBgm6UV/cJ2gezPqu1jY0kLXFeuY7Tf2mKMes/F4Iz9VXmEkusn2rE+Suw89H+LYWU9NgxPwgQ9KJCgzcs4Fbgt7mzhMsuPoiArg/RhV9X72obutoCG23uWaHBdLb7thk3yD3i36Pf34rlf5dKreFXznDMVd69fI7CoEJP2DbBCTbOlVJFgItxUlWYw7MM0HxvxFe4xSkKkIbUKTuHnOtLgrgOMtD4pvpKjkAAYnJYsYWzHIgZv96d6DC5KoDg+UUBd2XeHELUaBnEwbfaxEegGqTlpECQC2r80r7/jP8nchaX/34yQQ1rnYZfXl8QcvvPOPjyxwKQrrnSPDw7hw6HBY+UmnQ4KWImxdhXaIS25XtjdKAALatSRAtSwqXNsb1ifSoqSvcb3FN+6WWFEjTFETchBPOi4mR6IN8OuRjh/VPh+kyg41R6HBqJB60WkmI6g1Ug+YARS6gAIydlgNZ6XCKKXcg968XwS5PvhXcCcIbK7+4sqJ8VMFhG17yjpwiwS4Dyju3Tq2tbKAaLKAQ+OCSrk4Uk+WKWDdqkEW1Af3DK9IAx+H0ihSpoWZQmnO3Rhw6OO6I5P1TDu601ZSu8I0X9PxI5ICGU48mhNies1icKJ4sqVPDkSR6L3oHYWb7AhgptuVTK5d4d9XpeG23JAEt8qBiIFQF3sDGcuJoMudsGavaM99tlfW6fOmIeXbhnqNq6jpbutOYTPm1mIhQ6rYFYhCoYwo/2HtL4WV+PIaBvzEg//JKPeQ9i0O4NgSkDV6NHMguoA0zhR5uvqt/d1DXhP14GWq9h4vB68GeIVVjGTcHpqcxLCqRfAGzrWJY7e8bHhhdSAUlDRH5KpJzqVURpOabh4VyookqcqRWrKdARKogXJlfKAP1k7Ju5ytJ3gzwmQuEaWA7eznMzLUv/tok7kOPbfLQjQ8+JuVq1nSYY4mWT/VkzR6F1zRwZK63zbppinmoxbspcz6KPrfCpGpZ4Xj9ZSB2RNUVwWodQZx3CWXq2tYgZiGip762aG+uEc+Fk70/TMRYIUxFhqiLxygnWooxCFxKBAS+Nk/SSt571ynYvGOAEDfU+agKa6Q1bRntH30rom7hsu0HgRqOyLt0WbOK8uQ9leAFp+b4zQtBQudHZTUKUAbwNIZlZK2rklL3efRfAKGGnvvnAcg=="
  },
  "array_dilithium_signature": "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",
  "dictionary_dilithium_signature": "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",
  "message": "Dear Bob, this message was written by Alice and signed with Dilithium!",
  "message_array": [
    "Hello World! This is my string array, element [0]",
    "Hello World! This is my string array, element [1]",
    "Hello World! This is my string array, element [2]"
  ],
  "message_dict": {
    "message": "Hello Bob!",
    "receiver": "Bob",
    "sender": "Alice"
  },
  "string_dilithium_signature": "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"
}
```

The script to verify these signatures is the following:

```gherkin
Rule check version 2.0.0 
Scenario qp : Bob verifies Alice signature

# Declearing who I am and load all the stuff
Given that I am known as 'Bob'
and I have a 'dilithium public key' from 'Alice'
and I have a 'string' named 'message'
and I have a 'string array' named 'message array'
and I have a 'string dictionary' named 'message dict'
and I have a 'dilithium signature' named 'string dilithium signature'
and I have a 'dilithium signature' named 'array dilithium signature'
and I have a 'dilithium signature' named 'dictionary dilithium signature'

# Verifying the signatures
When I verify the 'message' has a dilithium signature in 'string dilithium signature' by 'Alice'
and I verify the 'message array' has a dilithium signature in 'array dilithium signature' by 'Alice'
and I verify the 'message dict' has a dilithium signature in 'dictionary dilithium signature' by 'Alice'

# Print the original messages and a string of success
Then print the 'message'
and print the 'message array'
and print the 'message dict'
Then print string 'Zenroom certifies that signatures are all correct!'
```

The result should look like:

```json
{"message":"Dear Bob, this message was written by Alice and signed with Dilithium!","message_array":["Hello World! This is my string array, element [0]","Hello World! This is my string array, element [1]","Hello World! This is my string array, element [2]"],"message_dict":{"message":"Hello Bob!","receiver":"Bob","sender":"Alice"},"output":["Zenroom_certifies_that_signatures_are_all_correct!"]}
```

# ML-DSA-44

ML-DSA-44 is a Post-Quantum signature algorithm defined over lattices as an extension of the dilithium algorithm. From the user side it works as a modern signature scheme:
- **Key generation**: The *signer* create its private and public keys
- **Signature**: The *signer* use its private key to sign a certain message and sent it to the verifier
- **Verification**: The *verifier*, using the *signer* public key, can verify the authenticity of the message

## Key Generation

### Private key

The script below generates a **mldsa44** private key.

```gherkin
Scenario qp
Given I am known as 'Alice'
When I create the keyring
and I create the mldsa44 key
Then print my 'keyring'
```

The output should look like this:

```json
{"Alice":{"keyring":{"mldsa44":"xLYglIaoYd7jwWeg6kd2v2gsOA7YjVJbFI/3PoeXDTLxjAwp+gK/p51RbLXEi2OWJhbjkFfnBEWYqqWgpptfylMoKnuTh5SAltq7vUHLLsXx8SDJdVKOmhEDxSWzrq05ZGQQAPfQClIsbQ8PLe7y+tdAj3T2aRSy3e4GWEJD162SlgmEAg6DBCQQBkQbxEBaGCFkNFEiGEgjMiAIxIACKCLTkg2Ewk0KRopBEEwjAQ2ZsoWSBnESxoFcNmrQsBAZM0qYMg2apFAgR4GBliwRlUiDRogUKYgBQTIIx3EMA0EKiY1SJCWQhERjpHCDJoQYAEIgRmBjEA4YJ0DUpGTBBiDMAEjQOEYUiRFBNnKDICFaQgLZwoSKRI6CpA0hskwbImzYIDIgEkEAtmSCOErgMmSaooyDyFAcOWhCFAXCNEnTSJJMRnIiSSYkg41bRgiiQjJjME0ABIGjBHJiEAkBBCkKSEDKIhATpTDgRCnimG2CREoClERTEnFaNDAUMGgYFRLhJAhRQIpKQEXgQlJKIgkDgFEjFYRCNhATQZFJJEwhQC6EJjHaSI2DQIhjti0DACGUkImDsE1JEhFYGFAcAEXIFEEZs5AIFxFkgiyjqA1JOGQAICYkpAkcCAkSNyggwTEhIXEYNBHYKErcuCnKtHDSNEDMIE7YlEQIqEWJxjCEtDABgWELl1DapIUCsxGEIFJZuAAgsAECNylYGIFcAGULQJAipYCZxgwMB0YUGJEgxGXkRlEZI2zhpESRFiaUCEHUQowASAHQiEzBRkbJGI5YFAkQBoAQRITIEggJBTARs2zBmCnjIInkGGwESVFLSGmDJIaQokEEB5EKoJFcEjEaKQkCs01StkEBgwjUKAQck2ULIBCSEmlhBBBAAiChpJEJCQ0iyREaxYCJlnESt4wEkIgIxTAjAjLCBCTgKApApg3QFkUkgkXDwAnMEDIkBUoDOUyaSIWTBm6TNkFLQCQjRjKBMC6BKE1LBmGbQm3RFAKQAkAJgAhDCIGjCGTEAIECMUWABmqAkAhDhnBJsFChwkQjpGUDGRKgNIEIhRCEQiCURnDbKHILMQGboIGBBAxRxmAJknDTICxhEoRKuC0LQHEcNBCRoFHIxlESxgyRAA6IFBIBg4TKyAjhoDEEIAgRp0ESSU0ikXFiFoYQIW6QFACJRIaYMBJCqE0SRCWi/7ZIOAOTdjzyED/DTY29g4DUYOBfyOSUsMUZmYr/IO2Uxr232RHoQgevtAZEe/+XALIsAzwS3gCLhbBCa2WO3SRqbKgbkgCaKUtghMAAESjUtUjFjuviWE6sc2EL0Ykw77JyIldsoq/0ZcTQJQ8nIyhMymJP4LqZPfvgKvyG9zQgsiOEB0ctGMQ3XHXj0nqmW+dhLvyEIDzoODeHJk5VnIJI10LRohNYDdrzX/CN3HmAO883pzf4esfe53P36xrHhB4EMetq2pXGjpfqRwG8cbY0HA6rC9XxIKdUQ8D+RdJh0huaLbGOL1Tnh4nXiALTY+D/r7+feUYU5NmnTqDITEdelFOmQkYdDM+0KbMm1QxfRNrP1mJsjGeOsYPNrGrgKcivyPg0WUbRqw7+Ur9C6mdVO7lyQ/19IHOrjhh/wRtSoGfjsTk1Zg+N6huJdSyoRy8n3U9Yjxmxrg9fwBwZOBcHC2ZOcwCzTxifdUBqoIHq7C6M4tedHrw1dSES/3D72idb5q/6TzVbkhTbR3e8ijxjH29MFIsUJv7ujjbCkw9MFZhOV0Pot4g5TxxQlrx7XJeUqjCoCyDIy/jNelhPokOaet3sZeRN7ESx6Q1tk1Mmwyv5DTXVKR/Z9p9vBkkMntP8gECnxbfYhPbmt/+Upik9jIUBfnxVtWF+fhj52W1iPrsjsNEHOi3dXTed0PIkvemzKWd64jrlAPtXXw9qRf46b2PRe6d5bpaWVD+9vEMYVVF2lqGbh4pGsJid5XrUVGzo+oLFVvO55Fr7VTv+CnJPvQz50MiN3kbMujK4aNTJE7kPGNhK9zYzejwBEKIOrvW0PvGIXSZtfSEM2ELWODyl36myESjigyo92cT1xj1yH6BZLLO4ORwOWkduX74z0dDNZZ+5AVHoPvgQ0laXJjaKeI3RSvcWC739hrqVgxjoZiflR+g+iJMZCp8GPgqPR8wolsThbr9UrzX4Ki5zFABIH/uwXhJ3yXdSN2R54UtmlQ68X0ClO/yzDuDB48y81YqGcolrs03uDHk7bINZfvu+Kd37CAc48yDFBXm9FKvwBw8yOmvYjxMXX7BNv5ecWFuYY0TNEV5NVeGpLFZ5K3T7KyfdpKkJFaz0tB9EqCCEV89MlyGouu/CndU99gHNvqSJg/7JRmH6S8B6P8Ti0t/w+aKsBTGA5BjKSvcPzzR21f0vkcriYAKP6hQoWPMpLegCisSxW3KhxUmyblmy5N7CHA+T9sddbY7hIYjrWF5ZLN7hKBmeCNayvOq2ssFAhlUf3pLzwkZGSN6SLoycVFRP1NSTLqqEcSiRAtrG3rrCXbJ4kvystV7aIzqKUTQGmB0iUKYu5ZQcYcVWMESC+xS66QHUeKS1QNl1HeqBY8y0ziAy0sWbsuogA4kmOxyEviZXsVNbFLd3KRWGmXFcHcFxd26BppL86MYOft9gjgw/7RP8JO2E2/QCcOPhAOa1zkLWq1k6pqH4uuDxyoUkVziU+SNC+iz1eYBGPT0/4DSRdnHhIpI1i+UGWYxkvo6LsOAZhXYHM1dge2IGnG9iuBRkJPHJDLP2GC0Vcpsep0vwv15MW5jYzROeDjRCf7WhWn5Dz5hse+sC1ElUTtMSvg5YH/vuAWo5LVo3WT5hA7vZjRUeEMoaUs+Ca81FbU+ZnW6dA54i0SRe9apPl63h7MX7p5+xVF8zRo+NUqmM6JisiT+cliu05VUp9+LtZeH2pgGIi9JsnuSqSxsqF4iocX/gNwxl2de0mHaoB0NOEqUoWT0RU7KUp3VL8065nAxN6HnH0xDeNNluLEBK8fRpj7gMjOvBcFGvH5GSkWqpTWZ8f9v9JoVjOWhQbtP6BpmKduJ2nH082XDtJc4mrWGlXgDGV0WXsno1H0r2UTOph+iAt/vy80DUA3iaBK+xyruIaazRp+j6Wz2qXJOJQoQi9ESjUaVyWmTJ9EwNcUtGXTzSolTISMbEleh9XtsuYnnBIc/shwaqOqhy+ih2etmEZ9B8XU7Inpa7WgOtnFCGbrmc7M34RomXm95zpi8X4mWyccoRBUr0Ld0uUFyypviyl1ggBiQ0psnbjNYnEED4RJxZKKYQ1Ibq5vGngVQOMaerLd2DCPg7jCeSslLSJhTeJ3dGz9QcAqj41wsNiVl/78s4MtEYNgixyHe5WEmdFH4bTNI1wNYRYQJXkqD83DReTFalCaDpE2t/rPHqDk6m8Q=="}}}
```

### Public key

Once you have created a private key, you can feed it to the following script to generate the **public key**:

```gherkin
Scenario qp
Given I am known as 'Alice'
Given I have my 'keyring'
When I create the mldsa44 public key
Then print my 'mldsa44 public key'
```

The output should look like this:

```json
{"Alice":{"mldsa44_public_key":"xLYglIaoYd7jwWeg6kd2v2gsOA7YjVJbFI/3PoeXDTKPUAoG5ZEBv39QR7S7TMUDdO/bdk/WeUCp1fwC6gGarzCZYRf8o94gSNJqmpZMkBhSaN/9OajKuFx5o2Rj+MwPzm/zJr/Qzlseb2B6UkSavaQ+xjKUkedzsEWBw1qKGj5BXJd967jUOR2/Dd9h5qqeib5ds1BHUXKSJ6XLBGQe0Ool8rt2fur1+KaZJ/QwaTjX3kIxmUq79QJKqKAoZkfQI41Hiz3MqKjROhEUEuQ1rAVegnWePz8+zJCJ+XIVbknKAiBcHQHqv0arNfAqVfCwbKcBZCj35rBeIacR3zunitxqG317kI4j2ds3u9SolIWY/s6PbMpbG/le3zxRe8IpwNwiPcH4eDjGaeOtcO2q+zEQ9IjR3+Y/LjpPgz273g5eEh/mpS8lNG4XPPkicBcgwL/CivTnvnzGPwr01UHwBvyNi6Nae9B5kaVpSjBVV3VYaz0PhxOkLqFrClsCMqKu4ctudBsQpC/NWpP0sc3FPK63bT6WEXTqLgoK4UknM7oeB6LUjcK34f0bQZpzkY4nhoRFcb3emASotgO3zh6MLs3dmMgV3tL9WRioO7IQaYjdaMVVAsQKSYqF2kxqAzhvLdfU7N62ZMBwACImwN+il3fheO2V3GhxDAwAdhJodHpwr4MmbBWrLKa0aN3oyu+UZaQWLOb+IxCeY8BhYuxXe3Z3DkR12z+j0G+DI68scmugONM4VVhXsy9XYrgSsPNbGpGQ8kjmeu+U1oP3DhbW3rq9Gbhh7q6bN/8QOwWd8fydILzkfnziM+2am2Qstoy5Ar9Ope71YZXRZAISuBZMvSfIknA7K1W3VW5lqgalUBnu+eJxkmWGVrGBdqlG9sA2AdLJq43chsoJyo5sc6U34oS1qHqdgonQniDoltoePpSG8XjULw/SvWC4yVmxPgc2nFOBiKVDz7NqFPTumZqCf8BflAPHiHcWOiqaJNEPmNOf4g6znTZTW0Ynra/kFfh3ZKDKhogTdz1sHFt/fa+SIwesP0kZNFbcSaGW29TIAXG8sqNc1GAq6/IaOOgoAeqK+mDSZtsNEizjhOUBBdhr5Sm+/kC3ugi2JXWjSYKsSJ9QdDzP+kKrslXOMbxGelgHkfOuWiynpxdpfdjQZJE1+09v63PqcEbTNMAqSbtCE8QybUY9YY7IZzY/iev04Fo0pq1HkrnWFQxw7QuHvBdl2q1ojNDoWU3L6P6v0gLn63BHkpWgs1OvEGurHqRXIZIumUo8VFRqPu9Pt4aLtJgUBW80/2tKd4nrHMvwE3nWjhpjsCzYb+N7LBzxVgdqMo9nt1fk4xzhM0WL0T4fxbTTMnSfHpWLdgkgNT0uBK9bOKmkemU/37SJph1qqyj1m+PUNn2tnsF95lhez6583Ldz4QN9BVAYk0zei7ibEbZ7dt1qJTNZ3RH4qOzkB93V/oqv5hjg+y4sUKj9jM8c7iyGwARU2dyfoFS+7HloCQlXF9czBmTzN0wgEnHVotMcDJvPMpXislTz37fQ96ZFUBgJ0uGNtIEE4SCls/n+7caTAlY3Y5er4w77Ddy6ANCGCeSO5pFVWkZQpDaORG+JRbs++H3CbH+r1uAeVmTIo7qWwIpgHuOtzvWK20hQKuzSYw9WwRHv2djhUpcbjUBaaNKncZZ/MH1vABhlRvdeHqWkqFIqOr8ixcRRtPg9XhiMbY3AdxiIR7McugkVbslzGogoFA=="}}
```

## Signature

In this example we'll sign a string that we'll verify in the next script. In this script we create the data to be signed in the code, but it can also be loaded from the extern as we do with the the private key. The private key is in the file we have generate with the first script. The script to **sign** the message look like this:

```gherkin
Rule check version 4.42.0
Scenario qp
Given that I am known as 'Alice'
and I have my 'keyring'
When I write string 'This is my authenticated message.' in 'message'
and I create the mldsa44 signature of 'message'
Then print the 'message'
and print the 'mldsa44 signature'
```

And the output should look like this:

```json
{"message":"This_is_my_authenticated_message.","mldsa44_signature":"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"}
```

You can now merge this file with the one where your mldsa44 public key is, so that the verifier has everything he needs in one file. You can do it by either use the command:

```bash
jq -s '.[0]*[1]' pubkey.json signature.json | tee data.json
```

where pubkey.json contains the output of the second script and signature.json the output of the above script, or by adding two rows in the previous script, one where you compute the dilithium public key and the other where you print it.

You can also specify a ctx to use as domain separation in the sign algorithm. For example:

```gherkin
Rule check version 4.42
Scenario qp
Given that I am known as 'Alice'
and I have my 'keyring'
When I write string 'This is my authenticated message.' in 'message'
and I set 'ctx' to '480c658c0cb3e040bde084345cef0df7' as 'hex'
and I create the mldsa44 signature of 'message'
Then print the 'message'
and print the 'mldsa44 signature'
and print the 'ctx'
```

## Verification

In this section we will **verify** the signature produced in the previous step. As mentioned above what we will need is the signature, the message and the signer public key. So the input file should look like:

```json
{"message":"This_is_my_authenticated_message.","mldsa44_public_key":"xLYglIaoYd7jwWeg6kd2v2gsOA7YjVJbFI/3PoeXDTKPUAoG5ZEBv39QR7S7TMUDdO/bdk/WeUCp1fwC6gGarzCZYRf8o94gSNJqmpZMkBhSaN/9OajKuFx5o2Rj+MwPzm/zJr/Qzlseb2B6UkSavaQ+xjKUkedzsEWBw1qKGj5BXJd967jUOR2/Dd9h5qqeib5ds1BHUXKSJ6XLBGQe0Ool8rt2fur1+KaZJ/QwaTjX3kIxmUq79QJKqKAoZkfQI41Hiz3MqKjROhEUEuQ1rAVegnWePz8+zJCJ+XIVbknKAiBcHQHqv0arNfAqVfCwbKcBZCj35rBeIacR3zunitxqG317kI4j2ds3u9SolIWY/s6PbMpbG/le3zxRe8IpwNwiPcH4eDjGaeOtcO2q+zEQ9IjR3+Y/LjpPgz273g5eEh/mpS8lNG4XPPkicBcgwL/CivTnvnzGPwr01UHwBvyNi6Nae9B5kaVpSjBVV3VYaz0PhxOkLqFrClsCMqKu4ctudBsQpC/NWpP0sc3FPK63bT6WEXTqLgoK4UknM7oeB6LUjcK34f0bQZpzkY4nhoRFcb3emASotgO3zh6MLs3dmMgV3tL9WRioO7IQaYjdaMVVAsQKSYqF2kxqAzhvLdfU7N62ZMBwACImwN+il3fheO2V3GhxDAwAdhJodHpwr4MmbBWrLKa0aN3oyu+UZaQWLOb+IxCeY8BhYuxXe3Z3DkR12z+j0G+DI68scmugONM4VVhXsy9XYrgSsPNbGpGQ8kjmeu+U1oP3DhbW3rq9Gbhh7q6bN/8QOwWd8fydILzkfnziM+2am2Qstoy5Ar9Ope71YZXRZAISuBZMvSfIknA7K1W3VW5lqgalUBnu+eJxkmWGVrGBdqlG9sA2AdLJq43chsoJyo5sc6U34oS1qHqdgonQniDoltoePpSG8XjULw/SvWC4yVmxPgc2nFOBiKVDz7NqFPTumZqCf8BflAPHiHcWOiqaJNEPmNOf4g6znTZTW0Ynra/kFfh3ZKDKhogTdz1sHFt/fa+SIwesP0kZNFbcSaGW29TIAXG8sqNc1GAq6/IaOOgoAeqK+mDSZtsNEizjhOUBBdhr5Sm+/kC3ugi2JXWjSYKsSJ9QdDzP+kKrslXOMbxGelgHkfOuWiynpxdpfdjQZJE1+09v63PqcEbTNMAqSbtCE8QybUY9YY7IZzY/iev04Fo0pq1HkrnWFQxw7QuHvBdl2q1ojNDoWU3L6P6v0gLn63BHkpWgs1OvEGurHqRXIZIumUo8VFRqPu9Pt4aLtJgUBW80/2tKd4nrHMvwE3nWjhpjsCzYb+N7LBzxVgdqMo9nt1fk4xzhM0WL0T4fxbTTMnSfHpWLdgkgNT0uBK9bOKmkemU/37SJph1qqyj1m+PUNn2tnsF95lhez6583Ldz4QN9BVAYk0zei7ibEbZ7dt1qJTNZ3RH4qOzkB93V/oqv5hjg+y4sUKj9jM8c7iyGwARU2dyfoFS+7HloCQlXF9czBmTzN0wgEnHVotMcDJvPMpXislTz37fQ96ZFUBgJ0uGNtIEE4SCls/n+7caTAlY3Y5er4w77Ddy6ANCGCeSO5pFVWkZQpDaORG+JRbs++H3CbH+r1uAeVmTIo7qWwIpgHuOtzvWK20hQKuzSYw9WwRHv2djhUpcbjUBaaNKncZZ/MH1vABhlRvdeHqWkqFIqOr8ixcRRtPg9XhiMbY3AdxiIR7McugkVbslzGogoFA==","mldsa44_signature":"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"}
```

The script to verify this signature is the following:

```gherkin
Rule check version 4.42
Scenario qp
Given I have a 'mldsa44 public key'
and I have a 'mldsa44 signature'
and I have a 'string' named 'message'
When I verify the 'message' has a mldsa44 signature in 'mldsa44 signature' by 'Alice'
Then print the string 'Signature is valid'
and print the 'message'
```

If a ctx is used during the sign then you have to use the same for verify. So the input should look like:

```json
{"ctx":"480c658c0cb3e040bde084345cef0df7","message":"This_is_my_authenticated_message.","mldsa44_public_key":"xLYglIaoYd7jwWeg6kd2v2gsOA7YjVJbFI/3PoeXDTKPUAoG5ZEBv39QR7S7TMUDdO/bdk/WeUCp1fwC6gGarzCZYRf8o94gSNJqmpZMkBhSaN/9OajKuFx5o2Rj+MwPzm/zJr/Qzlseb2B6UkSavaQ+xjKUkedzsEWBw1qKGj5BXJd967jUOR2/Dd9h5qqeib5ds1BHUXKSJ6XLBGQe0Ool8rt2fur1+KaZJ/QwaTjX3kIxmUq79QJKqKAoZkfQI41Hiz3MqKjROhEUEuQ1rAVegnWePz8+zJCJ+XIVbknKAiBcHQHqv0arNfAqVfCwbKcBZCj35rBeIacR3zunitxqG317kI4j2ds3u9SolIWY/s6PbMpbG/le3zxRe8IpwNwiPcH4eDjGaeOtcO2q+zEQ9IjR3+Y/LjpPgz273g5eEh/mpS8lNG4XPPkicBcgwL/CivTnvnzGPwr01UHwBvyNi6Nae9B5kaVpSjBVV3VYaz0PhxOkLqFrClsCMqKu4ctudBsQpC/NWpP0sc3FPK63bT6WEXTqLgoK4UknM7oeB6LUjcK34f0bQZpzkY4nhoRFcb3emASotgO3zh6MLs3dmMgV3tL9WRioO7IQaYjdaMVVAsQKSYqF2kxqAzhvLdfU7N62ZMBwACImwN+il3fheO2V3GhxDAwAdhJodHpwr4MmbBWrLKa0aN3oyu+UZaQWLOb+IxCeY8BhYuxXe3Z3DkR12z+j0G+DI68scmugONM4VVhXsy9XYrgSsPNbGpGQ8kjmeu+U1oP3DhbW3rq9Gbhh7q6bN/8QOwWd8fydILzkfnziM+2am2Qstoy5Ar9Ope71YZXRZAISuBZMvSfIknA7K1W3VW5lqgalUBnu+eJxkmWGVrGBdqlG9sA2AdLJq43chsoJyo5sc6U34oS1qHqdgonQniDoltoePpSG8XjULw/SvWC4yVmxPgc2nFOBiKVDz7NqFPTumZqCf8BflAPHiHcWOiqaJNEPmNOf4g6znTZTW0Ynra/kFfh3ZKDKhogTdz1sHFt/fa+SIwesP0kZNFbcSaGW29TIAXG8sqNc1GAq6/IaOOgoAeqK+mDSZtsNEizjhOUBBdhr5Sm+/kC3ugi2JXWjSYKsSJ9QdDzP+kKrslXOMbxGelgHkfOuWiynpxdpfdjQZJE1+09v63PqcEbTNMAqSbtCE8QybUY9YY7IZzY/iev04Fo0pq1HkrnWFQxw7QuHvBdl2q1ojNDoWU3L6P6v0gLn63BHkpWgs1OvEGurHqRXIZIumUo8VFRqPu9Pt4aLtJgUBW80/2tKd4nrHMvwE3nWjhpjsCzYb+N7LBzxVgdqMo9nt1fk4xzhM0WL0T4fxbTTMnSfHpWLdgkgNT0uBK9bOKmkemU/37SJph1qqyj1m+PUNn2tnsF95lhez6583Ldz4QN9BVAYk0zei7ibEbZ7dt1qJTNZ3RH4qOzkB93V/oqv5hjg+y4sUKj9jM8c7iyGwARU2dyfoFS+7HloCQlXF9czBmTzN0wgEnHVotMcDJvPMpXislTz37fQ96ZFUBgJ0uGNtIEE4SCls/n+7caTAlY3Y5er4w77Ddy6ANCGCeSO5pFVWkZQpDaORG+JRbs++H3CbH+r1uAeVmTIo7qWwIpgHuOtzvWK20hQKuzSYw9WwRHv2djhUpcbjUBaaNKncZZ/MH1vABhlRvdeHqWkqFIqOr8ixcRRtPg9XhiMbY3AdxiIR7McugkVbslzGogoFA==","mldsa44_signature":"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"}
```

And the script:

```gherkin
Rule check version 4.42
Scenario qp
Given I have a 'mldsa44 public key'
and I have a 'mldsa44 signature'
and I have a 'string' named 'message'
and I have an 'hex' named 'ctx'
When I verify the 'message' has a mldsa44 signature in 'mldsa44 signature' by 'Alice'
Then print the string 'Signature is valid'
and print the 'message'
```

The result should look like:

```json
{"message":"This_is_my_authenticated_message.","output":["Signature_is_valid"]}
```


# Kyber512

Kyber512 is a Post-Quantum Key Encapsulation Mechanism defined over lattices. It is a cryptographic primitive that allows anyone in possession of some party’s public key to securely transmit a key to that party. It can be divided in three main part:
- **Key generation**: The *recipient* create its private and public keys
- **Encapsulation**: The *sender*, starting from the recipient public key, generate a 32 byte secret and encapsulate it producing a ciphertext that will be sent to the recipient
- **Decapsulation**: The *recipient* can recreate the secret generated by the *sender* using the received ciphertext and its private key

## Key Generation

### Private key

As above, the script below generates a **kyber** private key.

```gherkin
Rule check version 2.0.0 
Scenario qp : Create the kyber private key
Given I am 'Alice'
When I create the kyber key
Then print the 'keyring'
```

The output should look like this:

```
{"keyring":{"kyber":"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"}}
```

### Public key

You can now generate the **public key** corresponding to your private key by passing the latter as input to the following script:

```gherkin
Rule check version 2.0.0 
Scenario qp : Create the kyber public key
Given I am 'Alice'
and I have the 'keyring'
When I create the kyber public key
Then print my 'kyber public key' 
```

The output should look like this:

```json
{"Alice":{"kyber_public_key":"0QY8YhUohdllmKZ2t3IRGukmoINrJLpNY0ZVgyoOpKWT2FO9UKmU2bkod4ADGHq8VgvChPMFF/krOIxn/0zAQmEm/emqRXpgtWiLM2LIt5NiHKNMAmSElSEyEGlMhjcK1pNAMwa/HPsjTxQ6hOp/dEcPWsd67Aq36Ht619WgGblTd1xJFEW9FcwxP3WV8vkVIGytg2dH4COMOFAlYQtkCVoe1maugpadjQy66mqFHlUbnvNVqDd16QmLrcctWcuJYBNksRZ1aJmzH7IL33MwKhex+VQi6Lpdq0GuAvdlO4SqIGSR1WSuzTcmfTFKkiCY5wcbcAiN9JEXZnchlvSD66APUlC9HnguMxeespuo0hTEwaRZfdSuXAQh/xCiQ6uUtvOQCUoynGirQjGy5BUQYBHLLIc/hkgbxkdwwgPNMlyFucMfgZB+MFwhx+pYoqjCcEEag1AR8ByJt6SRSdEZG0bKhNwGqLt4eOYJVqB5WQgCH2dzQrBNNzcYqJUlMPaiEyWk/gIl2QHBhDGquZUoQjoPAduaU9YyTXFvI8MI+8ycVCpoBCZk4LO3WmZHQ/S986hOWgKvXlKTnMV3nFEJzjsPxHWB9EEVzvWiyIuo4eNOAIanZNJlVAU5KkihP/qlPAcZc2BKs8GnN7xdQIFhNMt5tbA/kHM5x2unt6iqTIEfMCQxXAs4M3wUWxCjk3vEcdww/mV7O+oVhXm6JzJevuW25oJSLUlsmyaHSpiaFGayu3EJ8LYPL5Fa04NISCm4UJqpSNufDoeNLOIXgLOLZot6PGK5WqzDwJw2dkANmAC9qONuTAFKB0POGzCh7gN/K2Jp+7MGsXjOAWaU2fXLYCFV3kOMhKlja5NlFRWSu6fP8olFNtzOw9pQ/7ep8POAnaIESoiMb0xgOTUiN1RTASNZZwdwk+YUqCkYgRNZkrJ/xap1cUset3iWIxvDcJhsL1eTsvgraNODhZiiCvGLWjWhbmLIjfgz2zhK7sWAtxA9aCahp7tQandiVJfPfDmLdMHQV6uF07xMpS6mhMEAm/7nwhMMuyn8pjeWgjiyqII="}}
```

## Encapsulation

The script to generate a secret and encapsulate it is as follow:

```gherkin
Rule check version 2.0.0 
Scenario qp : Bob create the kyber secret for Alice

# Here I declare my identity
Given I am 'Bob'
# Here I load the receiver public key
# that will be needed to create the ciphertext
and I have a 'kyber public key' from 'Alice'

# Here we create the KEM (key encapsulation mechanism)
# The kem contains the 'kyber_cyphertext' that will be sent to other party
# and the 'kyber_secret' which is random number of a defined length
# the 'kyber_secret' needs to be stored separately
When I create the kyber kem for 'Alice'


Then print the 'kyber ciphertext' from 'kyber kem'
Then print the 'kyber secret' from 'kyber kem'
```

And the output should look like this:

```json
{"kyber_ciphertext":"VLIO0ODxE0dJrBtUhyGQRz+tAfbE0eOVQvBp5EUrrGGYlO6pZ3mrOigMEgMeuqMbC5+/dAXQvgHkGMC21ciz/Oh/kHyjOPKgxnAxDYzImFv8lZ4sFJlnC/vZkdYTu94a/wzpgjPNt2mKDVtOdVLdunAxY+HwBWDYGkKjFSJWsKROjtS7m5I3a5QhG7O4WxZ8aUqqjoKtXUV0zrQlBsz/ZLEQnM//5LMPNhYhLBt24kmrf8akV9tAoAQAEgBLp4KbJo4Ydp6tGrxJClBhZdq5s1l+YExr2zPOlQz659tYoGEnn7pbaVLwSChxJZ7vqZTE4Wk7JnHe98FZU0Lk6fmpEe/RU8yMBrXbyduXoybIlhgwM7mk+V8rkFTFNTVntKInFiUXnCOzE6tQiDL/qWhfX1bX59Nrk4kiCYCJY+hJnvdCaLrPRdq/V6H6WwvGjyWN3Ks4CVysP/Mc/4dIjnVpoXAvXyLSBkyc6n9KmhvZJdJYM/KFTVgbs1kSqS90zf+VAWgTG7UgSHB0ZR00uXb9Ck+DldIGPEhOquY3Ia5XKYRXLNijy1ngTgRq0/o2bF1hZfqJ/hLyJWpJ7Sm5Q2RKfRwFkGcxAakokkssQ0WVCFIupnzZ/X7HdmJFRQvQ2AaDoAq+reQvipIm3Mm4YFp/81xdzD1fXZoga+Bong4E8C/QR54QEO69zBXS9AG8nDrB0HkrODuyOOg6HFGR8UJ/dSSVNXSwgR38WZTks4inwtzAn/4/MTN33y69QTAs6OOzVHr1m/+VZIAaxKxsVDxBZXlrRRNuSB2arr4N3kgoVzYfca/tWo6bgcXvfk1Ozb+W4g4TR9pjuQTmaoGJfmba6lvumqAZ/8pEf9lYB947olXIR4cx4lAux4Ij2wi4hn9xoo/UKRLF+/TcIaBVsuS2jlpOHhOKm3hW/SdIXpBZvIzUa8pv1g2LSUwCXpTNaf7znXP/HgdZT3zPoaxqM8CLgoyO3A5PughUe33RQpDX4pmrZKmy4AkZjgrt4o/Skqu7","kyber_secret":"hFHb8bz6Sj4U9g2CAvPtjjZ2RG3iMeXtv3pt+EI5z90="}
```

Now you have to extract and sent to Alice the ciphertext, you can do it for example using the bash command:

```bash
jq 'del(.kyber_secret)' Kyber_Kem.json | tee Kyber_ciphertext.json
```

and send to Alice the file Kyber_ciphertext.json.

## Decapsulation

In this section we will **decapsulate**, and so reconstruct, the secret produced in the previous step by Bob. To perform this action we will need our private key and the ciphertext produced by Bob as input to the following script:

```gherkin
Rule check version 2.0.0 
Scenario qp : Alice create the kyber secret

# Here I declare my identity
Given that I am known as 'Alice'
# Here I load my keyring and the ciphertext
and I have the 'keyring'
and I have a 'kyber ciphertext'

# Here I recreate the secret starting from the ciphertext
When I create the kyber secret from 'kyber ciphertext'

Then print the 'kyber secret'
```

The result should look like:

```json
{"kyber_secret":"hFHb8bz6Sj4U9g2CAvPtjjZ2RG3iMeXtv3pt+EI5z90="}
```

obviously this secret will be equal to Bob's secret.

# ML-KEM-512

ML-KEM-512 is the Post-Quantum Key Encapsulation Mechanism defined over lattices proposed by NIST. It can be found in https://csrc.nist.gov/pubs/fips/203/final. It is a cryptographic primitive that allows the creation of a shared secret key. It can be divided in three main parts:
- **Key generation**: The *recipient* create its private and public keys
- **Encapsulation**: The *sender*, starting from the recipient public key, generate a 32 byte secret and encapsulate it producing a ciphertext that will be sent to the recipient
- **Decapsulation**: The *recipient* can recreate the secret generated by the *sender* using the received ciphertext and its private key

## Key Generation

### Private key

As above, the script below generates a **mlkem512** private key.

```gherkin
Rule check version 4.37.0
Scenario qp : Create the mlkem512 private key
Given I am 'Alice'
When I create the mlkem512 key
Then print the 'keyring'
```

The output should look like this:

```
{"keyring":{"mlkem512":"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"}}
```

### Public key

You can now generate the **public key** corresponding to your private key by passing the latter as input to the following script:

```gherkin
Rule check version 4.37.0
Scenario qp : Create the mlkem512 public key
Given I am 'Alice'
and I have the 'keyring'
When I create the mlkem512 public key
Then print my 'mlkem512 public key'
```

The output should look like this:

```json
{"Alice":{"mlkem512_public_key":"qLKnPIEJT3RnJUwc+IF87VJSixGBLgkg1bRP1mOloauRqKNRPksK2tkjJKhzSCqM/1zMinZgVVNR3KmrtxWs2UkNFXtUdPwp7mO5yBYSDIRdNjRojmOPSUu78xzGm1a6TLBcWjtjCEcjw/sZ5Vcv4sUNIntAFNnMintEzyPHNfWZeFd8fuAXQHpfxLOG8FVlyxFyZSvG55wXhFS+i/cqeuJAzvYEoZgctAMHzmp1pFsWEeG+h0ejYtVQ06OT/DGcyxMJ64S70FIgzwEWWvAHoiJ7FrNor+SpumHCLIZZ8uZCpULIeII8O9ElxOQ1PFeMrnuRbWIdRjYkpIiKJ6Fe2Sq13aXDWJA2eEAYb3lILHmulQGUcRN+oYhjqAKcLIwsdaSP7sOkHVoqeAEnJzC9IMm95VyN9zpn5xyPQ2tL03DBrMBghStE3xMtAHhyZOKbg+LJ91R52tkOL+yzBYo2W/Sfg+B+e8eEstwE0bET6qwgXReJIAg19XIMmeW5U5Vq3LLMDvE6kuaH5nRU8IaHQqM0FYBGyVPGlSV45kxz4lsjfxKPDdCwFqRgyOZOTuKNvGxB7/EBuzMINOESUegliguLvNw12KWuJTGa8Xk1nOI5TYAe5UCUJ4XFK6AhzDSV0rVKF4FqImgaFTgy/ChF0MvH/6aUw3bCEAeL/WKp2nJIVnDL17o0q+fG/RReKnU/ZXZkPFzFXxdbUxBrrUueB4l+JlNHH0CoM7Y07tMzUBQISQY33Sq7KEPDmuNnVUB9u/gRhaGoEuK7ObmAqta7wvSC/8i6yuwpzUW/z7YjtVcSaIqTRhAAIlHDjmls8zFZ43AxQGJgY9vCeyVv3LvMn6SF5PCHFXOQcVjIqcorkrKc4CtZZ/ZLhgYu6Jl0qLM3E+GIJMikwpdTxHrHf5q51HvDIzG3JiRpzJNmQzQdflHBx2OnB8QwDpctVxZD3vwwCcVQy8kxKfltdkqfwUVjZCQq00mcYlIs/ft6qcQvsmOz7rBzkHeOfCa2doPOhYBrVUD0hz9Yq/tysjwHDU7PuIlAu6kSN3YvDOm7szuZ8G4="}}
```

## Encapsulation

The script to generate a secret and encapsulate it is as follows:

```gherkin
Rule check version 4.37.0
Scenario qp : Bob create the mlkem512 secret for Alice

# Here I declare my identity
Given I am 'Bob'
# Here I load the receiver public key
# that will be needed to create the ciphertext
and I have a 'mlkem512 public key' from 'Alice'

# Here we create the KEM (key encapsulation mechanism)
# The kem contains the 'mlkem512_cyphertext' that will be sent to other party
# and the 'mlkem512_secret' which is random number of a defined length
# the 'mlkem512_secret' needs to be stored separately
When I create the mlkem512 kem for 'Alice'


Then print the 'mlkem512 ciphertext' from 'mlkem512 kem'
Then print the 'mlkem512 secret' from 'mlkem512 kem'
```

And the output should look like this:

```json
{"mlkem512_ciphertext":"UvH6CxQMxsHVqfZhQ3ac03a4NdLTOn3curr5/PXG2hGXp/L1wyFI0hw/KVAw/wtMFvA9m0xGer7wDm8IMLCR+HdMoq5WaBQqNDOZ3MRMnF8RVpoZHkfw+u61ABF7AbKYGhGMPou+5nA76GnwudsEHE4dMtbJ/6OOvY5dFZe4vEs0ugpkLkC+pcx+sBLEEaIZUveqaxlMOV+KIXz2I7hsYdBFSA8SDMOGes+urjrENDld5zcwd2ZUrpOy1a6PvDyqL2qaYiKyXiItvzVZR5gaFkCi+poZeTfR6ZkWMSr3IxsutEJ1SrFdvPqNL6Fko7JILszldSGREHx2Q1zRvh1iCORT51bDfR87qQC43IHEV70OPoJA7qWS6XJS4VYV2n5P0COQkahIMwGa4dgJJz+kKgdNZ60yhQZPOrIKIfe1VFSMUmMfktaPaOF4zFZqeUoC6YZgwIoy/Bv8q4p/f4q0JBr8MPQ6Ct44D2vFMNMGlY+J5ogx2hOEklV/zPIvBD/AEm1MA4Y/cJNncg63EcalymBZSLhg25Sdhg5NtIGlVPNRuipqWrl3riRnhrxspsBN5GcgXL/M1s/26iS2oK4L4PIfRIur1P94gmU+odlmhQS+J+3EDvWKe4HhueReDEvPhpQvAzbq3weQEuqDRaxNoJEC2OhmSbsJnB99pnzEt+Xgw6SQhtTfSU8/HJrOHcfGjGHj209jpdsYQKz8vUlBNlVHRnPpj83s2JSn3ISd4S9NeqrQpbtLWGtMZa5Gj/4CygRU+XhZriUU3rqRiSlc3SM4YjBgfenTinw6otfCz6ymQa6Lu1vHFqpX2bdf33xPurB26+w4/DHPGoJC1QJ2dSx2tmlqJxC+WEKt7AVHdif/waRK0K5ocOJAbQVfv9MHocRsed2yd2pUbmoyWXfeKet6DTTnaehkbZtySO+YnhbQPwVC7w8B+CHS5c2QYM4Qn3sX/AzspGLqonXB75kJ6lf/wJPc83CF/bnq+FrT8oPJwmhuyZhqCK9C1grOb3fP","mlkem512_secret":"by+KjII8Py8WdKK3JD5o8xYowKjqAjV1dS1KlElpWhE="}
```

Now you have to extract and sent to Alice the ciphertext, you can do it for example using the bash command:

```bash
jq 'del(.mlkem512_secret)' mlkem512_Kem.json | tee mlkem512_ciphertext.json
```

and send to Alice the file mlkem512_ciphertext.json.

## Decapsulation

In this section we will **decapsulate**, and so reconstruct, the secret produced in the previous step by Bob. To perform this action we will need our private key and the ciphertext produced by Bob as input to the following script:

```gherkin
Rule check version 4.37.0
Scenario qp : Alice create the mlkem512 secret

# Here I declare my identity
Given that I am known as 'Alice'
# Here I load my keyring and the ciphertext
and I have the 'keyring'
and I have a 'mlkem512 ciphertext'

# Here I recreate the secret starting from the ciphertext
When I create the mlkem512 secret from 'mlkem512 ciphertext'

Then print the 'mlkem512 secret'
```

The result should look like:

```json
{"mlkem512_secret":"by+KjII8Py8WdKK3JD5o8xYowKjqAjV1dS1KlElpWhE="}
```

obviously this secret will be equal to Bob's secret.


# Streamlined NTRU Prime 761

Streamlined NTRU Prime 761 is a Post-Quantum Key Encapsulation Mechanism defined over lattices. For simplicity in the following it will be called NTRUP. From the user side it works as Kyber:
- **Key generation**: The *recipient* create its private and public keys
- **Encapsulation**: The *sender*, starting from the recipient public key, generate a 32 byte secret and encapsulate it producing a ciphertext that will be sent to the recipient
- **Decapsulation**: The *recipient* can recreate the secret generated by the *sender* using the received ciphertext and its private key

## Key Generation

### Private key

As above, the script below generates a **NTRUP** private key.

```gherkin
Rule check version 2.0.0
Scenario qp : Create the ntrup private key
Given I am 'Alice'
When I create the ntrup key
Then print the 'keyring'
```

The output should look like this:

```
{"keyring":{"ntrup":"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"}}
```

### Public key

Once you have created a private key, you can create the corresponding **public key** with the following script:

```gherkin
Rule check version 2.0.0
Scenario qp : Create the ntrup public key
Given I am 'Alice'
and I have the 'keyring'
When I create the ntrup public key
Then print my 'ntrup public key'
```

The output should look like this:

```json
{"Alice":{"ntrup_public_key":"4/FNig/iWowwYSBt/XSfcIv0U6JxiZuwoh4z+f2RWGZVzKhWBWJa8DYku0PmHvHRFhGQD8SIIYFBEEza7uuZDNU7IqRcjheL/Rfj4by+lT4IYJoANrlaUHacZpRBEmff6HP5uyMQ2xXtBTfIRuGTsP5tJhlSfLj5BBURxXC6sq18Ja422BCooZWmtniqaiXRMsyvMUfu+Fr8xW/n8uuWMRRSdfOGQrliboqKuISnyAYbWMoGG04wehEuQSMOuaSvAFaUs0cR8hiRcxyEqSDobkQfAyBG+O9jL/ZPmTkoWlvUUoQiCl4sow380/A7CdqOSt2bFIivCgBBU04NJy9U6gNvohk4zQJhMEk8yFywsPnpteJulMDJjZOFW2eCQfXO4Pei84BHkUjIUPPx3lSr6WjRrisCSF3dpl+vn85gI60rdpn7g/jIWc4iwzAZOVZ8WWOoYQCD7bHKq0hamtwqBBBSKx4Xp3rCFN5yDDPWNi0m0Z5vRyV74xh0+AXEoTh6IjZzZDoepQQ7MzRTLRzqVmDePNQjT4W4QMk3Ar16UJ631LeCHyjtTz8Og1+vXCB3bl1jrguljl3CtFGL+PcXrMfcfR3/7yHKuRd1m+Ge8D6TXIrjSGNNKr+YJ64rLgtFDhg4Lwr91HE0lRbDBKrVSFC61P/pe4t8cBLCVJ0vJYSd9FfDKyQd2Pl4ocnnHNVF7KXgH/HzcohNDhTJZZK/kSgUXUqsj2JBI5nmPmV4U6/fx+dnNABCUuyYD3h4LhoD0TeZcB6ZavY0sga3jdF3r0+cNNX1ilrFaXnuTSVYkQXaFECpjbJZZ2AjSRUi8gdNlz5mvNz8zCWP/ChQt6QaObIpL12G/GSLxIyYS1m7o/03lV6lUM16vaGHDr3SEUJLAWtYyKzyr3CKqbRLurUcsHh0esuVv/iPfepQ+zSEvtg4TU+Dg4SP0RmMnLKIZOtEXG9Rsvpq/P7h52sbXxwHjkxhA0wNG29KJ4A0x+GtUpSDiEFW4ZufhZwoTp0X/gDYYfv1tseiqgWUiaH0JkgWspqLceZvd1huwgfFW/Gba+G9mgVXDgfx0y/ju2X8b34RbI0p5rJYkflI8rBTpac2bfhqg/8GAYNUf+wTzlfbBBmyxbK79QAXtC3Pi3kDALtxJfWyq+zwvix3j+LvKOmxOdzUI65M8mgNSvXItHvIpxVQrUHfh5Dq6INvIr9+HWAbaY1/JJRr/7HkppWmnFkF3VUM8V9ymnsmz1CfTZ0pVpxT44iTJ0NltR3nsAs8BKM3SCey0gsjfcZI7DT/d547J0fxon70qqEEQkk/Cgu02XNFXd4DHOgTE6ujb77v1/bpm1wXtErgDHQ4A73Jib8O2yDuwqpumSkeC6Bm8cHOK9uca0COajJbH2o4OGs9Zji+4fzZCH5Er5y8MtregB8WHxaUNaSDL++T8WAzcFgAxBHZoMx9gJg8eWNB/dSM188Locfi/AYQu1xqOZq+vRSqbTqUW0bGg8RhuCaBvbpjc7TXAKe27BRDS0ogqdYNF+BnWl23crkC"}}
```

## Encapsulation

The script to generate a secret and encapsulate it took as input the receiver public key and it is as follow:

```gherkin
Rule check version 2.0.0
Scenario qp : Bob create the ntrup secret for Alice

# Here I declare my identity
Given I am 'Bob'
# Here I load the receiver public key
# that will be needed to create the ciphertext
and I have a 'ntrup public key' from 'Alice'

# Here we create the KEM (key encapsulation mechanism)
# The kem contains the 'ntrup_cyphertext' that will be sent to other party
# and the 'ntrup_secret' which is random number of a defined length
# the 'ntrup_secret' needs to be stored separately
When I create the ntrup kem for 'Alice'

Then print the 'ntrup ciphertext' from 'ntrup kem'
Then print the 'ntrup secret' from 'ntrup kem'
```

The output should look like this:

```json
{"ntrup_ciphertext":"aHZConSJrN6RAJ/aeMmm5twbFEA5LmD0U0VfriZSAHWjtXuE9S0UDEZf1LoF/nSbVLILx3hDkXnnXuQppw3ykXNpbOkAqT6Gnx4QwKfjCBi0x9Git3Q54MwDxnRwRDDdGofndx741N8LdCPOCkd3KvXnTxLBq3EVuCZyHPO3jWKFEJ6nRX27JcNftNlH4pQv6mITsz0nWRpLIBmt7506svQDyDfiRlKgtsX/ErC54GWMidthZzmwti3FLuzpW33AIz1tyvPEOpXfFBZbYqELsdjhmCZriqYALXqBFj8SIqkwwKv8vZ/AX2cmUJkQBCl8ODfJHYxvcv/rW+FMlviCf2nRinMH38iaiVftVz0RGgikzOtWmr9tcgRs8AApuBRqXTAPFbQfzxyHzfduGxfcy/rSN4QW9Qyo3ea+IutNICOgjrJrlde0R8OODOxo0M1eTn38AO5sUsVPumJIeFOWATSzJIUkbLf+xODAxuPrmwFkEjQ1D91qatWu4GsX7qTmhyRy/RfuSotGilZ+40lUfT9xZUJsqAxuEs8BqPJbuwHqkEN2Ttx6jYk0td30/F7WdnqjQvZVWDidOzhIlrRtK7vd9LMKHxHasZKKOIsFaFc8ZWQwEgpNoC324GgdhNHHX6lkiMideMmts3btha8L14tGUXYC8enRLzYIC4zLsUpWmf9mylJ3PVSRdjODlZeW5AAzdHDf8qOzJ8yqh8Vs/96QTo7A3qtW2f07HQ/ovswM0PwF068bciIIA91cWFwcjIAs+80Xbl6olaML0CV2v+CzSQyVar2dSYWg7oAvDW5g4H8ABiODaDo90C4eh54UKagmd/XyuJDFzB39EeJNeZU5cVnXz8w3BWEXtcH2EvXvD5+biqcKh4s2SXrVMJjvy3TFO90QBFujDhZrNF0oMlgzY8LXcm1sgPojhpA4f1QMJZpKE5N1jX4qsYJSs+A4x6smvAKVcqxxAeB5iSo6upQQ+0wd06+fkdkZw8drWvG/ecnigBMoA+Wa3h573pfLWnhFuJwYRI1Nm9y9HNuyU6YU7xTCzueRgr1lx2iUDiUJPIiHGuWB9BBEzRtzvpX2gg+QmIpudc3eFGVeqxBE/lwTPEUkj/eqjOljLK5vUdtvcGRDpmzUKV4mnAkpx8yoGsRwwJKlCUcXRgFbzC0IUI5k0hkhyPNKILKFT5QQ06qYCxovSmxOnsXbfgba7oZtsN8Kfx3c+L9A7CwEwR/fhYvv0WYP4hxX5bc8mSpgNCvGj8AKuLq8hIAp8drH8WacMfKNKzD8CgxaShSXGhLz3dRy7FXWZlV6z0L9fg/vszlnNoOuMz5Z7TLN48KYgAuXO+BHEBbX26mk2qG0FAxuEb+0crQEDhEjUwUMY37Jkw==","ntrup_secret":"/su5iQuBMXE5lvcBjBD1biJ+h4c3lP7YlZO8hLeVHOk="}
```

Now you have to extract and sent to Alice the ciphertext, you can do it for example using the bash command:

```bash
jq 'del(.ntrup_secret)' ntrup_Kem.json | tee ntrup_ciphertext.json
```

and send to Alice the file ntrup_ciphertext.json.

## Decapsulation

In this section we will **decapsulate**, and so reconstruct, the secret produced in the previous step by Bob. To perform this action we will need our private key and the ciphertext produced by Bob as input to the following script:

```gherkin
Rule check version 2.0.0
Scenario qp : Alice create the ntrup secret

# Here I declare my identity
Given that I am known as 'Alice'
# Here I load my keyring and the ciphertext
and that I have the 'keyring'
and I have a 'ntrup ciphertext'

# Here I recreate the secret starting from the ciphertext
When I create the ntrup secret from 'ntrup ciphertext'

Then print the 'ntrup secret'
```

The result should look like:

```json
{"ntrup_secret":"/su5iQuBMXE5lvcBjBD1biJ+h4c3lP7YlZO8hLeVHOk="}
```

obviously this secret will be equal to Bob's secret.

# Benchmark

In the following we will compare the Post-Quantum algorithms with the most common Elliptic-Curve algorithms (ECDSA, ECDH). All the results in the following are generated by the script [benchmark_sig.sh](https://github.com/dyne/Zenroom/blob/master/test/zencode_qp/benchmark_sig.sh) and [benchmark_enc.sh](https://github.com/dyne/Zenroom/blob/master/test/zencode_qp/benchmark_enc.sh).

## Key length

As first parameter we will look at the private and public keys length (measured in bytes).

| Sizes      | private key (<span class="unit">B</span>) | public key (<span class="unit">B</span>) |
|------------|---------------------------------------------|--------------------------------------------|
| ECDSA/ECDH | 32                                          | 65                                         |
| Dilithium  | 2528                                        | 1312                                       |
| Kyber      | 1632                                        | 800                                        |
| NTRUP      | 1763                                        | 1158                                       |

As we can see they Post-Quantum keys are much longer. Will this affect the speed of the algorithms?

## Signature

We can divide the signature in four main parts: the generation of the *private key*, the generation of the *public key*, the *signature* and the *verification*. As can be seen from the tables below the Dilithium *key generation* is **not affected at all from the key length**, indeed both the key generation time (computed in microsecond) and memory (computed in Kibibyte) are not very different between Dilithium and ECDSA.

| Algorithm | Key         | Time (<span class="unit">&mu;s</span>) | Memory (<span class="unit">KiB</span>) |
|-----------|-------------|----------------------------------------|------------------------------------------|
| ECDSA     | private key | 13678,5971                             | 617                                      |
|           | public key  | 15226,2096                             | 615                                      |
| Dilithium | private key | 13485,2965                             | 650                                      |
|           | public key  | 15343,0342                             | 637                                      |

Regarding the *signature* and *verification* algorithms the test was performed on different message lengths: 100, 500, 1000, 2.500, 5.000, 7.500 and 10.000 bytes. The **results are amazing**: the time and memory consumed by the two algorithms are really close to each other. Their are shown in the following tables where time is measured in μs (microsecond) and the memory in KiB (Kibibyte).

- Signature:
| length | ECDSA Time (<span class="unit">&mu;s</span>) | Dilithium Time (<span class="unit">&mu;s</span>) | ECDSA Memory (<span class="unit">KiB</span>) | Dilithium Memory (<span class="unit">KiB</span>) |
|--------|----------------------------------------------|--------------------------------------------------|------------------------------------------------|----------------------------------------------------|
| 100    | 16081,6516                                   | 16836,6952                                       | 622                                            | 643                                                |
| 500    | 16231,4911                                   | 17385,6549                                       | 625                                            | 646                                                |
| 1000   | 16410,2233                                   | 16711,5771                                       | 629                                            | 650                                                |
| 2500   | 16900,9023                                   | 17178,8706                                       | 641                                            | 662                                                |
| 5000   | 17852,7499                                   | 18490,5152                                       | 660                                            | 681                                                |
| 7500   | 18810,2357                                   | 19303,2178                                       | 680                                            | 701                                                |
| 10000  | 19812,6163                                   | 20748,2910                                       | 699                                            | 721                                                |

In order to have a better view of the time consumed by the signature, you can have a look at the following graph:
```
�PNG

   IHDR  @  �   �M��   9tEXtSoftware Matplotlib version3.5.2, https://matplotlib.org/*6E   	pHYs  a  a�?�i  �9IDATx���wx�������NȀ0�H��7��Zg�"P��n��V��Vkkk��VѪ�Z[���(j�[�e�V�	+��B����;9y�����;�|���ܟ��7�D"H�$I�$I�$Ő��H�$I�$I�$�4I�$I�$I�s,@$I�$I�$IṞ �$I�$I�$I1�D�$I�$I�$�I�$I�$I�s,@$I�$I�$IṞ �$I�$I�$I1�D�$I�$I�$�I�$I�$I�s,@$I�$I�$IṞ �$I�$I�$I1�D�$I�$I�$�I�$I�$I�s,@$I�$I�$IṞ �$I�$I�$I1�D�$I�$I�$�I�$I�$I�s,@$I�$I�$IṞ �$I�$I�$I1�D�$I�$I�$�I�$I�$I�s,@$I�$I�$IṞ �$I�$I�$I1�D�$I�$I�$�I�$I�$I�s,@$I�$I�$IṞ �$I�$I�$I1�D�$I�$I�$�I�$I�$I�s,@$I�$I�$IṞ �$I�$I�$I1�D�$I�$I�$�I�$I�$I�s,@$I�$I�$IṞ �$I�$I�$I1�D�$I�$I�$�I�$I�$I�s,@$I�$I�$IṞ �$I�$I�$I1�D�$I�$I�$�I�$I�$I�s,@$I�$I�$IṞ �$I�$I�$I1�D�$I�$I�$�I�$I�$I�s,@$I�$I�$IṞ �$I�$I�$I1�D�$I�$I�$�I�$I�$I�s,@$I�$I�$IṞ �$I�$I�$I1�D�$I�$I�$�I�$I�$I�s,@$I�$I�$IṞ �$I�$I�$I1�D�$I�$I�$�I�$I�$I�s,@$I�$I�$IṞ �$I�$I�$I1�D�$I�$I�$�I�$I�$I�s,@$I�$I�$IṞ �$I�$I�$I1�D�$I�$I�$�I�$I�$I�s,@$I�$I�$IṞ �$I�$I�$I1�D�$I�$I�$�I�$I�$I�s,@$I�$I�$IṞ �$I�$I�$I1�D�$I�$I�$�I�$I�$I�s,@$I�$I�$IṞ �$I�$I�$I1�D�$I�$I�$�I�$I�$I�s,@$I�$I�$IṞ �$I�$I�$I1�D�$I�$I�$�I�$I�$I�s,@$I�$I�$IṞ �$I�$I�$I1�D�$I�$I�$�I�$I�$I�s,@$I�$I�$IṞ �$I�$I�$I1�D�$I�$I�$�I�$I�$I�s,@$I�$I�$IṞ �$I�$I�$I1�D�$I�$I�$�I�$I�$I�s,@$I�$I�$IṞ �$I�$I�$I1�D�$I�$I�$�I�$I�$I�s,@$I�$I�$IṞ �$I�$I�$I1�D�$I�$I�$�I�$I�$I�s,@$I�$I�$IṞ �$I�$I�$I1�D�$I�$I�$�I�$I�$I�s� �V�p�6���A(
:�$I�$I�T�D"v��E˖-���g�u�Y�H�bÆ���C�$I�$I��
���:��!�Sddd �/Й����$I�$I�ꖒ����ϳIǚ��)��*33�D�$I�$I��������$I�$I�$IṞ �$I�$I�$I1�D�$I�$I�$�w�H_QUUA�P���H|||�1$I�$I���b"}I�H�M�6�s�Π�(4lؐ�͛�L�$I�$I�! җt��h֬iii��֗�Dػw/�7o�E�'�$I�$I�b���%TUUU��7:����T 6o�L�fͼ�$I�$I�T\�.}	v~����D�����d$I�$I���a"}��J5��%I�$I�$�fY�H�$I�$I���c"�i۶-��{�Q}��.��Q�F�א$I�$I�T��]
PU8¬��ټ��f)l�M|\��
i���4hРF���?�]�v|����ӧz�����H$R#�!I�$I�$�� ��Ң����6�V�Zd�p��n�֣E�Ɏ��M������:�!I�$I�$���XR ^Z��+��{H�����+���K�6��޳g\p���hт�ﾛN8�k���ަꗿ�%�w4�U�V����?��D"���?�u��$''ӲeK~��T?�߷�Z�t)Ç'%%�nݺ��k�
��:u��V�v� �۷/�P�N8��-�N8����j���Z5jDNN�<�{����/&##��;�_|��_�h��~:������p���u��#�8H�$I�$I
��TC"�{�+?�׮�
n}v1��IӁ�ϟ]®Ҋ#z�/z���������<��3���+���[̝;��c��.z���|��~�#���^}���}�)S�p�=�����b�
�N�JϞ={lUU�F�"--����?����'?9��c֬Y ���klܸ���z�S�}���iҤ	�f��ꫯ�+�`̘1:��s�r�)�p���w�^ v��ɉ'�H߾})((ॗ^�����c�q>I�$I�$I��XR�WQE������'l*)���_9����TҒ���ʻw����3O<����7�h9���{�qÆ�G?� �:ub����s�=�|�ɟ��k׮�y��t�I$&&Һukx�c_}�UV�Z�[o�E���������q���i5nܸ��?M�޽��[ �����o~C�&M�������~ƃ>Ȃ<x0<� }�����o�~�G}���<�/_N�N��(�$I�$I���x�T��Z����rT=��Φs�·7dȐO���?���3f���}��\~��<���TVV��e˖���wHy�ie�WիW�������q�Ƈ\������͛�?>o��&���տ�t�D?��$I�$I�j?� �jHjb<K~q��7k�v.����=0�]��nm���ǲe�x��x��W�����]w���o�Mbbb`����C��!�P(@8�Wʌ9������x�-bsA�$I�$I�k,@�
���VT#:6�EV
��K�$4�JaDǦ�ǅj4c�HLL���ߧu�� �ر��˗�}�����{{���ڵ��Fjj*#G�d�ȑ\y�t�҅�ү_�C��ܹ3���U_�1{��C$%%�]"5�_�~L�2��mے���II�$I�$�.�X�1�֑݀h����֑�j�� HOO��K/�?�!o���-⢋.".��/ӧO��;�d�������g���\s�5����=���Y�h}�O<�����i��Ǟ|��t�Ё/��0}���=���,͚5#55�zAyqq�~>ߕW^����9��={6�V���_��/>*��$I�$I���g"�-x�;�h��rȼyV
~���8z�Y�뮻1b#G�䤓Nb��������c���z


�۷/��կ�0a������jذ!�<�Æ�W�^���k<��s4n������3u�Tv��̀�����O~@JJ�'��o			�w�}<��ôlْo}�[G��|-[�d���TUUq�)�гgO���Z6l���H�$I�$IR��D"���T����Eqq1����<VZZ��իi׮����4U��Vog�R�e�0�]�Q����p�	��Ӈ{ｗ�m�r��r���ӧOg���\��:��RM}NI�$I�$��u~M:������C:|����駟&==��;�r�J����V��I�$I�$I5�{�H:b���IOO?��ݻ��۵kW���.����3� p���k�~��5��I�$I�$I�1�K���Xuͮ]�(**:�c����]v�em߾��۷����TZ�jUc�U���)I�$I���rk���[`)h�K���� ##㘼Vvv6�����$I�$I����m�疰���z�"+�[Gv�-L&�o�%I�$I�$I��K�6r�s)? 6�r�syi�ƀ�I��D�$I�$I����p�۞[��v������n-�j��$I�$I�$�Vo�ĕ�)l,.e����E���X�H�$I�$I�1�f��#:n�O/I$9I�$I�$I:�f������숎m��r��H�����䢋.bԨQ�>����k��k�mۖ{���<����H�$I�$}�U���b���ٺ���ЧZd�0�]�1�'Ų��H�Z�
�̀�E��m�B\|Щj�ٳgӠA�y��?��v����ЧO����~�;"�I�$I���n^�N�O��G[���:o`k��f��y �,C?Ћ�:��q�ђH:b RP�</�%�2[�i��ng��kڴ�Q�������$I�$)�UT�������UT�#4�H����띛���m�-9d!z�nٍ�z�*�s���%�¤-? J6F�K�=j/���;h׮�����ݛ'�|���ŋs�g���IFF#F�`ժU TUU1~�x6lH�ƍ���{�D8��o$;;��͛������E"~��Ӻuk���iٲ%?�����[`-]���Ç���B�n�x���BL�:�s_�]�v ��ۗP(�	'� ��^W_}5�^{-�5"''�Gy�={�p������q�ǋ/�x��/Z���O?���trrr8���ٺu�}$I�$IRݵ�hg�a:�����p���[��u�W� ��h��7��?/��݇^>�wo:��C�a RM�D�|���*-�o�Ћ��$��K7E�;�����k��;��_��C=��ŋ�����w���o�����9���INN�7�`Μ9\r�%TVVp��w��c��裏���}�v�~��O���?N�x������;��/~������٦L��=����?̊+�:u*={�<�UUU�5���4��}���?���?�f���^c�ƍ<��S�z��?N�&M�5kW_}5W\qcƌa�С̝;�SN9���?��{��s�NN<�D���KAA/��EEE�;���I�$I����*�w>����e���%r�y}����4LK����q!�th̷��bH����J:
��TS*���-k��"�+C~�wd��x$�^���2n��v^{�5�@���y��wy��i۶-YYY��_�"11�N�:U�������7��9��C=��/�����ի��z+ ;v����_��O��|k׮�y��t�I$&&Һukx�c_}�UV�Z�[o�E���������q���i5nܸ��?M�޽��[ �����o~C�&M�������~ƃ>Ȃ<x0<� }�����o�~�G}���<�/_~��T�$I�$�}k�������v �޹)�݋f�)'��7�Y�r%{���DIP^^N߾}ٹs'#F��.?�Sqq17ndРAճ�����?q�^�z��-Z�y����7f���^ڷo�i���7��MF�IB�'�T-[�����CʋO+K���|���iܸ�!W���� T�������7�$==�ϵj�*I�$I�bD$៳
���K�[^E��xn9���G(�R�,@�������?����'���#{�#�{�n ��yZ�ju�c���\{�G�\��
�P(D8�ܷ���cٲe���k���|���箻����>l)s�����ف�xw���ȑ#��o���j��{yJ�$I�6��r���l �fs����e��IG��TSB�#�U�!�et��a�����w8��k4b�n�HNNf�ڵ|�k_���z��������'����hѢ��>�< ���̙3�~���X���TF��ȑ#���+�ҥ.��kt�ܙ��B�������={��NRR�ޛUUU5���~��1e�ڶm{ثW$I�$IR�������E��[ARB?<�3�o����̜t����i��I !-A��%y�oj�� �����n��#3|�p����>}:���\u�U���|�����o&++���{��ҹsg���~��бcG�t�	عsg��{�Ǩ��bРA�����O���J�6m>q��'�L�������;ٵkW���#�ĴY�f�����K/���KJJ
YYY5�~\y�<��#�w�y�x�dgg�r�J����?�������V�$I�$};����g����]@z��d��>t��8��É:�T/u;��2��vH�-��ng����/�O�S���v��i�����?O�v�hܸ1o���w��k_�����G�����������/dȐ!dddp��g�X����#�0l�0z���k���s�=G�ƍ?ql||<S�Ne���0��.�����' ��|�������>~�aZ�lɷ���{?Z�l���ө���SN�gϞ\{�4lؐ�8��J�$I�T��l3������@|\�|�#O��T��"���X %%%deeQ\\Lff�!�����z�jڵkwD'�?U�*�dw��Dw~�+?��ӧ3|�pV�\I�������$I�$I�Q{�*�����Ykhߴ���C＆��>���t,x,)Hq��nD�)꬧�~���t:v��ʕ+��k6lX�+?$I�$IR�4k�v��<���� �xX[n:�)�� �Tx/I�����w�����{��_��v��U�(���.b��<��3 �~���Z��~zM�k�$I�$)��VTq�2�3)ܾ�VS��僸udw���Xҧ8&���gv��EQQ�aKLL<��/k���l߾������ҪU�{����$I�$I�â�Ō�4��E��?����FfJb���o���y,I�LFF�f1Xvv6�����$I�$IR�WY���V��WP��$=�;�����r��&�K� �$I�$I�T��ڲ���3�p' �uoί��A���`�I�J,@�� A1��%I�$I���p8��3?�7/.��2LFJ��VwF�iE(
:����D�������cÆ4mڔ��$�Rԗ�D(//g˖-��ő��t$I�$I���;�qä���h #:6��s{�"+5�d�j���%���Ѯ];6n�Ȇ������F�֭���:�$I�$I1-���u��%�*�$51�����p�b���%%%%Ѻuk*++���
:����x�G�$I�$IG���e���B^]R@���{l�5ip2IG����B!ILL:�$I�$I�>�K�6���}O9��!�;��=��q�@��,@$I�$I�$Ŭ�}���b��`= ]�g0al���8����D�$I�$IRL��b7>���ťą�_���'u$9!>�h��I�$I�$I1eoy%�yq)���6�Ә0�7��d�Lұd"I�$I�$)f�]���'�g��= �?�7�iI�
���_/I�$I�$��+�s�k�y��U�#�<3�;����MR@,@$I�$I�$�in,a���|��������#����p2IA� �$I�$I�T'U�#�񝏘��2*�"4JK���{rz�AG�TX�H�$I�$I�s>޺��'�gΚ �Եw�Ӌ��'�T[X�H�$I�$I�3"�O���۟��}U�''���?�P(t<I���$I�$I��:aSq)7NY�;˷ 0�}6�7�7���N&�6� �$I�$I�T�E"�����=����J���.\4�-qq^�!��,@$I�$I�$�Z���s�ԅ��p �r��0��5K8����D�$I�$IR����E�4e![w����;���w 1>.�h�� I�$I�$I�ʮ�
~���XP@�f�Lۇ��Y'�T�X�H�$I�$I�5f�����~�>B!�lx;�?�3)��AG�T�X�H�$I�$I
\iEw���G�� �Q*w��͠��N&��� �$I�$I���vr��y�ڲ����3�����KI_�_A$I�$I�$��*�o��7WR��4#�ߎ�ɉ]r��&)X�H�$I�$I:�V�b���,\_��Z�o��Q����I� �$I�$I���p8£�Ws���(�����/G���-��&)�X�H�$I�$I:&
�����y�v �֩)w�ۋ�̔��I�E �$I�$I���H$¤�B~����W���O����lM(
:��e"I�$I�$�ټ��MY�K70�m#�oLo�4np2I��D�$I�$I�Q�����2u!;�V���v���퉏�IG��$I�$I��U����=��g�m �{�L&��C��'�T�X�H�$I�$I�1o/�OΧ������?�W�ؑ�����I�g,@$I�$I�$}e{�*������khߤw��M�֍N&��� �$I�$I���|����v�^ .ږ�N�BjR|��$�g �$I�$I�����*&���?�����J�1�v\���I��$I�$I��/n�b�O�ϲ�] ��˭gu#3%1�d�e"I�$I�$�UV�y��U���TTEh� ����ɩݛM�a"I�$I�$�|�e7�'�g^�N N�ï��I���`�I�aX�H�$I�$I�L�p�����;^��Ҋ0�	����ӯ�P(�x�tX �$I�$I�>Ն�����r Ïk���e�Ԁ�I�g� �$I�$I��	�H������-fWi%)�q���]�Π6��yՇ���D�$I�$I�!��.��O/���E �mݐ����}��Iґ� �$I�$I�T��ś��Sٶ����מԉ�ߞ�����I�b"I�$I�$���
n{v	S��sN���{ˬ��Iҗc"I�$I�$�s�Wn凓糡��P�{|�;�#�	�AG��/�D�$I�$I����W�ۗ��،�h�8����&�mv��$�X�H�$I�$I��kwp���|�u �;�5?�fW${�PRl�$I�$I�T��W�����᭕�#����oG���͂�&I5�D�$I�$I�'�m��u�dc	 ��Ӓ_�Ճ��Ā�IRͳ �$I�$I�b\U8�}�ݯ,��*L��D~5�'g�jt4I:j,@$I�$I���f�n�<��� �]�q��4�H	8�$] �$I�$IR�D"�c�Z~����-��AR<���Θ�\B�P��$騳 �$I�$I�b̦�Rn�����o`P�l�oLo��N&Iǎ�$I�$I�C�����N]D�
�����\2�qq^�!�~� �$I�$I�b��=����"�_������0�7s2N&I�� �$I�$I��7�qӔ�l�UF|\��O<�+�~��qAG���X�H�$I�$Iu��J~��%�kv! �5Kg�����ml0I�,@$I�$I��:����q����۱�P.֎�ڙ�����IR�`"I�$I�$�!�U��������D"Ъa*w��������&I���$I�$I�TG,\W��I�X�y7 ����̮d�$�L�jI�$I�$����
�7Wq�+�Gh���oG��]s��&I���$I�$I�T��ܼ���`]1 ��ٜ_��Iv����IR�f"I�$I�$�B�p�����;_ZJYe�̔~9�g�nI(
:�$�z �$I�$IR-S�}/?|r>�}���;5��ѽh��p2I�;,@$I�$I��Z"�0y�:~��v�U���O����j�U��Y�H�$I�$I���]��������f ��i��czӶI���IR�d"I�$I�$�Ņ���ٱ����8Ɵ҉�G�'>Ϋ>$�˲ �$I�$I�R���[�]��y ��"�{���K�̀�IR�g"I�$I�$���[���l*)%.W�Ёk�щ�����IRL� �$I�$I��������R��� �5i��c{ӯu���IRl� �$I�$I���9k�s���|�m/ i�M�w!-��t�T���*I�$I�$ee�U���
~{���J�s{3�c���IR̲ �$I�$I���7�p��y,ݴ�s���֑��JM8�$�6I�$I�$�(��
��;q�k˩���� �����i=�M��I�$I�$���޺��'�c�ڝ ��-����Iӌ�`�IR=b"I�$I�$ՐH$�����������n=�;���"
O��I�$I�$�l,�ǍO.`ڊ� �И����U�Ԁ�IR�d"I�$I�$}�H�����g�����8n>�iK\�W}HRP���r�w0`� 222h֬�F�bٲe�SZZʕW^I�ƍIOOg���r�ڵk9�3HKK�Y�f���?����c�z�-���Grr2�w�=��'������m۶���0h� f͚U��$I�$I����.�'�r����*��w^C^�fkg�!I� Q�z����+y��x��W�����SNaϞ=��\w�u<��sL�<���~�6p�9�T?^UU�g�Ayy93f�������g?�Y�1�W��3���_�:�����k���.��_�>f�ĉ�?�[o���s�һwoN=�T6o�|l>�$I�$)�����S�}��o"!.��'wb���Сiz��$I@(�D��صe��5k��o����Oqq1M�6����{. K�.�k׮̜9�����/r�g�a�rrr x衇�馛زeIII�t�M<���,Z�������o�s�N^z�% Āx�� �����q��W���s�������Eqq1���5���$I�$IuԮ�
~��&�Y@��t&��C�VY'�jϯ)h^��������l �̙CEE'�tR�1]�t�u��̜9��3gҳg�����SO����ŋW��q���Q^^Μ9s9&..��N:��I�$I��/jƪ��v�4&�YG(�=�=�^5��C�j!���	��\{�6�=z �i�&���hذ�!����iӦ�c���8����>똒����ǎ;���:�1K�.=l޲�2��ʪ�\RR��cI�$I��J+���KK�����N��1}�.;�`��Oe����+�dѢE���AG9"w�q��v[�1$I�$IR-3�p'�'��-���l�O��Jz���$�6�X:*���*�����o���[=o޼9����ܹ�㋊�h޼y�1EEE�x��c�uLff&���4i҄����s�9���7�Lqqq�����/��K�$I���QQf�+���>ڲ�f�����qNO�I�,@T�"�W]uO?�4o���ڵ;���������믿^=[�lk׮eȐ! 2���y���c^}�U233�֭[�1���9�III�����c��0���z�1�-99����C~I�$I���iy�.���t�{c%U�#{����띛M�t���U����J����3ϐ��Q��#++���T������K?~<���dffr��W3d��)��B�n�8�����;ٴi��rW^y%��� |�{����o�K.�7�`ҤI<����YƏυ^H~~>��{�eϞ=\|����#I�$I�ꄪp�G�]�]�,��2LôD~5�g�jt4I��D"��C(v�B�����p�EPZZ���_�?��O���8��S���pȭ�֬Y�W\�[o�E������o~CB������cɒ%����ӟ���5x���뮻شi}�����cРAG��������Eqq�W�H�$I�T�ݶ�&�g����z��vt/�e��L��<���Y�H��/В$I�$��H��.��^���*$�s˙�����O�aOI���k
����$I�$IR�������,��e[ �6����&/;-�d����D�$I�$I�ҿl����ع����8~xJg.ގ�8����X`"I�$I��ze��r~��b�����2�0��r2N&I�I �$I�$I�7�\����\��]e�ǅ����q��Ǒt4IR� �$I�$IR��SVɯ����Z@���glz�56�$騱 �$I�$IRL��z;�O�G��} \<�-7�օ�����I��&I�$I�$ŤҊ*&���G�}D$��rט^��$�h��c�D�$I�$I1g��b�O���� ���OGv#3%1�d��c�D�$I�$I1��*̃o��w���2�Izw�Ӌ���M�t�Y�H�$I�$)&�ڲ���3�p' �uoί��A���`�I�a"I�$I��:-���̏�͋K)�����/�՝Q}Z
���'I
��$I�$I���;�����j #:6��s{�"+5�d���Y�H�$I�$�ΉD"L���۞]̮�JR���7���m��C�X�H�$I�$��ٺ����ZȫK� �׺!w��C�&N&I�M,@$I�$I�Tg��h?~z!����⺓;���;�U�c�U�f�.��h3��N%�I�$I�$�z��*����<��z �4�`��>tk�p2�KX�,�t�l88�l	����\.)�X�H�$I�$�V��b7>���ťą�_���'u$9���W��Y�t9t^�1:�WK��X�H�$I�$�V�[^�o^\�_g��m�4�ۛ�m�N&}I���]~��Y^�t9��aI5�D�$I�$I��ܵ;�~�|Vo�����p�7�����,�akfz۫O�@���q�F�XR��oI�$I�$��a~��r|k�4�L��s{q|��AG����
X4�Ȏ�]tt�H���$I�$I�j�7�0~�|>�X��}[����JK8��T샹��AqᑽMz���$� �$I�$I
TU8����{^]NyU�Fi��~vON��"�hҗWZ���={�DgiM���vq�= !�l	m�ˤR̲ �$I�$IR`>޺�&ϧ`� N�ڌ;��Eӌ䀓I_��-���0�(�^�D��0�Z����t��$��߸ ]�! �$I�$I:�"�-�~�C�UT�����FvcL�\B�P��/ng!̸��*�EgM�����h��*��Y0����M�.D�l-?��u�K1�D�$I�$I�Ԧ�Rn���w�Go4�}6�7�7���N&}	[���{a�DWFg��È����ɷ�vt9�̈.<Oω���+?�e"I�$I��c"�����t�"JJ+IN��Ӻp�ж��yՇ����	��Y�oe��k0b|��ϻ�).ڍ8�)�z�D�$I�$IG��=��2u!/,�@��,�ۇ㚥�L�"��U��U��w>#Z|���M�'X�H�$I�$�z��"n������H��ot��'t !�0��j�H$��|�(|/:�C�s���s�O��Y�H�$I�$��UZ����!
��,�	c��37+�d�
W���0�(Z��'C����@��A���9,@$I�$I�T�f�����~�>B!�lx;�?�3)�.yVPY��]n����,)�/�!WBF�@�I:2 �$I�$I�1�U���2���j r�r���j�8�d�(�s��î�Yj6�^����'�� �$I�$IR�X�n'�'�g��� �70���э�dOA��۷f=�=��Gg-a����BHjl>I_��H�$I�$�+��
��+y�͕T�#4�H淣{rb����I�m�&��{(xʣ����{��'髱 �$I�$Iҗ��h�'�g��b ��Ղ_}��$�L�;>����O@UYt��F��n� �]5R,� �$I�$I�Gxt�j�|y�a�R���ջe�ѤO��Cx�X�$D����A0�z�x
�B��T�,@$I�$I��n�������讄�ujʝ��"'3%�dҧX7��˞?8���h��f�Ň�,@$I�$I�tD"��

��sK�S^EZR<?9�+�3�5!O ���D`��0mB�w B��,~��h<IG��$I�$I�>��]��h�B�X��m�czӦq���I�%��/F��X?':�K�^��͛v
4��c�D�$I�$I����e�Bv� )>�N�ĥ���U�E�*aє莏-Fg	)��Bz54�6��c�D�$I�$I�U����=��g�m �{�L&��C��'��CE)��;L��\�%g���a���4�|�c"I�$I��Ox{�n|r>E%e�ǅ��	��Ď$%�M�*��������,�	�>�R���')p �$I�$I������_�������Mp����m�(�d�~{��������8:�̅a�@��@RZ��$� �$I�$I����\?y>k��ࢡm��.�&��LJ6��`�_�"�9J�0�:�9���'�ֱ �$I�$I���*����r���GD"�2+����f�qM��&��U0�^��OWDg-zÈ�˙gA'��,@$I�$I�����~�|�n���~��zV72SN�zo�Bx�X�4D��Y��0b<t8B�`�I��,@$I�$I��ʪ0���������$q�9=9�{󠣩�[�>L�V�|p��4>Z
.��:�D�$I�$���h�n��<������9���4IO6��HV��&����Y(����Ѽg��$�I �$I�$I�D8�o��?��"LFr�}�;g�mE��	)�0,}.z�����Y\"��v4�l>Iu��$I�$IR=�a�>~��|������p繽h�05�d���*`��莏m+���4�1��Z�ORL� �$I�$I�a�H������-fWi%)�q���]�Π6��yՇ������`��P\��4�A߅�߅��')�X�H�$I�$Ũm�����yyq }[7��1�i�4=�d�wJ�a��`�`���,=�\�CrF��$�$I�$I�����M����l�SNb|�kO��w�oOB|\��T�����!Z~��Dg�D�{��_HL	6���f"I�$I�CJJ+���%L����9Lכ�-�N�ze���m���*K���]a�x�~�{ZR���WI�$I��1c�Vn�<�ť�B���;p��IN�:��-�a���`"�+��V�a����t��
$Iǎ�$I�$IR����߾���f|@��i�=�7�m����c�0m|����}-Z|�;B�@�I��,@$I�$I������I��h� �3�57�ޕɞ��Q����0�nX���y�3a�x��\6I�D�$I�$�N*�s�+���+	G '3�;����:5:�b]$+^���Gg�x�9�_ͺO�� �$I�$I�c�m���I�X���o�i�/��AVZb����U��ix�(Z��'C����@���Ɠ��f"I�$I�TGT�#�i�G���rʫ�4JK�W�zrF�AGS,�,����鿃�EgI�0�R|%d��O�>��$I�$IR�f�n�<��� �]�q��4�H	8�bV�n��8̸vm��R�a�0�rHml>I� �$I�$I�X$������?doy��udw���
����X�w;�z��E72Z�Ы����� �|�t�,@$I�$I�j���Rn|ro/���v��ߘ��e��L1i�&��{(x�wGg��a�u�k$$�O�� I�$I��Z������E� )!�O��%���U�a�WÌ����CUYt��F\�FA\|��$�˲ �$I�$I�Ev�)�g����΅����0�7s2N��S�޽M�HUt�7F\Oo�&��� �$I�$I�%�\���,`ˮ2��B\}�q\���H��:�bɺ�6�=pv�I�����rIR� �$I�$I
��J~���9��㚥3aloz�66�bG$�߆iw��w�C��,>Z�	2�$ �$I�$Iz��m���|
��#�K��㇧v&%ѽ��0,{ޝ ��Dgq	���0�Zh�1�x�t4Y�H�$I�$�����_YƟ�]M$��r���n�8�h�U����N�-K���T�w���O��I�$I��cl�b�O�Ǌͻ���-gv%#%1�d��*Ja�0�w�smt��	/�AW@z�`�I�1d"I�$I�t�TT��Û����T�#4IO淣{�9AGS]WZ��{��E�YZr%�R���'I� �$I�$I:Vn���I�X���o�lίF�$�AR��T����?�����Yy0���;��l>I
��$I�$I�QG�ˌ��󥥔U��LI���zpVB��㩮*^3�9�A���I'~���NM�,@$I�$I���u;�r������v ��Ԕ;G��yVJ��Tgm[��y��pEt֢����	qqA���Z�D�$I�$��E"&�Y�/�[��JR���]��A���C_Φ�0m,�
�pt�vD�'��W��	 �$I�$I5hˮ2n~j�}���mq��޴m� �d��־->V�|p��4>Z
.�$� �$I�$I5�Ņ���El�SNR|�O���#��O���D`����c���,�ω^�ѼG��$��� �$I�$I����U��g�����"�{���K�̀��N	W������aӂ�,>	z�î����'Iu��$I�$I�W���-���6���+N��5��DR�˨u�*�a�$x�ض2:KL��K`ȕ��2�|�TGY�H�$I�$}	{�+�ㅥ��5 �kҀ����_�F'S�Q�>�L�J�Eg)a��`�w!-;�x�T�Y�H�$I�$}As�l��I��x�^ .҆�N�BZ��Zt�������[���r�_��Ɠ�X��ʒ$I�$IG����{_[��o�"�Y)�uno�wlt4��7�{������a~-��HL	4�$�I�$I��#�����8���vpN�V�:�;Y��'S��s-̸��*K���]a����l���$~u�$I�$I��Ua~�#�}m9U�$q��=9�G󠣩�۲޽7��<\��ʏ�N���@�IR�� �$I�$I��f����]�4�Ha`�l�n�����1w�N N���g��iFr�aU�m� �M��"�Y���G�
�N��I�$I�Tｴh#�=���ťճ̔J+W��HN�ֳ�3�_+B����D"�f:L�V�qp��L1Z�.�$�S �$I�$�^{i�F�xbӯVR�eQ�t�x ���p��"X�r��X7+:�C�1���ͺO��3I�$I�ToU�#��ܒO�������)�,�ꈪJX2޽�Eg����|z54jd:I �$I�$���z�!��:��ť�Z��!�T��*�`�?���w��Β2`�%0�J��	4�$� I�$I�T���[�����i����ͻ>�$Q=P��<3�]���l�}x�6
4�$�,@$I�$IR�G��j+g���"ʫ�G���2�V��w;�z����2Z°@� �A��$I��D�$I�$Ŵu;�2�`O�Y������][d2�+~�#6��vHh����v��,�j�]��W{��wGg��a�u�k$$�O���,@$I�$IR�)���%EL�]��U[��o72Rէ��ѽe&�P��S�≹���$���[Gv#>.���a�}��PU����۷ .>�|��#f"I�$I�b���L�]��y(�WQ=ڡ1��qj��$z��-x�;���%�,Do��­#�qZ��,�T�޽M�HUt�7F\O��%�$�5 �$I�$�N+�[����3���E�K��-�R�?�1�y�e�}�s�֣'wkά��ټ��f��^y�G=�� ���^88;�h��fhp�$I_��$I�$I�s���}������he�х��!N�֜1�������q!�th|�"�6�Dࣷ��	�����P�Wï��}'I�) �$I�$��ذsO�Y��9�n?�мsNc�qv�Vd7H
0�j�p8z�Ǵ�a���,.z�]M:O�T�,@$I�$IR�VVY�kK63���i+�\h����>-��G��,B�hЧ�����x�ز4:KH����a^��$IG��$I�$I���n*a��B�~��{.4�>���y�ޣ�I����*��O���`���,9^���M��'I:�,@$I�$IR�QRZ���60����늫�9�ɜ�?�1��hۤA�	U'��@��0���gst֠)�>�R���'I:&,@$I�$IR�"��}������h#�х�	q!N�øy��؄�������۳�f�J�hYy0���HL6�$防 �$I�$I��T\ʓs
�<gk��wl�θy��ۊ&��&T�Q�f> s����KM:�����\�O4�$) �$I�$�)����EL*(���[�_h� )����dL~}���\Gf۪�b������=1-����˙�UC�T�Y�H�$I���nE�.&�.��ֳmOy�|`�l���rF��%y�BGh�xw,y"�[��v��h�$,@$I�$I�Q����/���م�+�Y=o����~���ϥ}�����Y33Z|�x������#o`p�$I���$I�$I�1�H���`��B^X��}U �ǅ8�K3���qB�.4ב�D`��0�nX;#:�A�s`�uмG��$I���$I�$I��6�����uL.X��{���6`\~g�kE��� ��	W���´	�iAt�}��� w6�$�ֳ �$I�$I_JEU�7�nf��B�Z�����Ӓ�9�W�ȣ_�F.4�SY'E��o[�%6���a�U��"�|��:�D�$I�$}!+7�frA!S�g���y�6�����Z� �S�����ܿ��d]t��}}Ҳ�'I�{�׈$I�$I�\{�*y~�F&2g͎�y��$F��eL~.�5�0��};a���?��m�Yzsz������$}9 �$I�$�"�s��`RA!�^������sS���qb�f$��\_�����c����$:k��]���#I�j,@$I�$I�!6�*���TPȪ-��kҀ1����KN�'��%�\������Y�n0|<t?�=]%I���"I�$I���
�ֲ-L,(䍥����&��͞х�ں�\_��e�������U>��:�q^I$I�Y �$I�$�cm�ͤ�uL���-�.4�אq�8�W2RL�:o�\xw|�o Z����h��vX�I��I�$I�꙽�х��1������I�ӷc��)����
"���h�ꍃ�.g�Ъp�$I���$I�$I�@$�L.(���]�Q\�֩)��qb������H����u���P<�î�f]�'I�_,@$I�$I�a[w�U/4_�yw��M�4���qN�V��J0�bBU%,�
�&����Y|2�;�� �	4�$�~� �$I�$)�TV���b+g�ڇET�_h���7{�`�<��&.����*�`�?���w��Β2`��0����h<IR�f"I�$IR�X�m�

yr�:�J.4Ř�<��ӒL��&��9���`���,�1�^���'IX�H�$I�T��+���E�8���W\h�(-�Q}[1n@]�g�P1e�v��Gx�!ط#:�lC��~@R�`�I��,@$I�$I�c"��3�����m`������ؔq�y�ԭ�	�'U�(��ڣ�/P�':�� ï�^� !)�|�$��$I�$Iu��=�<��z&�tӮ�yn�T���qn�\Z6t��j���0�w0��PU�5�	��C�oA�%�$��� �$I�$��
G��b���ʒMTTE�'%�qz����cp��.4W�*Z����@$��#���N�^n$IR-g"I�$IR-T�}/��/4�P\Z=��*�q�y�ջYi.4W+��N�e/�w2�m��K��/�D�$I��Z�����ob��Bf��V=�JM�쾭��K��Y&TL�Dࣷ`������t��Ѣw��$I�������;�0r�HZ�lI(b�ԩ�<^TT�E]D˖-IKK��NcŊ�SZZʕW^I�ƍIOOg���r�ڵk9�3HKK�Y�f���?����c�z�-���Grr2�w�=���x�%I�$�+�D",\W�O�.b�_��cƪm��7�����������n���Ç��#_�����q	��;p�l��$�N�
ը={�лwo.���9�C�D"�5���D�y�233�0a'�tK�,�A� \w�u<���L�<���,���*�9��O�@UUg�q͛7gƌlܸ�.����Dn��v V�^�g�����=�������s�e�ѢEN=��c�A�$I���ع����gb�:>�XR=o�0�s��rn�\��L��UU��1ml]�%�B��`�U��h<I�jJ(�D���
�x��5j ˗/�s��,Z���ݻ�i޼9��~;�]v���4mڔ���{� ,]���]�2s�L̋/�șg�Ɇ���ࡇ⦛nb˖-$%%q�M7���ϳhѢ�<����ٹs'/����/))!++���b233k�##I�$��
�#L_����yeq�U���I�q��=�q�֡��utT�����A���,9^���M��')�x~MA�
3eee ���T����HNN��w���.cΜ9TTTp�I'UӥKZ�n]]�̜9��={V� ��z*W\q�/�o߾̜9��8p̵�^{t�II�$I:�u;�2�`O�Y������][d2.?�Q}[�0-)���i�%P�g��س9:k��\	��B�'%%I��D�́"��o���A��s�=�[���7�i�&���hذ�!o���æM�����������cJJJطo�����WVVV]�@���$I��/����W�1���wWn���2Rէ��ѽe&��W{�(ٳ�f�J�����0��=����X��Xb�c&11���z�K/����l���9餓8��өwb��;��ۂ�!I�$��[���I��:o��*��C;4f܀<N�ޜ��� *�����Ǡr�GM:�����\�O4�$IǊ������3o�<���)//�iӦ4���| �7oNyy9;w�<�*���"�7o^}̬Y�yޢ�����~`���dff����o�����W����������K�$I���V����L,(d���W���JaL�\����\G�֕0�^��/�/�Z���C�3 ..�x�$k 
DVV +V�����_��@� ILL���_g��� ,[���k�2d� �¯�k6o�L�f� x��W��̤[�n�Ǽ����櫯�Z�����Lrrr;��$I�bV8὏�1����m��2��<1>�)ݚ3&?���Bsm��`�T`�ڎ�����۬I��)ըݻw�r���?�^��y�摝�M�֭�<y2M�6�u��,\��k���Q�Fq�)� �b��K/e���dgg�����W_͐!C<x0 ��r
ݺu������;�dӦM�r�-\y������=x�n��F.���x�&M����?�?(�$I�bʆ��xr�:&�)�p����s2; ����"���u��	���u:=Z|�.�$I���jTAA_��׫�|��R^x!�=�7nd���ѢE.��~�ӟ���sqqq�=���2N=�T���?T?Ͽ��o���
�B������/~Q}L�v�x��������~Gnn.�ӟ8��S��G@�$IR,*���%��XPȴ[.4ON`d����ϣWn��u�E"���h�vFt���a�u��=�|�$�"�Hm�>-�B%%%deeQ\\Lfff�q$I�$`�&�.d��ٱ��B�������=Z���Bs�*��Y�66-��ⓠ����k �}��$�0<���y�$I�$I�����g�m`rA!��W�s2�9�.c��ѶI� �^�,���ͷ��tbȿ�\�-�'IRmf"I�$I��"��}������h#�х�	q!N�øy��؄�������(�s�
3��YJC|���h<I�����ӤI�8� n��F���?ҭ[7���ҦM��J�$I�ѱ���)s�1���5��V�;6Kg܀<F�mE��� ��ٷf?�={�Eg��a�U��"H�2�$Iu�;@D�Νy��9���9s&'�t��s����IHH੧�
:b �G�$I���+ü�����y{����+n��Y}Z2&?��y]h�ck�f��{��g(��5jî���AbJ��$�K����� �����;��S�2z�h����6�N8!�p�$I�TCV�b��B��`=���W���fL~.g�jAZ��&�۱f��*K��f�`�x�~6��9)Iҗ�ߢ"==�m۶Ѻuk^y�Ə@JJ
���8�$I�$}y�J+����L�]ȼ��Ɍ����\�7M.��-���{`�$�TEg�`����T�sߌ$I_��8�䓹���۷/˗/���& �/�m۶���$I��/(�0��L�]�7��"zr9>.ĉ]�1.?�:7u����~L� K�����ף�G����$I�1 ����=��r���L�2�ƍ0g��;＀�I�$Iґ�\Rʓs�1�`���oڀq�y�ݯ�2ܣ� D"��0�n��̓�#���j�/�l�$�0���S�޽�M�6U��o\�$I�$�~Ua�X��I�yk���o4OK���^-7 �~���\��a����c���,��F��7�h<I:�<���y�x�w;_�h��z+[�l9Ɖ$I�$鳭ܼ���L�����˪���4b\~g�jA�d��U@�*a����Gg����z54jl>I��	�5(N8���C�#G�<�a$I�$�S�)����XPȜ5;��Mғ�/�1���,#����*�`�?`������,)\
��9A��$�ޱ ;v�8��UUU�Z��n���Ç�J�$I���箍.4�����-?���띛2&?��4#х�
R�n���� ����5��W���!�a��$I����O5o�<N<�D�o�t�@x�BI�$)8[v����uL*(dՖ���5i���\F��%'Ӆ�
������0�aط��3[��@��!�A��$)`�_SмD�*..�����cH�$I�'*�¼�l
yc���橉�|�gt����.4W-P�f> ���]�㢋�{�����$�6� ,�Ĭ���_��\r�%�<ޫW�cM�$IR=�і�L*Xǔ��ز��B�>y7 �3{� #%1���7�U�f�.��h3��>��#���螏���yOq=t=��c%IR�����#
�i�
�BTUU�t��=I�$���[]h>�`�>>x���I�ӷc��)ǅ�:��</�%�2[�i�����{`������->��xU�$���4� �W�:�$I��z ��A�N&�����.� ._�Ԕq�8�KI	.4�1��Y�t�_?X�&��츓a����!�$�V� mڴ	:�$I���uwS?X��م�ؼ�zަqc��8�_+Zd��P�Z�*z�����ۨh�Ѣ��H%I�j��$I�$��UV���b+g�ڇET�_h���7{�`�<��&.�[)`kfz۫O3�2�I��I�$IR�Y�m�

yr�:�J.4Ř�<��ӒL��6ٱ�Ȏ�]ttsH��g"I�$I�J��W�⢍L�]���.4o��Ȩ��7 �.�]|�Zf�&x���#��st�H��g"I�$I��"��3�����m`������ؔq�y�ԭ�	�'����0�~X8	�ʣ�P<D�>�B��ҥ�$�A  �r�J6o�L8>��?>�T�$I�j��{�y���L.(d�]���F���������l�Bs�2�|<-Z|�x���z5TU���o�G�i��8�<I����{��?��?�Y��H$r�c�P���O�)I�$I�AU8´[�\��W�l��*�}CRB��hθ�<�o�Bs�>U��dj���8o�0]G��@ހ�ǆ�
/�t�B�̖���Y�0�$I�) �{�����<���hтP�oZ$I�$A���L޿�|Cqi��G�L���qV�Vd���\�P�.��7x�A(^�%�B����+�q�O�M�����fFt�yzN��W^�!IR�e"V�X��O>�q�tI�$I+����ś�8����UϳR9�o+���ҽeV�	��P�f=�Biqt��}�/��?����݈��S�$ bРA�\��D�$I���/f��B�����҃͇ׄ1�y��-��D^�T��� ,���qGz��$�>� W_}5�_=�6m�gϞ$&z	{�^�J&I�$�hڹ����gR�:�l,���j�ʹ�s9�.y�i&�>C$�߉��X���y����N�����I����"���Z�N�a�A
��D"�z	zII	YYY���tI�$�F�������م�����0 I�q��=�q�֡��U{UU��0�>ش :�\l��h<I�A�_SмD�^�:��$I���u;�2�`O�Y������][d2.?�Q}[�0-)����(�s���yat��vp�yv�`�I��Z�D�i�&��$I���Ҋ*^YR��B�]����g�$0�O+�ȣ{�LB!��P-V��
�����4��߅�BZv��$IR�eRO=�쳜~��$&&���~�g�u�1J%I�$�&,�P��u<��z��UTχvh̸y�ڽ��U�-������������S��'I�j=w��Sqqqlڴ�f͚v�� ���$I���V����L,(d����[d�0�.c��\h��/��o���`���m�E������\��ϯ)h^RO������$I���#���GۘXP�K�6QV��}b|�S�5gL~.#:6%ޅ��*`����/��Bq��[0�j��l>I�T'Y�H�$IR�a�>�����s
)�~p�y����쾭�n�Bs��%�����Ӡ�����6�$I��,@$I�$�(���%��XPȴ[.4ON`d����ϣWn��U7�l��s����lk�}�/q��$I� �$I�T�-�T��مL�`=;�\h>�}6c��8�GR�\h�:b�"�y`�yet֤St�Gϱ.6�$I5�D�$I�j���
�������_W\=��L������G�&L(}�|�&̸V�qp�f8�w���%I�Qa"I�$I�@$὏�3���m��"��<!.�I]s7 ����b�U��h�Q����G�Ы����%I��eRO���񱙙�G1�$I�T�m*.e��uL*(dͶ�����7 �Q}[�$=9���TZs߿�|}t�� �] ����O�$� �TÆ�x9bUU�QN#I�$�/�a�XZ��م��|���$�sV����ϣoޑ��]��������.6Oω.6����%I�1gRO������������.��!C� 0s�L�q�㎠"J�$I1gE�.&�.��ֳmOy�|`�l���rF��%�m��M���Z4�?�w�.6�5��I�$#�D"A�P���op�e�q�y�2��?����G�z�`�������,�����$I���]��{�F&�.d^���yӌdF��el~.훦P�2"��B��G��v�w���%I�_S�,@DZZ��ϧcǎ�̗/_N�>}ػw識el��$I���H$��w0qv!/,�Ⱦ��me��B�إ���8�sS���,���/��B��}T􊏖}�'I�]<���ym�����G��;�<d��?������RI�$Iu��R������X�uO��}������~�h��`B�K*-�9��{���Yb�!�4jh<I��ñ ��s�G���_dРA ̚5�+V0eʔ��I�$I�[EU�7�nfRA!o.�B����iI�٫��ѯu#��n*^�=]l^�+:Ko]l�1�6
6�$I�g�X����|��K�еkW������+@�DO�$I�e���L.(d���l�]V=�ߦ���8�W$�3g��6·Dowu`�yӮ��\�<��撤#��5�D�~��$I��SV��62���9kvTϛ�'1�_.c�s9�YF�	�� �U����`����?���+�$I_���4I L�6��~��>��ɓ'ӪU+����Ѯ];�t<I�$)0�H��k����`#{�.4�z禌����.�Ht����rX�d�͋��P<�8�\-�O�$�˲ S�L��������;w.ee����������y�N(I�${[v����uL*(dՖ���5i���\F��%'Ӆ����.6�!ص1:KJ�~���A��A��$I��,@į~�+z�!.�����UχƯ~�� �I�$I�VeU���maRA!o,�L���橉�|�gt����.4W�s-���}�wGg�ͣ�G��!�a��$I�j��X�l��'�YYY�ܹ���$I������fR�:��]ǖ]���kȸy�٫)�&�j���0�~X�D��r�Y��b��BBR��$I�j��h޼9+W��m۶���}�]ڷoL(I�$�(�[]h>�`�>�^=�n��9}[1v@�r\h�:.���Ì���w��}�� :|���$)fY���/��k���G}�P(Ć�9s&7�p?��O��'I�$՘H$��;�\P�s�7�����|�SS����.9$%��\u\e,|f> ��Dg�x�1�^-z�O�$�� ?�я��|��`�޽��$''s�7p��WO�$I�ʶ�.���3qv!+6ﮞ�i����<��׊Y�&�jȾ�P�(��0���%�C��`���a^��$I���P$�B�Cyy9+W�d���t�֍����#������,������:�$I���ʪ0�Vle��B^���z�yJb��т���6��8o���s-�� ������-����]�bsIR <���y��%%%ѭ[��cH�$I_ɚm{�TPȓs�QTrp�y��,���qV��d��\�bü�b��O��b�����v��$I��,@Dii)��?o��&�7o&��ܹsJ&I����*a���l�UJ����&�0Wl�+���E�8���W\h�(-�Q}[1n@]��S����xf�O;8o�t8���$IX����Ky�W8��s8p !��,I��Z�E��%l,.����J�֑�8�G"��3�����m`������ؔq�y�ԭ�	�A�Rͪ,����W|lY��%D��r��l>I��Z� "++�^x�aÆ�V���$I�yi�F�xb.���ʁ�9�.��tӮ��r�26?�s��Ҳ��C������E�YR�_]l��h<I�>���4� �Z�"###��$I���m�-�D�T�&�Y@RB��hθ�<�o�BsŖk.6���e���W@�!%+�|�$I�����馛x衇hӦM�q$I�T��Z����^}�K���ot"+ͅ�1��Fos�d*D��h��]l��l�K�$!���Oii)�۷'--���C��ܾ}����$I�T�6�����w^C�ŎpV�->�s�y���G����\�$�� �w�ׯ���o'''�%�$I
TFʑ��2R�r��,�a��uYt� =΅�WA���$I��,@Č3�9s&�{�:�$I��H$�ˋ�����>��<+���M0�hػ��b�=����L������'I�,@D�.]طo_�1$I�T��߹�[�Y�kFO7IOb��rBp�2��*�:��.<W]�������vp�yfnt�y� %3�x�$I��D��7�����׿�5={�����L�.I�����*�_��=�-goy��!�{|�:�8�Z��۞[r�B��Y)�:���h`j�KX?g�b�g]l>�����$I�i�H$������� >��#�
����
"V�JJJ��ʢ���H�$�(�`�~��">�X�������t�ɨ>�*a���l�UJ���m���CuF8+^����������	.6�$�4ϯ)h^"�|�͠#H�$�))�஗����k�D�aZ"?>�+���%�ʍ��C:4(��%U�F��| �.�����r%4�l>I��z�D|�k_:�$I��H$¿l��^]e ��ˏ�م�����j���P�gx���.6Ͽ8��<�e��$I����;�|����1J"I��X�v�^~��"�^���M�{0�C���I5`�jx���P�7:�̅!߇���\�$)  �N���?���� �$I���+�<2�#�{}e�a�������ړ�t<�Y7'����g.6o��^�G��\���ٻ��*��㯓�J�3�!����u� Ȱj�j������lݶ�ڻ�Q�m��ֶ@p�8p����
$lV�8��ǅ�T��!W���x����+'�I�y��~$��D�ڵ밷����;w.��~;��{oH�$I�T�}�n'��[�ʭ{ܹ	��ʤS��!'���hVL�iÆi��.���AǓ\l.I�TEX�������N?�t�������={v�$I�T]��_���.��o�I�$n;����9�Nc�Z).���i�����,.z������$I�gX���hт�˗�C�$I�D,c��M���Rv�+���r���4��r:�kڿ>�3�z�;lHN��.��?��V��$I�� ,8��X,Fnn.<� }��	'�$I���5��rۄEL[��n-�s��,���8�d�״sL?�ؼ�@0Kk��� �A��$I���,@D�>}�D"�b�����'�)�$I����%�<6u5xg5E�QR��ѩ]��N$%ąO��6~th��$���H�z�=2FA�?FK�$U��M�]�������h֬)))!%�$IRu0m�vn��5��pr�f���L�5�r2�+�Fa�k��O/�w=_Nt��$IR5d"ڷo����ݻ-@$I���v�=Ƚ�,e��M 4k�̝#2���%�^�����G`Ǫ`��΃��A���$I�7b"~��_ҡC�;�< �=�\^x�Z�jū��J�޽CN(I��� �������2���E��C�!5%1�xґ۷�|�����,%����7�$I�*��x�����?���)S�2e
�'O��㦛n�7�9�$I�¶b�n������G�T��E���&};VÌ?��|j�y;t�����%I�j���G۶mx��9��s9�3�С9�$I��TX\��o��ﮡ$�nR<7�ލ��@B�K�UMl�uh��˔/6���z��bsI���?�F��q�Fڶm��ɓ��{ ��b�����N�$Iayw�6n���;�pzF�ٓ6넜L:�RX~h�����C-6?���$I5��3f\p]�veǎ�y� ̝;�.]���N�$I�mkA!?y	//��UZ
w��ɐ��EP5P| �=�����Y|�:]ͻ��O�$I��D�����C�lܸ�|��������5�\r:I�$U�h4�?fm�����SXB\.=�#7�ލ����*n��O-6��R�q�C�+]l.I�TEb�X,�RUTPP@ZZ�������G�$�Z���[�/d��� �JO��Yd�I7��ev���w}����`�u��BH�n>I�j1__S��5.�r�J�y��n�J4=�;�#�T�$I:��,�wo����Q�Q?9������'>����6��/{�������A��.6�$I���O�W_}5M�6�e˖D>�0�X�H�$�Po.��i� �g���HM	9������U��!șU>�vf�ؼ�`�K�$�����{���{���Î"I��J����&.���[ HoT�_���)ݛ��L�E�a�'�����$�}~p�U�c��'I��*�D�ڵ��|�;aǐ$I�QVR��������WTJB\�+N����ڕ:I�aǓ>k�v��'��O�����C��[�O�$IU����w��o��UW]vI�$%rvs���,�T @v���7&��-]F�*h��`���~j�y��n��BR�p�I�$�Z� ]�t���ogƌdee���x��?�яBJ&I��ojOa1�~c�L_G4�)	����\[�\r��$��3a�Ç/6o���b��J�$I:r�X,;��ձc�/|,��f͚JLSu���F~~>���f�$I�^b���qפ�l)8��}Zs���5H9��)�RX�rP|�|T>?fX�ؼ� �K�TM����� b�ڵaG�$IRڸs?wN\��˶СI]~1*��69��)E�a�?����L��������'I��j�D��䆠��a%I�T��Fy���͕(.%1>��'w�S�����A�"�n�YO�G�;�Y�Fp����~�p�I�$�ư  �<���կX�r% ݺu㦛n⢋.
9�$I�������u�B���`@���;:�.���L:d��`���Bip,�:w{�����$I�p �7����~;�]w�< |�W]u۷o�n9�$I��H��b~��2�9k�4���-�zpN�t��U�b1�0=�����y�c��A��\l.I����%�cǎ�}��\|�Ň͟~�i��Z�#�%M�$�*��bL���_����{� �N�t~6���%��N�^��N
��MF>��|���%I�|}Ma��������?3<x0���!$�$I��n�>ni��@�f��wt;5	9�j��}0�0�Qص.��'C��G]5�j<I�$�. �K�.<��s�r�-�����ӵ�?�H�$UE%Q�xo5�����(I	q\J�<��	#������滂Y���R��~ ����O�$I������9��x���v�|�ᇼ��[<��s!��$I��5;�u�"Vm��	]�rϨL:4uq�B�mE��|��>�ؼ#�z_ Iu��'I��Z�D�;��3g�����	& УGf͚E߾}�'I�T���W�}�.���9 4����ge0�wk��+�����X�Z�<�8�#�>���$I�\�.}�4I��0�b1^����^]��}������!�I��r:�J�%�l|�l�sh	
�O�K�$}���)l�"^}�U���2d�a��_�h4ʙg�R2I���i�ֽ�6a!3�����oL&��79�j��}0��0�Qؽ>�%�@�`�дK��$I��/`"~�ӟ��|f����Oj"I�TI
�K��;�x��5�FII��ǧu��:�v<�6{��/6/���6	�����kj<I�$��X���+W����y���Y�jU�$I�j�Vn�	Y�c? �ӌ���I��.�V%۶<����P�F�N0�:��]�K�$�ڰ iii�Y��:6_�j���'�$IR-�}�A�yy	�m�Ej2w��ə�-]r�����-6�\>o; ��q�0�K�$�ڱ g�}6?��?~<�;w���'?�	#G�9�$IR�����Gy൥���%�:�3�� �%�$�%�tbP||z�y��`���n@��$I��o�D<���:��ݻ���@NN'�x"���r:I���gy�n����wгu*��΢wۆ�S�qpo��|ƣ�{C0KH�> k�I�p�I�$I�D���1m�4�L�����S��z�⤓N
;�$IR�r���߿��?����h�zI��x�1\2�=	.9Weؓ3��
�Y�&��J8�
�K�$�F��b�X�!��������4���IMM;�$I���Y���',"g� ��h�]#{Һa����Vغ�?���b��0��b�D�;�$I���6� �$I���-��|�^Y�@��>;��3Z��L5^,�>�i��7��m��?�ngB�wI�$�� �$I����h��\ϯ&/g����"\v|~|Z7�%��pE�%�dB��<wޡaz����C��!��$I�*�?yI�$IlѦ|n���9����mr��Lz�N9�j��{����� ��,6�}��v��$I�jI�$���;X�o����%��	����p�����E��� f�>~�S�͛±�C�&��$I�Bb" V�^�_��WV�^���{�7o�k��F�v��ٳg��$I���7�q�����pV�V�qV�SSBN�k�R��,�7D��Y�.0�:�}���%I�T�Y��w�}�3�<��?���{�{ｗ�͛3�|����/�Q�$��ڼ� wN\̔%[ h۸�8;�o�<�d��b1X�^��cՔ�y���~�nC]l.I�$b"~�ӟr�=�p�7ҠA������my��I�$U]%�Q�����LY���R�"\yR'��vW�$ŇO5Mi1,y	�=��Y$��b�A����$I�� �p�B�}���̛7o����CH$I�T��۸�[�-dIn Ƕo�}c��֢������s���A��`�P�/
�7�n>I�$�
� 6$77��;6�;w.mڴ	)�$IR�SPX�������XO,iu�ٙ�9�ضĹ�\� f>�Zl^���!w9�mn>I�$�� �>7�|3�?�<�H�h4ʇ~�����r���O�$)t�X�W�q���l�s�1}�p��4��r:�([���G`�s�Zl�5����<HL	7�$I�T�X���k����m�RZZJFF���\p��v�maǓ$I
�Ɲ����EL]���M�q�Lwir2���}��b�7������C\l.I�$}�X,;���6�h�"���K߾}�ڵkؑBUPP@ZZ�������G�$U���(z�����(I�q\���\��Τ$��\��O��-f�8�1��b�~�Ɠ$I��|}Ma��i׮�ڵ;�$IR�>^��[�/dŖ� �Ԅ{FgҹY����F(,(_l^���B�O�w���/I�$�x���b<���\s�5�s�9�3氿����{�#Fкuk"�&L8��{�r�uב��N�:u������?���B���Z�4iB���;v,[�l9�60|�p�֭K��͹馛())9용S����Mrr2]�tᩧ��J��$I�}v�/�g�p���Y�e/��%���������7W����̈́7nʏz��۷��a؃��$IR�����?��r�)�hтH$�k߾}��ݛ�.��s˓o����~�����t�Ё7�x�k���֭[3r�H n��^y���y��Ҹ��3f~�! ���>��-[2m�4rss���ILL���`�ڵ>����������[\q��jՊ!C�|��O�$�L�X�	�6q��Kٱ���m�O��N�zI!�S���(Xl��y�����݂�Y��\�$I:J�"7n����w�V���D?~<�F�*�effr�y�q������Ǚg��=��C~~>͚5��g��s�`ٲe��у�ӧ3p�@^{�5�:�,6o�L�- x��ǹ��ٶmIII�|�ͼ��+,Z�������޽�ɓ'Q~�(�$�vX�}�MXȇ�v Хy}��E���CN�j-�5S����*��?��t9���$����5��?q���4:u�T)k���L�8�M�6��x�wX�bg�q �gϦ����N;��}�w�N�v�>}: ӧO'++��� 2d,^���O?�'�|��$IKJ���+���p���i�1���-?�������'��F�G$z�����݆X~H�$I��#��]w���w�͓O>I�:u���z�ᇹ��+IOO'!!���8���?q�I'���GRR6<��Z�hA^^^�5�.?>y�����58p�s?σr�����

��'+I����wp넅�ٶ��6�Q��oR/�d��
`�Ӈ�o
f�� ��b�FB�'I�$�F ��s����'͛7�C�$&&���9s*�c=���̘1��'Ҿ}{�{�=���ZZ�n��;6*������w�jI�tt��WĽ�,��99 4���#2ѫ�7ڃ�Z,�|f?�M�0����R���D�$IRX,@�%�\��ٳ���������7��[na���>�^�z1o�<������N;��-[RTT��ݻ�d˖-�l���-[2k֬Þ{˖-e�}��Of��&55��r���~ƍ7�X�vAAm۶�f��$I�b�����W��{1�\8�7�NZ��/�?�-�i���>����`�y�s!!9�|�$I�,@���
���:'�p�Q�8���������F�`!zbb"o��cǎ`���lذ�A�0h� ��^�n�J����2e
���ddd�]�ꫯ�q�L�R��'99��dP�$��Y�u��_Ĭ�;�޲���"�]����ډ�`���b�5��;��]Ns��$I�T�X���mے��Z!ϵw�^V�ZU��ڵk�7o�7�]�v�|���t�MԩS���������3�����_~���x�4nܘ��T���z���8�3���ࢋ.��$//��n��k������ꪫx�G����q�e����o��s���+�T��)I�����Ry{|o5ť1�$�s��]����$��"����"X<.(>�,
f�x�9
]m�C�'I�$��Eb�X,�
�+����?��?N���sM�:�SN9�3�K.����z���<~�����o�s�NڷoϕW^�7�Pv�Vaa!?��O��?����2d��ʎ�X�~=W_}5S�N�^�z\r�%<��$$$��n`ɒ%���s�������?��������ϯ��H�$U��Vl����~�~ N�ќ�F�$�Qݐ��Z)�v{�x�lf����%0�*h�>�|�$IU���)l �Q�F�߿����֭��%�;w�)Y��-IR��uO!�������[��p�Ȟ�y������	J��OCў`V�e����K��ǧI�$	__S�<K��w�;�$I�7��xv�~9y{
K���%�;�3��~����]s�x\�b�f=���Y��\�$I�f�iP\r�%aG�$I�ږ�p����ٰ��6i�7:����p��z��`�[��O-�w<�|��wI�$IՒH-UPPPv�YAA�����$IRU����߿��?���h���	��n\<��q�`�/QR�^�����Y$z����A���$I��Y��R�5"77��͛Ӱa��=;��D(--!�$I�{k��xi1�v ��̖�9�'-�RBN�*��n���|������}	�
�3�$I��
dRK����4n��w�y'�4�$IG&/���'-�Ey �iX���ݓS{�9�������?��
�]
u�O�$IRų ��N>���ݱcGڶm���@b�7n��h�$I�Q����u����=XB|\�+N����֕�I��V�E�����E� v�����b��s !)�|�$I��Z;v,;��v��Iǎ=K�$�jaN>��_��M� �mא�Fgѣ�{��b1X�L{־[>�x��槺�\�$I�,@T���?�ݻ���і$I��{��_������#�)	�<�;�oG�K��yJ�`���/	f�x�,6o�;�|�$I�*�H-v�7�D���۩[�n�c���̜9�>}���N�$�V�X���q��%�0�wkn;�����N��O��[�~h?�����n��W�������>�
���Ԓ$I�� �Zl�ܹ@�"�IJ*?�8))�޽{����aœ$I�Pή��5q1o.�
@��u�gT&'ukr2�b�D�|3l.����������{�x�<E{�����WC�%.6�$I�j�H,��B���K���Oj��hZAAiii�����F�����4�_?\�o���@q)��~xRg��vR��	T�,��]��+�`�v����b���u��$IR��k
����-IR嘳a��[Ȳ�= ��И{GgҵE���)4�R�]��w~|�N�
�w����%I��__S�<K�$I��?P̯^_�?fn ��u�����/�%���iGV~�x�]r��H�$I��,@$I�T�b�//���//a۞� ��N�a�iR?9�t��n9�����$I��5I�$U�;�s�K�xo�6 :5�ǽ��ԹI��Te�\��ٵ�[�,�$I��5I�$uE%Q���zk%K�$%�q�pշ:����s?�i���!���#�����h�$I��'I�$U������Y�u/ �wi�=������j�h),�=g�ϻ�m����<4�}��� �Y�I�$I�b �$I:*v�+�ז��7Ф^�����}Z���V+���3�y��΅A�A���EO�|���S[�G����-I�$�Z� �$IR���b����{_]��}E |�[nڝ�u�BN�P��
�����v���p���Jh�;=2FB��~Z��~���+���$I�t,@$I�TaVo���1m� ����}��8�C㐓)T[���G`�sPz0�5�����H�/ǡ��C�+%�$I����D�$I�Xaq)�M]�cSWST%%1��ڕ+N�DRB\���Xֽ��X�F�<�?�>���;9$I�$E �$I�F����m�f�> N�֌{FeҶqݐ�)�ŰxL{�F��Y0�zh7 �t�$I�jI�$}-����W�2~�& �5H���j��ڨ� �<3���`�P�~^M:��O�$IR�c"I���$�������e�(&�����CjJb��T��s`�c0�8X��5�W±�C]��H�$I
��$I��؊-{�u�B>Z���V��7&�>m�L�o�`����-	fͺàk!�\HL	5�$I�$Y�H�$�K(*��W��{k(�ƨ�ύ�w���;���Z#�Uo��a�{��'��A�S!��$I�$U �$I���.���/-b�� ��т�F��M�:!'S�).�����Ga۲`��̱0�:h�;�|�$I��9,@$I��������\ Z��p�Ȟ��2�d�4�w�G�YO����,��}p���O�$I��I�$�4�ٙ�yp�r�,!.�ߑN�F�d��X+�X3� s�%��?�����!�bHI7�$I�$��$IR�ś�e�"�o�@��4��Ef��p��rl�	��e� �`֪7�z����0�I�$I�Wb"I�$�,�wo����Q�Q?9������'>.v<M�RX�2L{rf�ϻ	�{t8"�7 I�$��� �$I��,�/-bs~! óZqǈZ����LGUѾ����®u�,>	z�����C�'I�$Iߔ�$IR-�y��7�l �Q~qv&�tor2U{���
w�:��+�@��Ɠ$I���b"I�T˔�Fyz�z~��r����;�?�v�NR|��t�l]
���AiQ0k�	^}.��z��$I��
f"I�T�,�����-d�� ��oĽ�3��25�d:*b1X�n��cՔ�yہ�~�c�A���$I����D�$��SX̯�X�3���AjJ?փ�mK�K�k��bX<�=y�Y$z��A�C����'I�$I��D�$���b��(��'-fK�A F�iͭ�3h� 9�t�p��0�i��8l
f�u��E0�jh�1�|�$I�T�,@$I�j��;�s�K�xg�6 :4��=��8�kӐ����������=��~�%{�mn>I�$I
��$IRS\�/��wo���8Jb|��O��5�t!%�}5���~���!V̚��{d}��G�$IR�e"I�T��^��[�/dY^p�����wt]��9�*L4
+߀������O��?�.�BĽ.�$I�d"I�T��/����� 4���-�zpN�t"�^3����,.2� �U�p�I�$IRc"I�T��b1&���/^^���E |�_:?փ���BN�
�o|��������
�����6�Ɠ$I����D�$��Z�}�����Wn�s�z�7:�����Lb�j��(�{J���0�j�{����O�$I��8I��j�`I)O�����YEQI���8�?�W�܉���Wk�l�	��e� �`ު�2FA���$I��#�OO�$I�Ȍ5;�u�BVo���]��3�д^���DKa餠���q���Р�h���%I�$�+� �$I�v�+��W���� ��O���2ٻ�KΫ��{a�?���v�f�����`�y�n��$I��j�D�$�
��b�0;��^]ʮ�� \0�7�NZ�Đ��kۓ3�,7/�fuC��q?�����'I�$I5��$IR�j�^n���kwнe��E���BN��m���,x�A�E��0�Z��]H�n>I�$I�A,@$I�����R���*{w5ť1R��n\vBG����*�5S����*�����v&���U�$I�*��$IR�����6a!�v���ݛs�Ȟ�m��NI,[�H��ǆ�O�$I�j8I��*`۞����^������5�'C3[�伺9�f?3�=��,�d_��FB'I�$I���$IR�����h#�����"�dP~rF7���Zٵ>(=�<E{�Y��0��p�P��-�$I�T�,@$I�B�,��[�/b��] d�I��Y�Jon0}5���\-y	b���yFp�U�XHH7�$I�$�R �$I��@Q)�k%~%�������p��$��z�Fa��A����y�S`�u��T��2I�$I
��$IR%zg�Vni9� 0�g�ٓViuBN�#R| ���?
;V��D�:]-���'I�$I*c"I�T	�r��ż�0�6�p�Ȟ���"�d:"���G�Y��ۃYrZ��c�!�u��$I�$I�a"I�t�Fc�}�z~��r�,!>.�e�w�ǧu�^�������O()fi�`�5��{�� �|�$I��/�Oݒ$IGɢM��:~!�s��Ӷ!���"�uj���_�b�az��c�k@,�����	��1Z�$I��:r�$I�`{��7V�Դ�Dc� 9��7�.О�8cWY�%�tbP|l�S>?f��v��$I�$U# �$I���y�5q1���qIg�j�ge�<5%�d�B��ܿÌ?���,!z7Xl޴k��$I�$I_��$IRش� w���7�n�m�:���L�uL��l��������2�6��W�qW@����$I�$}# �$I�@Ii�����7SV������W�ԉ�ݕ:I�a����[���/@�8�5�������X'�|�$I��
a"I��5�۸�[�-dIn �uhĽ���֢A�����~;����y���݆B\\x�$I�$I�D�$�+*(,��^_��f�'��:��2�;��ז8��W-%E����l]�"q�1
_m��O�$I�t�X�H�$�X,�+s���%l�s�1}�p��4��r:��.���0�	ؓ��A�K`�UШ}��$I�$IG��$I�ظs?�MXĻ+�Щi=����..ʮRv������A�`֠UPz��>�ib8I�$IRe� �$I�/�K����5<��J
��$��q�)����Τ$���ș���!f-2���c!!)�|�$I��Jg"I��>^��[�/dŖ� �Ԅ{FgҹY���	�hV����0�|���`�G�S �NI�$I��,@$I�����E<��2���F �K��=ݷ_P_���,���X��!�;0�Zh�n>I�$IR�`"I�tH,c¼M���Rv�+�c���3�Ө�G(�n�6����џ`��`���^�����'I�$I�R,@$I��5��r�K��pU��z����wt�;69�ؾ�?��	��Y�v0�Z��=H�H2I�$I�gY�H�6J�1f����=�4o�B������(I����R���G����$JrB?:�+?8�I	qaǫ�b1X�a��c�k��6�`���}��GYI�$I��FI���E��=i	���e�Vi)�9"���y"�뙾z�NXȚm� 8�[3~qvO�7�r�Z���L���<��0���v]l.I�$I:" ���ɋr���s���</����>�Ǿ�m	"�+ٱ� ����qs6ЬA2w���Y�Z��<,���g`�㐿!�%�@�����v	7�$I�$�ڱ �T��Fc�=i�g����3Zz��/��x���{m)������qӐ��I;^픿	f>�������nS�%w9�kn>I�$IR�e"�J��v�a�^����_Ȭ�;ԹI��T�ܲ�[�/bֺ� toـ��dѷ]����Ry���^�hI0k�]�΃�:��$I�$U{ ����{����:�I�}
�Ky��<���Kc�I��ӻr��I�w�y���`�[0�aX3�|���`�G�3 �'�$I���a"�Jk� �B��T���b�MXĆ��8�Gs�ٓ�FuCNV˔��/�ͷ.	f�x�9
]m�C�'I�$I��,@$Ui�;6�UZ��Z��пc��&�Jۺ��_���I�7�25��F�dH�.9�L�w����?��-�,�>d_������'I�$I��,@$Ui�q.܁�^[���ǀ;Gd� ] �h�ggm���������\2�?9��'�ǞJ�s-�x�����oh�:(=�/�:C�'I�$I�|%@R�V����\ R�(,��xv���lF4IU���n���v��&���d��&-�`��Ə��K'A����Y�~���!!)�|�$I��Z�DR�������ɧAJo�p��g�B�r����ٰ���m���[�URH����7W���R�Q?9��=����a�!Z
�_�i�����.��GǓ�c�$I�$I!� �Tem�Sȃ�/�!��*����=�v�>���n����76�n��Ҥ�步[���l�} �33[r爞�LK	9Y-P��?���k�Y|d������$I�$�z�Z(�ʺ�),�Wzh����紮�� �M��7Wr˰!�����B�ɋ� hӰ��ӻ�*�ޭ0�O�џ���`�����_	Z�O�$I��OX�H��>\��	�6�{Ge}�16u��gT&�>��`-g�iM�֞�/�d���L_ǯ�X�ރ%��E��Ď�ϩ]��h۶�?����Y��0�:�{!$�7�$I�$I��W
$U9KJ�}�" .؞��/.5N�ޜ�Y�xea.��_ĸ�{�TC-����Y�)���r��,z�J9Y���`�ð���y�q�~��gA\|x�$I�$I�/,@$U9O���5��ѬA2?r̗^ǈ�[���w��xP��RR��SX̯�X�3���A��~zfw�{\;�,<���bX�L{r�F��p�#h7 �x�$I�$	IU���x��U �~V�)�_�>-RS�gv��	�xp�r��h�d���b��8��&.!�����[s�Y=h���񣢰 �<3���`�P'8�j�5Фs��$I�$I�
,@$U�X�;^ZLQI��4eD�VG���oǋ�s��q7wOZ�c��w�J:�rv��Η�ֲ� �oR�_���Iݚ�����ρ�����`A0�������5	7�$I�$I_���*�Ey��bI�q���D"G~�M\\���dq���ڢ<�\���2ZŴ�����(O~��߽��ť$�G����\{JR�5Q�r�ôG`�8�������� �\H�NI�$IR�e"�J�SX�ݓp��:өY���=Z�rŉ��k�s�bunB�d��I�Ŝ��e�B�������7:�.�������`՛�~����;�,6�r:�Ņ�O�$I��
�+�����NYɖ��thR�����Ϙ��S��ʂ\rv�wo�����R�ѐ��'/��Y�Ša�Dnփ��K�Jw��K�����G`۲`���10�:h�'�x�$I�$U4I�[�)������gg~�cn�&%��Q�\�׏x��u�ݧ�m�**��
�Ř� ��OZ������-úӤ~r��j��;����'`_�S����p4ln>I�$I��I��Fc�6a��իU�,8>���ՊW�r������x���-r�*Y�c�MX��+�ЩY=��Š�.ۮ0;���?��@��`��^�C��$I�$�f� ��~��ywS?9��Ϫ���<+��VlcAN>����߱[��WT��V��۫8X%)!��N��O�Dr�K�+��Y�~��/�`ֲ���a��$I�$��X�H
Ͷ=��k�9�?9�-RS*칛��p����6a���
�d��UZ�
{~I_ݬ�;�e�BVm���]�pϨ,:6�r� Z
�^�iCά�y�3��O��H�$I�jI���ե���&�����翠;^������{���_�I_n׾"�m)�}�@��I�6<����v��7U��=��]�.%ⓠ�yA�Ѽ{��$I�$I
���PL[��qs7�����H�������1Y���L^�ǔ%[8=�E�I�/�1n�&�}u);������������od���D�����`V�{9����N�$I�$I���$��p�v�n��}��-S���N<��j�|i�;7�^�����m����6~��� ���wt&�vhr�jn�R��,xJ�R�Faе��H�81I�$I�>ᫀ�*ݟ�_��m�hZ?�����Y��Ԯ��p3w�7SVT�u��*�Ƙ�v'[�ҼA
�;6&>.Baq)�M]�cSWST%%1��9�W�ؑģp�W���������������>�\ /I�$I�� �T�6���Co�����9����I��gg���~�_?\��m�l�v�?�TSM^��ݓ���_X6k���yǶ���Y�} �:��8;�����z+-���a�C����0=F���m�P�I�$I�T�Y�H�4�X�;'.�`I����pv�֕���uLsF�nͤ���ٸ�L��x��\�,}U��r�����yn~!�;Tn6o�̝#z2,��Kο��|��4�|
6�ĺ��{0�jh�)�|�$I�$U �*���xg�6�#����Ja���z0u�Vn�����������4��IK>S~|Zݤx^��$�M��\5��A�1�i(���5�W���?E�$I����ø%U��K�{� �:�3]�ׯ�����3��#���rr�Tz�:��v�a�^}��E�,��SI�j�����������E{�Yw�ܰN���C�$I����;@$U��MYAn~!����S����ǵ���9�ٰ��&.�Z�:��b|�n�]�u�/ID��B�iú���O�{t9<>L�$I��o�D�Q�4���N[��g�$%1>�,qq�Ӌ���닷���<���2�<RU�y����ĸ99�޶�ާy�����+.��������,.z����A����$I�$�� �tTE�1n���h�aY-9��aG☖��N�a�j��]�R?�o��'��0yQ/��a���-�HN��D(,�~��E��i)���qM��o|�����̒S��%0�*HK7�$I�$I5���I:����F�l�M��x�8�g�q�\��� �;��7Vpǈ��#I��Fc�X��go�E��/*-{��Ɯ��ΙY-�p�v����Ö�rXӝ#2����2;Vw{�{J�JM��WC�Ő�n>I�$I�j0IG͎�y�e �pz7Z�U�cq�$��Q�\��,�����}ې��v,�ҭ޶��s61~�&6�>P6oߤ.c��3&�m�-��l�c����IK[��2-�;Gd04�U�毒b1�83���ʪ�V�a�� �l�O5�$I�$I�������ז����R���a�����5cd��L�����_��k�'!>.�X�Q�{������m�]6o���Y�Z36���7"�K��f����Z���{
i� 8�����-���`�#��Q���`�y�\l.I�$IR%� �tT�\��f�����3�l�p�Y=��|+�6����\vBǰ#IGEqi�w�o��99��t+E�����'umʘ�tN�hAJb�=_|\�A��������0�0��k]0�O�������1�Ɠ$I�$��� �T�J��6a �׎�v�BN�Ś7H�g��������ْ��K��X�śxqN�mfǾ��Ǻ�l�9��٧5�T��骕=y�R�����Y��p���P�y��$I�$I��,@$U��|���[�Ҥ^7����|�qm7'�����Ή����ǆI�F�2a�&^����[��͛�O��>m��NFk�om[���>��J�Ɲ`е��H����_�$I�$U
Ij������ �2��&������E�oL�~�>S�l���y��2�X�WRX\���7g��F����8N�h���6�ԵY�=��ʋ�`��`�Ǫ7��m�=�9���0I�$I�T9,@$U��'-��8ʀ����&�8G�[����N<��j�|i1�wiJ�d�E�j��b|�n/���Յ��9XR�X�������V��M1e5WR����G`��`��#`�����p�I�$I��/�{�*���xs�V�#�;:�H$v����owe��\6��ϯ�XΝ#z�I�\v���99����Ɲ��m�alvFg�ӱi�� v��`�a��`�X�^����L'I�$I�����
��`	wM\�N�D��BN�ե$�sϨL.~rOO[��m��0�X �ż� ����Ѻ]e�zI��j��~���И���U<V9�7���a��P�7��o~�.�����'I�$I�����
��[+ٜ_Hz�:\��a���N�֌����y��e�B&\s�;���(��θ9�xcqK� D"pB����NgHϖ�Ir��7�iN��c����f=��Y�@Br��$I�$I�Wg"�[�W�_>X����Y�_�����.�ƢM<5mW��)�H�e�����&��̶=��]��glv:����eZJ�	k�hV���X�A��ӷ���A�$I�$I��%I�H4��(��ҳ���"�H�X��������t�B~3egf��M�:a�R�}�A^���g�$��lިn"g�iØ�6d�I�v�u���BX��ر2��%@�90�Zh�+�|�$I�$�BX�H�F^�����wQ7)�F-?�ضe��|i��X_xV�+,.��e[yqvSWl�4 1>·�7gLv:�Ӝ��a��v�G�YO����,9��>��!��	5�$I�$I�X ���������� �pZ7Zנ�$��"�7:�a�ϛK����-�lv,� �X�9v3nN��o������m26�g�jM�zI!��a����¼g��0������@�E�� �|�$I�$騰 ���=��Rv�/�{�|��aǩp][4��'u�wVq���ߥ	RÎ�j*g�~&��ĸ9�X�}_ټej
���06�]��B|���`��������5�����q6��� I�$I�j2���|�n'�}��=�2I���G�\��.��`3�v���o�஑5�/}{����\�����5;��u�93�%c��Թ	�q�VaJK`�D��l�]>�vfP|��bsI�$I�j�����B��{�1b�Z�nM$a	�=�D>��_��We��ܹ�/����T6l��_�޽{{�p�'���B۶my��?���矧{�����ū��zT>�ڨ�4ʭ�p�qm9�C�=)���3*����c����R�W��������ywϛ����cP�&��wz��m����pBצ���^��8<�^�4(?ⓡ���ڏ��A��-?$I�$I�E�Dj߾}��ݛ�.��1c�|�������~�׸���;vl���/$77�)S�P\\̥�^ʕW^ɳ�>@AAg�q��v�?�8.��.�aÆ\y� L�6��~������u�Y<�쳌5�9s搙�y�	�O~���[�и^7�v��Mݷ��n�g�2��I��w���[�u//��a��M����;6����6��ۆ�FuCLXC�¬?��OBa~0����w�on>I�$I��H,��B5S$a���5��5j{��᭷�`�ҥddd��Gq��0y�d�FNN�[�����[o%//���`I�O�S&L���e� 8��طo/��r��8p }�����?��������Ojj���GP#m�}��~�.�Ky�^�{l۰#U��{r��%�@1���'v
;���]����`3/��a~N~�<5%��[3�_:}�6$�]o��`����!Z�w�A�B��B�e�$I�$����6� Qh�l��+����O?]6�>}:6,+? N;�4���9s&�G�f���t�Ie���!C��/ɮ]�hԨӧO��o<��2�3Gr髻{�b�ҿCc��N;N�iZ?�[�u����7V04����_K�Dyg�V�����e[).~� >.·�5cl�t�ݽ9)��!'��b1X�L{V�]>o7_�����,I�$I�� Qh�~�i4hp�QYyyy4o����hܸ1yyye�t���kZ�hQ�X�F����+�}��O���<x����]PP��>���%[xc��"�3:��Z���;�����M�Z��;_Z̟/9���%b�7����&��̮��e��l�ʘ�t��Ӛ���CLY�������[��CD� �lt=��7�$I�$I��,@�'�|�/������� p���s��w����_Tp���֢Aȉ*_\\�{Gg2��yk�V^_����Va��Q��_����7'��[��͛5Hft�6��nC����{����
3�{�J������Q�0�I�$I��*�D�x���Y�|9������lْ�[�6+))a�Ν�lٲ�-[�v�'o�5�<�y~���vlVAAm�֎�G��W�i��4�����5�8��ڢW�ܙ��^ŝ3�KSRSÎ�
����7o��99|�j;�l�JN�㌞-�݆�4%!ޣ���]�a�c0�(���J�~߇:�B�'I�$I����/�����w�އ���ݻ�={6��G�����D�QPvͭ��Jqq1����S�L�c��Q�Fe׼��[���?.{�)S�0hР/̔��Lr���|�[���� p�Ȟ�M���:�=���ofݎ������}vfؑ�E�1f��ɸ99��0�}E�e���И1�m֫�e�і3�?K^�X4�5����<����K�$I�$}J�~Sn�޽�Z����k�2o�<7nL�v��Ί��_��ןy�=z0t�P~�����S\\�u�]���O�֭�������˹��Y�h������o[�<��?���'�̯�k�ο��/>��c�x≣�O���b�6a%���h��-���j���x��Ņ��33�3:;�>m�K_����?'�qs7���@ټm�:��Θ�6�oR/Ą�@4
+&��7L+�w�6�.���v$I�$I����>9�C��N��)����%�\�SO=�O<���crssIKK�̵;w���cҤI���1v�Xz�!�ׯ_v͂���k�裏hڴ)�_=7�|�a�����s�m��n�:�v�ʃ>ȰaÎ�s)(( --���|RSk��/�����O��x��x���ʸ���7w=Z�2��=���?P��63n�&f��U6o����^����q���h+> ��	�����D���Zzg�$I�$Uw����Y�H_�oаk_���]v�+�gv窓;��Jٱ� ���]v�/��a=��I��/PR录�xq�&�,�BQIp�R\N�ڌ���9#�)��!'��n����	��f�ip�0����:�|�$I��
��k
�G`I�B�������֢>���1�8UN����rf�ߋ�͔����;d��%�xqN/�����Ee�cZ4`l�6�ݧ-RSBLX�l_	�������`ְ��~���O�$I�$�8 �>���;�笍 �3*�D�w�\�96���0k�N�xi1��X�N
��=�L���f�,oOټI�$F�i���tz�N��Se��`��`�Ǌ��筳a���c$��GI�$I�tt�����()�r��E |�_:�;69Q��D�otg��=�^����1,�Uرj���R�,�¸99��r;���tǤ�8N�ќ���|L3���-ʍ�[�~h?�!VZK_
���s�C����v�\l.I�$I��:I��Դu,��Cú��lX���Ty]����ouᡷVr��Ŝе)�)�aǪ�b������99�� �=�%e��mא1���Պ�u�BLYC-��o������p�]�o�x�7��s��v	%�$I�$I��,@$f���f�
 ~vfw����#qͷ:3i�f�n���������v�k�������qssX�cټuZ
c���݆��ꇘ��[2���>/��,�nS��8�
�״R#J�$I�$������IK�_TJ����N��aǩ6R�wT&�y&����}�з]��c�{
�yma^پ�O�M����V��׆���JGU�4���?ˏO�K�3��H�Si�$I�$I�����2o/����y��E�gT�/&E��4eLv������-d��'�s�(���`�v������yG�`u���C3[R7��+�4�~��牖@�n��$I�$)t�j$	�E����b .?�#=Z����z�uX�Y��ey{x�����aG�vVl�Ësr�0w[
��;5����tF�mC놾�^�b1����d���rt�H�$I�$I <��Jrv�uZ
�sjװ�T[M�'s˰���~��
�e��m�aǪ�v�=����7g7���Mdd�֌�N�wz��w%U���`��`��`��#��-�^&I�$I��#d"�U[���{k �cDO�%���8�_:/��a�ڝ���"���q�p�9���β��0{S�o�$�H��pJ���N���HN�9i--��oÜg`����V �u��HX�&������@jkh?�2K�$I�$}._�j�X,�mQ\����������"����b������xua�{�
;V��Ř��ϋ�s��`3���=��&���mѻ5M�'����ڵ���=��筳!�b�)��d"<w1���P�7�����$I�$I� �j��h�Ykw�uO!���0c�NR�kdO�T� ]����ou��o��I�9�[SRSÎ�ͻ0~�&���a��}e��Ɍ�ۆ���tk� Ą�Tq!,{9��c���:�����}��y��d��s���7�=�uP~d����$I�$I_�D�e&/���IK��/<l>�gKwUT���ՙI�7�f�>~5y9��v�J��`	��1nn�V� v�f���8��l���t��Ҕ�8K�J��0����P���0����ς��rN�H�>�O��o{��$I�$�
��b��;�[��


HKK#??���԰�T�ɋr���s���~�^6C3=��"M[���4�H^�j0��7
;�Q�Ƙ�f/��a�<���=6�cc�f�sfVK��aBS�_��ȝW>OM��B��Q���I�$I�j������� �j��h��'-����wOZ��-���
4�sӲ�跎_Ȥ�O 1>.�Xn��������9�������7����tF�m�Fa��`����K^���<.�v{t:�;7$I�$IR�d"�����̱W�r���v'�:7��`��-�z���-,���_>X�U'w;R�ؽ��Iryqv�6�.�7HI�^�9�_��5r�L������v�.�7�q��<��4�|�$I�$I��D�%�������\�#׸^��������\��V��n���(S�ocܜ�Z����( �qN�֌1�m8�GR���ҕ���7`��`��;t�XR}�}/��c�BJ�$I�$� R-ѼAJ�^��flv^���kvrۄE<u�q��ΈX,����8'���6�c_Q�c=Z�26�#�������X����� �{�����'I�$I����߱1��R��/��%�-�R�߱qeG�"������߽ϻ+����\���:�X�Ֆ�B&��ĸ9�X�eOټi�dF�i͘�t2Z��,E���s����Dݦ��A�����I�$I�$U R-��\��9D���������s��\sJg~��J��6#�Nbرs���7����M|�r�C��$%�qzF��N�ĮMI���ܫ�X6�J��/���`��.��G����nNI�$I��*"��>���Z������4���IM�9��>yQ.wOZr�B�Vi)�9"����BLV;,)��߿Ϛm��p@;��v$����ɸ9�xua.{��=֯}#�f�3<�iu�VYSk��	��9���E���ң���&�|�$I�$}���������oХ����d�B�7���Ώ�3c��b /^=�~���c��}�8g���q灲y��u�݆1��thZ/�l�^4
k���X�2���ɐ12(>:�qމ#I�$I��j��k�<K����"��$����NM�N�t����-���N ����*(,������G�v���%�3,�c��ӿCc�,��,3��7ؽ�|�"�/��s��{z$I�$I����$���a=xk�V�o�ß�_����|�>VIi��Wm���9LY���%Q "8�KS�f�3�gK�$���/J�`�k0�o��-��~HN
�신U��_�$I�$I����$��Q�$nփ�<?�߿���Y�hפn�~�ey�8;�	�6�m���y����/�Q}��2-�B?���m˃�������۟�=FBR��7!I�$I�T�X�HRH�d���9L_���^Z�ӗG�����=�83/��aInAټQ�D��ӆ���d�I��G_����x\p�Gά�y���2�߃&G�n I�$I����D�B�D�wt&C�>��Ƥ�����+?Oaq)o-�ʸ99L]���h����vo���6|��$%�0;��|��x<��x�64�ۣ����%K�$I�$U$_m��ujV��N��o���瓖pB�,߲��{
i� ���9�c�s6���99�<3�%e��nې��mѫ5��%U槣O۷=8�j��`۲�y��A����Рex�$I�$I�j8I
�O��K�6�z�>Nx�m���=�*-�;Gd04� 9��3~�&��������nt�6��nC��*�s�!�RX��y����`�Pz���A��.4�$I�$I� ���x��ӆ�LYqX���_����E�ڳb�f��Y�X��x��l��~����s�Q%ٵ���=9���}!�b�)i��$I�$I��,@$)d������s���3�ח�uj��~��lI�d�������q��]��m�4���w{��3�$I�$IR��+g��Ykw��_��ם{l:?:�+��VB*}��E�B�������N�
J��gAbJX�$I�$I�t��$�l�//? �����#,������n��s��m�υ��Bh�!�x�$I�$I�,I
Y�Gv���^�
���iA�x��q��}��:�q�Ɣ$I�$I�� �����ؘVi)��������2-��Wv��i���l��|Ǫ�y���W�χzM��'I�$I��#b"I!���p����"pX	9��;Gd���V�(-�US��+^�Xi0O��c �H?"�;�$I�$I�.,@$�
�يǾ��ݓ���eZ
w��`hf���`;VG\��'��+����싡�hH�^>I�$I�$}m �TE�l��-��v'[�ҼAp�w~T����t"�����|^�	��np�U����$I�$IR�� ��*$>. �MQ��b�;/(=� �y$:�
�A�3!!)Ԙ�$I�$I�8 �����.X�|��c���y�v��}.�����I�$I�$騱 �$�,�(�{/��c�$(=�㓠ǈ`�G�� ..ܜ�$I�$I:�,@$I5C�&��l��|���y�̠����m^>I�$I�$U*IR�UR+&G\�~b�`��
Y��\���K�$I�$�6 ���g�����/ؿ�|������8�ꆗO�$I�$I�� �$U�����Wg��뷀�����]��'I�$I��*�D�Tu�b��1�}�����<]�v{t=���)I�$I��*�D�T����s�mY��q��N�>@����$I�$IR�g"I����杠�X�*D��yB�`�G�E���K�$I�$�X�H�µk=������[����:R���'I�$I��j�D�T�J²�a��`�T �SB��=Zf�P�$I�$I՝�$��lY��v��;�,4�~$���O�$I�$I5��$��*,�E/���9�������Bh�1�|�$I�$I��,@$I/�Ӄ�c�x(9����a����q���$I�$IR�e"I�8{����ܿ��U���{=z�����O�$I�$I���$�)-�Uog`�d����z�9�^m�C$nNI�$I�$�* ���g�j��w��,��+��}/��1�� �|�$I�$I��,@$IG�� ,�q����y�&�����{мGx�$I�$I��C,@$I_n��X�<�?4�@�S��=�	Ia&�$I�$I�c"I�|v���g oa�<�]p�G��a���I�$I�$I���$�\4m5�o�QW��y|t?�/��߂��0SJ�$I�$I_�D��a�?���֕ϛ��싡׹P�qh�$I�$I����D�j��bX1�<�ބX4�'5��s��=ZgC$nNI�$I�$�k� ���fۊ`�����m��v���#�lH�^>I�$I�$�X�HRmpp/,� s�g���5�����v	-�$I�$I�T�,@$����`�����E/B��`���C��=�����$I�$I��I�i���
��ض�|ިcPz�� R[��O�$I�$I� �TDKa�;A����`�G����x�K�$I�$�ְ ���l�������X>o�;(=2ρ:C�'I�$I�$��D���h)��{�@��~0��~M���.����� �`�������U��%I�$I����D���%a��P��|����2F��W�v�_��$�{1�8�T~nI�$I�$�
� ���`�Dx�b����DA.<w4�;ה���>@��A㎕U�$I�$I�,@$)l���Ώ�,?�|�sD��3!��r�g�ƒ$I�$I�T�D�¶~���^}��<#�~I�$I�$��;�$�z���u��jI�$I�$�&�I
C�V����5����oqt3I�$I�$I5��$U��;a���?����()��w�@jkh?�R"J�$I�$I5��$U���0����#�!d_�]��ṋ]��e��oCp�$I�$I��X�H��RZK'�\m�^>o����s �n0k��}&�|�B���A��1�r�K�$I�$I՜�$U�=[`����'7��%@����Jh7"�Ͼ_�H�>�O��[���{�$I�$I��5X�HRE�� ���n���!Z��5�c/�~�Bj�/��x�x���*I�$I�$� ��M��qA�yn�<�8��C�8���'I�$I�$�R ��u���G	��ڿ#��'C�X��h�n>I�$I�$��� ��#���`�a�+���t8�2Ⱦ�57�$I�$I�$�D��\�>X�o��'غ�|���`��1� �o��$I�$IRU�+v��Ev�����w8���B���@��p�I�$I�$I�B ��i�(�~+Xj�r
�;�G��N�0J�$I�$I: �P�s��	v�)�w=#8��^>I�$I�$I_����m���n�����}�,9�~���t7�$I�$I����DR�SZ+^���u�ϛ��WBֹ�\?�|�$I�$I��1I�Ǿ0�i��I���"q�}8��!t8"�p3J�$I�$I� �j��sa֟`�Pz0��mٗ���Aö��$I�$I�T�,@$�L%E��`�Gά�y�>0���s$��O�$I�$I��e"������i�w�o�C\���������}[�Y\"�����c=�J�$I�$I�,@$UK&�䛡`s�,�5�%�gK͗N�hI�x�V�Wٗ@���$I�$I�
IUߒ����@��yA.<w4l�7���
���1�+5�$I�$I����DR�-������g�7@|2�:7(>Z��̄�$I�$I�� IU��i�{�E��tv��H�$I�$I��� I�U��#��x���!I�$I�$�Z�IU���0�)��ȑ]_�%�$I�$I��Y�H�Zv����������X��!�����J�(I�$I�$�� ��X����Q�ܼE�����?��S�	�6�������$I�$I��:I�))���aƣ�;�|�mhP|t8"�J��D�|���S[�G����-I�$I�$�ʳ �T�����Y�=��,���.��v���d����a�4ػ%���~�w~H�$I�$I�\ �*��U0�1��l�~��-����ˠn����q���ģ�S�$I�$IR�g"���`��~��)���2]=�;>$I�$I�$�Y�H::J�`���[P>����$I�$I�T�,@$U�O�{�|����:��x�����$I�$I��
f"�bl_3� ��y�~�WB�K�|��$I�$I�$U I__,�އ�������!I�$I�$)d ������@���y�3��8���$I�$I�Be"����	?	��t�~����i�p�I�$I�$I�! ���'�=�=%�Y�V�����$I�$I�T%Y�H�|e�=����-{��1���$I�$I��,�6����i�w�o�C\|�XI,z1(>�|��#ǜ	�q��$I�$I��j�D�m�L��7C���Yjk�������=�B���!I�$I�$�ڱ �j�%ṋ�����0������WB���C�$I�$IR�d"����Ώ�,?>-.F>�c��!I�$I�$�Z�;��J�~���^}�h1��[~H�$I�$I��,@��b�N�$I�$I��0���ߢb��$I�$I��*�D�-����@�.�@j��:I�$I�$I��,@��".�����Y�z{��u�$I�$I�T�Y�H�I�H8�Hmu�<�u0�N.I�$I�$I�`	a�T�2FB��~Z��~���+���$I�$I�T�x�*�{�ǈ#hݺ5�H�	&|暥K�2r�H��ҨW��w6l({����k���&M�P�~}Ǝ˖-[{�60|�p�֭K��͹馛())9용S����Mrr2]�tᩧ�:�r�O��s��[~H�$I�$I�a,@T����G�޽y��G?��իWs�	'н{w�N�ʂ����III)��n`ҤI<�����l޼�1cƔ=^ZZ����)**bڴi<���<��S�q�e׬]���Çs�)�0o�<~��s�W����O^�$I�$I�TeDb�X,���"��ǏgԨQe���?���D����}�����ӬY3�}�Y�9� �-[F�=�>}:��^㬳�b��ʹh�����o��m۶�����7��+��¢E��ػw�f���G�������4���IMM���$I�$I������6� Q��F����+t�֍!C�мysp�1Y�gϦ����N;�lֽ{wڵk�����>}:YYYe���!C(((`���e�|�9>���$I�$I�$�l �4[�ne�޽<��:�7�x�ѣG3f��}�] ���HJJ�aÆ��o�-���+�����'��������|n��RPPp�_�$I�$I���)!� �=��( g�}67�p }��aڴi<���|��a��������5�$I�$I�$�bx�*MӦMIHH ##�y�=ذa -[�����ݻwv͖-[hٲe�5[�l���<�߮IMM�N�:���g?����emܸ��}��$I�$I���Y���$%%q�qǱ|����+V��}�� ��׏��D�z뭲Ǘ/_Ά4h �b�lݺ��)S����ZV�4����O���$''���z�_�$I�$I����#�T����˪U���^�v-��ͣq�ƴk׎�n����;��N:�SN9�ɓ'3i�$�N�
@ZZ�_~97�x#�7&55�믿�A�1p�@ �8�222�袋x�������n��k�%99�����Gy������]vo��6�=����J��3�$I�$I�$U�H,��B5�ԩS9�S>3��Kxꩧ x��'��������c�������.��������'�������2�?��e�[�_�������S�R�^=.��x��;��S�r�7�d���ӹ�������ğKAAiii���{7�$I�$I������f"}�AK�$I�$I_���)l� �$I�$I�$I5��$I�$I�$I�q,@$I�$I�$IR�c"I�$I�$I�jI�$I�$I�T�X�H�$I�$I���D�$I�$I�$�8 �$I�$I�$�Ʊ �$I�$I�$I5��$I�$I�$I�q,@$I�$I�$IR�c"I�$I�$I�jI�$I�$I�T�$�@��b� !'�$I�$I���O^W��u6��Y�H_`Ϟ= �m�6�$�$I�$IR��g�����Z(�~�>W4e���4hЀH$v�#RPP@۶mٸq#���aǑj5�����E����Q�:�z��������سg�[�&.�m�|�"}���8���Î񵤦����Ӕ�#�����E����Q�:�z�������
���$I�$I�$I�q,@$I�$I�$IR�c"� ����y�$''�E���z�����ïG����Q�:�z��.��K�$I�$I���;@$I�$I�$IR�c"I�$I�$I�jI�$I�$I�T�X�H�$I�$I���D�!}�Q:t�@JJ
`֬YaG����￟�;�мysF����������k���&M�P�~}Ǝ˖-[�fÆ>��u�Ҽysn��&JJJ�f�ԩdgg���L�.]xꩧ���'Uk<� �H����e3��ʳi�&����ѤI�ԩCVV�q��X�;V�ZQ�NN;�4V�\y�s�ܹ�/����T6l��_�޽{�f���x≤��жm[|��J���꠴���o���;R�N:w��/~�b�X�5~-JG�{�ǈ#hݺ5�H�	&�xe~�=���t�ޝ�����x��W+��;�����͍7�ȝw�ɜ9s�ݻ7C�a�֭aG���w�}�k���3f0e����9�3طo_�57�p�&M�����w�e��͌3�����R�NQQӦM�駟橧��;�(�f�ڵ>�SN9�y������+����_�R?_���裏���H�^����(U�]�vq��Ǔ���k��ƒ%K���M�F�ʮy��y衇x��Ǚ9s&���cȐ!�]s��x�b�L���/��{�ǕW^Y�xAAg�q�۷g�����W�⮻��'����W��~��_��c���#��t�R~��_�������]�עtt�۷�޽{�裏~����7m�4����r��3���w�QY���_�"�������tDLE<����]��ǩ�F:L�V4��<�V�i۩�U�Gؙε%n�DA��*"�RL��-kFJr�����U�W3K�|>�����ܟ���8�sny��}UW+##C���������7�dgg[�;::̠A���O?݃U����l$���~�cLKK����5��_�1�2�LEE�1Ƙ��z�x{{��m�y�Lpp����ύ1���暑#Gz\�{���IKK��%��ٳgMtt�)**2S�L1999���N�?���4i�W����4.�������������?��c���o$�={�Xc�m�f����G}d�1���	���ҵ�~���J3g�4>��Ǳ9s����c�E��H2������L3s�L�zƏo~���F��c�˝?^UUUJII��y{{+%%E=X`/�~��$i������*���{�ވ#4d���***'��i�IKKә3g������9.����eggk�̙���t���;v��Ν��*>>^/���u����r���Կ�?ޣCBB4v�XkLJJ����UYYi��<y�����1iii����'�|���nz'N�Ν;u��IRMM����4c�I�"�S�����
\����������Ir:�r��=T`/���Z�b����4j�(I��햟��BBB<�~���n�{�ҹ��9s���ںb9@��y�f�۷OO?��e��G��;vL/�������}�v-]�T˗/׆$}�OW�l�v�5p�@���C�F=��~����Ј#�����x�X�B��ϗD/=�;{��Л�'GO  ��.;;[���*++��R�[�ɓ'������"��ӧ��ni���;v��z�)IR||�jkk��/j�=\p�x�״q�FmڴI#G���]5h� z �/a�˅�����G�N��8~��)�\��
��e˖�7�PII����X�].�Ο?�����_�=��u�޼t�jc���p���JUUUjnn֘1c�p8�p8���o�瞓�����n�����Xll�%}�OW�l�r�����q�:}��7�Y�V��c�Y�@���`����?�vJҋ@������1�&�� ����������;wZ�:;;�s�N%&&�`e@�f�Ѳe�TPP�]�v)22��|BB�|}}=z���N���V�%&&����n���l��(11�c�Kc�_����:x����o��;V��Ϸ�M?�#))Iuuuǎ9��C�J�"##�r�<z�̙3�����ǖ�UUUYcv�ڥ��N�?���;悔��STT��Ç+44�����Ν����t|||���)�^zJw��]�k��Oap�6o�l���M~~�y���MVV�			1n���Kz��K��������R���d��;w��d�3d��k�.�w�^���h��.\0�F�2���f��������v�mf�ʕ֘cǎ���@��c��C��?������v�z��fʔ)&''�zM?�c�����p�_����>07n4����O��5f͚5&$$����70�f�2�������s�����xSYYi���Ltt��7o�u����8�N�`�S[[k6o�l�K/�ԭ�nV.4��~�y�7����͖-[Lxx���͵�Ћ@�8{�����6���F�y��gMuu�9q�1��z����8�v�Zs��!�_�������v�� z�&��y3d����gƍg����tI@�&�?���5������G?2���&00�̞=�455y����`f̘aLxx���Oj���=Ɣ���ѣG???s�wx\���� �~��?��O3j�(���oF�a֯_�q�������0N��������dSWW�1�����7o�	

2���f�����ٳcjjj̤I���������͚5k�|m@oq�����c�b���c�����g>��sk�t����+�_q�Ƙ���^{����???3r�H��ovٺ����czf�	        @��         �v@        ���         �!         �C         l�         �        �    �FCC��������.E��h�"edd|���^�Z�G��z    |�     �ƍ^}�Q�ܹ����ϗ�������mٲ��   �     �QPP���®{���`555���I���JKKSff����n@�   @�G    �S�N�#�<�+V(44TN�S/���>��3-^�X���STT��m�����Z͘1CAAAr:�Z�`�>��c�����7���)  @aaaJII�g�}&I*--ոq�Էo_���())I'N��$���k֬Yr:�


�=�ܣ��b�k755i�̙
Pdd�6mڤaÆ�����5���E=��n��6kڴi����F����8u�T-_�\���0`�\.�V�^�1��Ç5i�$���Gw�u������奭[�J�"##%I�������ԩS=޿v�ZEDD(,,L���joo��z��W`]��o2�$yyy��r��r)::ZO>�����u�����i   �-�    �%6lؠ��p�޽[�<�.]��s�j�ĉڷo�RSS�`��;wN��paڴi����޽{UXX�S�N)33S�ŀb޼yz��u��!���jΜ92�����Д)St��UTT(++K^^^����V�w�}ڹs����u��*==]���V�?������G���z��׵~�z577{�i�ܹjnnֶm�TUU�1c�(99Y�O���{�uk���۷�*++����FO<񄊊�$I���P``�*++�~�z���y���ݒ���b555y|�TII����URR�6(??_����T������C6l�$�3�]   �+/c���"    \�ԩS��ѡw�}W��?x���_s��ѫ��*Ir�݊��PEE�&L��'�|R����o�n���j������Skk���Р�C�z\����
Sii��L�rM5�5JK�,Ѳe�t��a���jϞ=;v�$��ѣ�����~�;�X�Beee�9s�������o����\eee]v���EFF���Z�G���5���\v�$iܸq�6m�֬Y���B�����ɓr�\�.ӧOWAA�222.��%�-Rii�������#I��̔���6o�|���z�jmݺ�z�ȷ�#??_�/V߾}%Immm���Ջ/��E�]��   �2=]    �ks��w[����QXX����cN�S��]555*))QPP�es���+55U��Ɋ��SZZ�RSSu���+44TТE������ӧ+%%E�������tq��ի��o���I.\P[[�����N��c7BTT�BCC��555jmm��ymmm�����{�uk������IRDD�u����4x�`+��.$�j�ȑVpqi�^�������Ӿ}�$I�ΝSqq��,Y���0�����   vD    ��������<�]�z���NIC���t=��3��!���ӎ;����+//O�������+����˗���P��_�j�*i	z��GUTT��k�***J����u���k^Okk�"""TZZzٹ���k��jk��J���}�^7b�o3���������w�}�v�ءg�y�       `[cƌ�믿�aÆ���G///%%%)))I���/5t�P�'?���������ʕ+����M�6i	*//עE�4{�lI����k��Ç����VBB���_���'�x��v��p84lذ.[��>|�N�<�S�NY�h����1���O�ů�����������    n
<   ����l�>}Z���Ӟ={T__��۷k������Pee��z�)�ݻW���ڲe�����*66VǏ�ʕ+UQQ�'Nhǎ���+I���֖-[��~��������ǎ�#F(%%EYYYڽ{���������� k�JJJ�����;v���A������w����k1}�t�y�Z�p�8���r�Z�J��j��� �!�~��5���1Fn�[n�[Ǐ����}�v͚5��K   n
    �M4H������Pjj����b�
������[���z�wt�}�)&&F�V�Һu�4c�������w����eee);;[?��$��g�Uhh�&N����t���y<�C�^}�U9�NM�<Y�g���C���O}���t1\x뭷4y�d-^�X111z��t��	k'����Z���h�֭jmm�=�ܣ�zHyyy�d��p8��s�饗^ҠA�n���̙3���PDD�bcc�n�:=��V�   ����cz�    ���j���*..VrrrO�sU���4i��=�;Ｓ��   �-�    ��v�Rkk������Ԥ��\}��G:r��e��i


Rtt��=�����������K   �-�t    ]���]?���u��1���O'N�ƍo��C�Ξ=��\���
WJJ�֭[��e   ��         ��C�       ���         �!         �C         l�         �        �        `;         �v@        ���         �!         �C         l�         �        �        `;         �v@        ���         �!         �C         l�         �        �        `;         �v@        ���         �!         �C         l�         �        �        `;         �v@        ���         �!         �C         l�         �        �        `;         �v@        ���         �!         �C         l�         �        �        `;         �v@        ���         �!         �C         l�         �        �        `;�������    IEND�B`�
```

- Verification:
| Length | ECDSA Time (<span class="unit">&mu;s</span>) | Dilithium Time (<span class="unit">&mu;s</span>) | ECDSA Memory (<span class="unit">KiB</span>) | Dilithium Memory (<span class="unit">KiB</span>) |
|--------|----------------------------------------------|--------------------------------------------------|------------------------------------------------|----------------------------------------------------|
| 100    | 16092,9629                                   | 16073,7253                                       | 615                                            | 622                                                |
| 500    | 16190,9976                                   | 16194,5630                                       | 618                                            | 625                                                |
| 1000   | 16495,3762                                   | 16534,2457                                       | 622                                            | 629                                                |
| 2500   | 17086,1121                                   | 16937,7886                                       | 633                                            | 641                                                |
| 5000   | 18359,5242                                   | 18312,4593                                       | 653                                            | 661                                                |
| 7500   | 19497,0142                                   | 19460,3409                                       | 673                                            | 680                                                |
| 10000  | 20633,8036                                   | 20595,4703                                       | 692                                            | 700                                                |

In order to have a better view of the time consumed by the verification, you can have a look at the following graph:
```
�PNG

   IHDR  @  �   �M��   9tEXtSoftware Matplotlib version3.5.2, https://matplotlib.org/*6E   	pHYs  a  a�?�i  �IDATx���w������sf+[q�����@E@�5�$1j�ƖcT��BPc7�&&b~��5&�"��(F�w��]`�63�OܸQ#*0�p~��C�{.��=a���W(�Ő$I�$I�$IJ �x7 I�$I�$I�t��H�$I�$I���c "I�$I�$I���$I�$I�$IJ8 �$I�$I�$)��H�$I�$I���c "I�$I�$I���$I�$I�$IJ8 �$I�$I�$)��H�$I�$I���c "I�$I�$I���$I�$I�$IJ8 �$I�$I�$)��H�$I�$I���c "I�$I�$I���$I�$I�$IJ8 �$I�$I�$)��H�$I�$I���c "I�$I�$I���$I�$I�$IJ8 �$I�$I�$)��H�$I�$I���c "I�$I�$I���$I�$I�$IJ8 �$I�$I�$)��H�$I�$I���c "I�$I�$I���$I�$I�$IJ8 �$I�$I�$)��H�$I�$I���c "I�$I�$I���$I�$I�$IJ8 �$I�$I�$)��H�$I�$I���c "I�$I�$I���$I�$I�$IJ8 �$I�$I�$)��H�$I�$I���c "I�$I�$I���$I�$I�$IJ8 �$I�$I�$)��H�$I�$I���c "I�$I�$I���$I�$I�$IJ8 �$I�$I�$)��H�$I�$I���c "I�$I�$I���$I�$I�$IJ8 �$I�$I�$)��H�$I�$I���c "I�$I�$I���$I�$I�$IJ8 �$I�$I�$)��H�$I�$I���c "I�$I�$I���$I�$I�$IJ8 �$I�$I�$)��H�$I�$I���c "I�$I�$I���$I�$I�$IJ8 �$I�$I�$)��H�$I�$I���c "I�$I�$I���$I�$I�$IJ8 �$I�$I�$)��H�$I�$I���c "I�$I�$I���$I�$I�$IJ8 �$I�$I�$)��H�$I�$I���c "I�$I�$I���$I�$I�$IJ8 �$I�$I�$)��H�$I�$I���c "I�$I�$I���$I�$I�$IJ8 �$I�$I�$)��H�$I�$I���c "I�$I�$I���$I�$I�$IJ8 �$I�$I�$)��H�$I�$I���c "I�$I�$I���$I�$I�$IJ8 �$I�$I�$)��H�$I�$I���c "I�$I�$I���$I�$I�$IJ8 �$I�$I�$)��H�$I�$I���c "I�$I�$I���$I�$I�$IJ8 �$I�$I�$)��H�$I�$I���c "I�$I�$I���$I�$I�$IJ8 �$I�$I�$)��H�$I�$I���c "I�$I�$I���$I�$I�$IJ8 �$I�$I�$)��H�$I�$I���c "I�$I�$I���$I�$I�$IJ8 �$I�$I�$)��H�$I�$I�������*��a����	�B�nG�$I�$I:��b1v��M���^|z җذa�7�w�$I�$I�amݺu4j�(�m�d "}���l �:'''��H�$I�$I����"7n\�9�t��H_��c�rrr@$I�$I��o���/�&I�$I�$I���$I�$I�$IJ8 �$I�$I�$)�8D��"�����nC	"%%����x�!I�$I�$�@�o(��i�&v���V�`j֬I�z�&I�$I�$} �7�i����OFF�V�[��b�e� �ׯ�$I�$I��×��D"���V�Z�nG	�F� lٲ���|�Ò$I�$I��!��K���3?222�܉ѧ���-#I�$I�$}s ҷ�W:�u%I�$I�$}{ �$I�$I�$)��HJX�P�W_}5�mH�$I�$I���Kq�Ƙ�j[v����N��y$�=����կ~ū�������oܸ���:*>MI�$I�$I�+)N&.�Ȩ,dcaI�^��tF~�=���Ϊ�X,F$!9���vU�^��Б$I�$I��ÁG`Iq0q�F�x��*�����x�}&.�x��w�^~�����E��������ٳ'�\s ͚5�;���s�%33���裏�׵�;�<�9�*{���Ԯ]�?��O D�QƌC��ͩQ��</��Re��3�BL�0�N�:����[o����;v,�F���?$

�;v,P��իW
�x���ѣ5j���Od�ҥ���t�ܙ��,�֭[��㩧�������tڵk�c�=�__I�$I�$I�� ����W�ʺH4���>&�E� B��^[H�V���8�)I�B�l�7��o�����w����[x����СCeͽ���-��¨Q��4iW_}5mڴ�_�~����>����ٳgYYY L�4���b�<�L ƌó�>�O<A�֭�9s&?�я�S���vZ�n��f��>Z�h�?��:�sX�`'Nd�ԩ ���~i�ȑ#y衇hҤ	_|1�w���<���ddd����#F�����s�1b�y�:v��|�e�]Fff&^x���bK�$I�$I�� �W���I��:1`SQ	��j�~�/�} �����={������>K�>} x�ghԨQ��nݺq��7ЦMf͚Ń>��Ȁ����W^�. ������O';;���R��.�N�J׮]hѢo��O>�d� ���o���ԨQ���,�����ȫ믿� p��Ws��2m�4�u��%�\R�	������Yg�@���Y�p!O>���$I�$I�T��HG�+VPVV�I'�T����G۶m��}N|v��C}�������~�s�=�\�޽{����Ο��g �/_Nqq�炍��2:v�Xe�s��_���;����֭���[eo˖-@p\؊+��K���*k***��S&�$I�$I��� D:@j�$���_Y7w�.z�ݯ�����<o��[�����v�ilٲ�)S�P�FO� �7��V�yiiiU֙������������ދF�U����_%4HJ�^_wI�$I�$IU�HH(گ��z��C��t6�|��P/7��������e˖�����;�ФI v���ҥK�?5gΜ*?oΜ9��=N9�7n�_��&L������ʀ�}������v��*���RSS�D�z���U�n]4h�ʕ+9�����%I�$I�$< �!�1�����	A��Ӹc�w��� ++�K.��n��Z�j�������	��U�f͚�=���g���)S��_�ʸq���>�wO<�K�.���_����������k�%�ҽ{w
�5k999�x�F�f�X�j��ϧQ�FdggojԨQ��$77��RZZ�{��Ν;:t���$I�$I��/��%��������@���*��r�y�G'0������{/=z����.}���{��t�ԩJ�u�]�{�Gǎ���;y��*����?��Ұa���⟺�;���3f8�q��Ѽy�o���>�lH�^��S�/���7�����Kyꩧx��9��c9��;v��W�$I�$I����b_t
�t�+**"77���Brrr��VRRªU�h޼9���_r���Ƙ�j[v����N��y�ɏ�ҳgO:t��C=D�f͸�k��ky
�__�$I�$I���>_�����()�k�Z�nC�$I�$I��G`I�o�=�YYY_��裏>h�=�裿���=��A��$I�$I��×O�Hbƌ���z��/�;���9餓�𵔔����?����/|�nݺ�$I�$IM4kކ=�!�.4=�I��JJ( ��[vv6��ه��M�6=���$I�$I:h�o�����i �O�__R��,I�$I�$I:T�/��j�P�1�_�Z|����$I�$I�$
�H���/x��{o�$}k �$I�$I�t(�y��O~T���A��o� D�$I�$I��H9|������|p{��A�$I�$I���%�%�a�Hؾl�~NV݃ۓt��	I��E]�g�Q��ٳ'�\sM��9�B����j�ې$I�$I����`���yA�Q#��l�_4��`_�z���Cۧ��@�x�F`՛��K�?p��կ�С���7n�ȠA�}C�$I�$��s5�t1��7�����}(��>�� �A>]�*�1?������e�k0񦪃�r��_C����W���bD"����ow���;I�$I����o'̼��"e@�?z��F�]��?�����5�L��Q�S7Q�Q�0���o������!%�D)�/��j�P�1�_��A�u4e̘14oޜ5jp�����K/U������|�������ѣ+V�  �0t�Pj֬I�Z������>��f4��o$//�z���_�j�z;��8�s�앗�S�vm���?�W�3f� 
1a�:u�DZZo��֗�s�ر�5�?��P(D(b�ر@�#�V�^M(��_�G�ԨQ�O<��K����ҹsg���4h[�n�r���z������i׮�=��~}=$I�$I�a���~� �	=�3���!� 70)څ�e��˲_�ò[�^�0��] ز�$NoDJ,>"(��u]4n���
�i��I_}������1c������OкukfΜɏ~�#�ԩC�V�8��S�ٳ'ӧO'''�Y�fQQQ�����رc���HAA��?���
�{��r�g�y��C���;�0{�l.��"�u�F�~��go�>����ٳgYYY L�4���b�<�̯����N����7��}��G�-8ꨣ����s,`�ĉL�:����/�9r$=�M�4��/���#;;��~���~��0b��q �{�9F��#�<Bǎ�����������/��_I�$I�T��b���0u�Z�巇~w@�>�����[�o�-��欮��Q�̉�����g��Υ#��t���]��b��!w7޿�[6@j�~����r�]w1u�T�v�
@�-x뭷x��'i֬������&%%�6m�T���z�aÆq�Yg��O0iҤ����c�ȑ �nݚGy�iӦ}e 2`� 233y�W��� x���9���������?��~��_y?�5j���Err�~yu���3`�  ���j�=�\�M�F�n� ��K*� � 0����+�f͛7g�<�� �$I�$�ּ�o�d����p~�7���Gxz�j����%�7��&�)��~�%C@��t�4�;�@Jx �d���.(++�cǎ�ڵ�=zT��UXX�ƍ9餓*�����ܹ���:�㪬�ׯϖ-[�����d~����s�q��w�^������?�y����Ν;����Ͼ��u�p��V�����ݻ�+Vp�%�p�e�U�TTT�ϧL$I�$IR5�mL	K��L�~t���T����_�}����08Ϊ}�n\���r�x�}��� ���1��I
��i����t��dOc|�5o�s����_�����}�Ӟ={ 7n6��ZZZ�\s�~_���_J("���l�o�>��v[�laʔ)ԨQ��_��gef��S1_�g�[�ߏ���ާ���~���W	� ����x3I�$I�T}��
o��=�����C�a�]��l��m�5~o(�An:��o˙�w����N`�?���?�>��3��xL�C���f "(���Eղ7�4���P�z���7�kh߾=iii�]���qQ�:��x�g(//�\����K���y�w8��S��I�y��q�	'�O9�7n�_��&L�������^���o*55�H$r�����u�ҠAV�\�����/I�$I���b��(��0�����~��N�ʲ%�v3f�"f,�
@vZ2W�j��ݚ��R�3���ԧ_�z�]��-�K��������2 ��p�5��c����aǁw�� ;;�믿�k���h4J���),,d֬Y�����_���������?dذa���2g��t�B۶m��꫹��iݺ5�ڵ�`׮]����;�'�x��K�����w��t�F�f�X�j��ϧQ�FdggojԨQ��$77��RZZ�{��Ν;:t���$I�$I:����0�N���S?�w��wB��e��Jx`�R�:o�$�C���\ջ�����p��-k�7!�@�xh:��O0�`���r�G��ڭ���ԩØ1cX�r%5k��N��[n�V�ZL�>�n���N;���$:t�P9����c�ƍ\xᅄ�a.��b�<�L
h��>�G��iӦ��ޟ�����>��_~�^�z�k�.�~�i.��o�.�^z)�{��p�dffr�����$I�$I�A�|L���&�gs6�� �)��wo���o�b_yp�Ġc�q��v4�}p�����b�=�X EEE���RXXHNNN��JJJX�j͛7'==���$	f���Yu����^د/I�$I���lZ Sn�ӃuZ.�z=t�R���WD���u<8e���pB��R@��y��Z�_��I��O�H�N��Ȥ$I�$I��hL�bN�.���7@Fj�b1�-����|� ���ঁ�xL=B!�wHՍ��C���?���ִiS>���rߣ�>�5k�|�kO>���%I�$I:R��ُBž`��3���ZT�}�nw�_�;�v pTF
W�i�y'5%59��%�I��駟�I'�􅯥�����?����/|�nݺ�$I�$����������a��`�������'V���Q̽���ڇ�״�0wo�=[��~�>ːt`�H:d������>��mڴ�!��$I�$I��b1X2����˂����o�������ry}ϼ���H�P��ؐ����A�q|��I�$I�$I�o�<�|���3jA�a��"H
��(���������)��&ѽUmnԎc�ƩqIߔ��-D��x���+I�$I����a���o�:9N�9t�҃P#��m��I�Y�#�Ҷn6���6up.�@�o 55�p8̆�S������P�Z,�����[��IMM�wK�$I�$��턙����A����B��ۨ�읕۹k�">����9i\ׯ-gwjDR��{�Ù����a�7o�ƍٰaC��Q���ȠI�&���x�"I�$I�᧢��f�%���=��P��ʲ�[�p���L]����$~vZK.�ќ�T?6���%K�Pjj*M�4����H$�v� ���HNN��"I�$I���X>~���]k����A�ѪO��Kyh�R���:"�I��vi��}�P';-�o@ҁf "}�P���RRR�݊$I�$Iґk��0��`�9@V�ਫ�C8	��
�zsO����e�7��k_����U~V�:�t�H�$I�$I:<m[SFq�:%3n��JH� ��Ҽu<0e)��J8�Q.�.���Ը�C� D�$I�$I��e�Vx�nx�i�E �'�z�� �b1f,�����d�n ������α�	;�\Jx �$I�$I�e�0�Qx�a(B��~��N�ʲ�3a��o �F
W�n�]������%Ł�$I�$I���-�����������мGe��]���^���XR��\xJS~ѫ5��p��4 �$I�$I�����`�ؼ X�6�>#���!�����^_�g���"
���7��mi����%ř�$I�$I���g��r����r����吒@YE���Y�o�-cgq9 '5�c���kT3N�K�.@$I�$I�$UE`�h���p
t�N�2�`�����g�bVo/�e�L�*�OA>���%�H�$I�$I�Jw�[��G�b_�w���qWy-*�����q�x�. jg�qm�֜ӹ1�I�C߷�j� D�$I�$IR�D���g`�ݰwk�פk0�Q�ʲU��r���LX�	�)I\vj.?�Yi~�)����A�$I�$Iҡ����0e$l_�嵄~�C�!��c�v�-�7Ӗ��5TDc�C��΍��_����H��@$I�$I�$Z�����`ͬ`�Qz�NAR
 %��8k����ݥ �j[��ж^v��t81 �$I�$I�th�\�n������J�v�� ��x���?y	
K 8�A�pJ����[�a� D�$I�$I���o'̼��"e@�?z��F�eo-��]��pc k���m��7$ũyI�+I�$I�$IGE)��=̼Jv{-zB�;��q�e�71f�b�XA�NO��^���f��$��%%I�$I�$IV,�SG��5�^~� �hէr���������}B4)I!~trS��ݚ���8�I�� D�$I�$Iҁ��m�|k0� �>�΃p�4Ǟ�
�|c�s%%�Q �[���i��xu.)��H�$I�$I���-�)#aɸ`��ݮ����Fy$ʟ�]��S��mO ���-�����xu.)A�H�$I�$I���l�7����XBI��B�9����bLY���'.f�ֽ 4���M�1�躄B8�t��H�$I�$I��ʊaΣ���P�;�k3���:m+����]�1w� �2S��ok��҄��p<:�t�0 �$I�$I�������0�Nؽ!�k���	ͺW���^�=���m -9̥=���Z�����%a@$I�$I�$���`�ؼ X�6��#�� <ͱ����N_Οf��<#��:6��mhP�F��t�1 �$I�$I���mZ Sn�Ӄuz.���\)� ��G����<2}9E% �h]�a�
h� '^�K:��H�$I�$I�bE`�h���pJz�z=d����ǿ6p�%|�s ��e3lp�����%�@$I�$I�$UU��zf?
A���gB��ע�l��팙��}R@ݜ4��ߖ�OhDR8��%�?@$I�$I�$"���30�nػ5�k�5pިse��-�3~1�o +-���ւK���FjR<:���1 �$I�$I��t�,SF��e�^^K�w;���i�-�Kxh�2���:"�I��ui��}[S;+-�o@�>� D�$I�$I:�}2/p�fV�Ψ=�A�� )��
~?sO�\AqY����rӠv�����%�3 �$I�$I��D;Wô�a�߂ur:t��]�9 D�1���:���-�K�и&�.�K���-I�� D�$I�$I:��7��H��υ��!� �X�K�2f�"�n�@��nؖ!��'r����� D�$I�$I:T������dW�ע'���WY�`}!w�_��+�P3#��z��G'7!-�� �$I�$IR"�łc�����{���U����,���Ky�� �&���)��y�V�f�ī{I��@$I�$I��D�zL�6����C����<Os�+��yz�j�*� �ѡ�hK��2�չ$}k �$I�$IR�ٶ���%�ujt�:r��	@YE�g��ӗ�����[�q���kT3N�Kҁc "I�$I�$%�=[a��7b%A���0�����?��=��f{1 ��6����;�\R�0 �$I�$I�we�0�Qx�!(���FA���e������`�. �d�1�_�ߩ�I�C߷$D �$I�$I��*�_��a��`�AG�'4�^Y�r�~=q1�>�@��$~zZ.�т�4?"�����M�$I�$I:-�SF���:�	�	G���i��{Jyx�2�g-���sbc��ۆ���86/I��$I�$I�t8ٴ ��+���\�q=t�R�Pc_Y�?�Z��3V����>��iP;��͎W�tH�H�$I�$I������h��<�pJz�z=d���x��Ox`�R6� pL�n\�)-kǱyI:�@$I�$I��ꬤf=���}���gB��ע�l�ҭ����E� hX�7h���7 ţsI�+I�$I�$�:��ü�0�n(��5�8oԹ�l��"���7�5�����W+.<��)Iqh\��I�$I�$�:��`�x�2�/��ZB�ۡ�Osl*,���Kx��O�� %)�'7�ޭ8*35�o@��I�$I�$���dL�־�3jA�a��"HJ`wI9O���?�����( C��ύ�ҴVf����� D�$I�$I����a���o�:9�^	ݮ�� �#Q^�����.c��2 Nlv�.�c���ӷ$Uc �$I�$IR��7��H��υ��!� �X��7��	�Y�m/ -jgrӠv�o_�P���E@$I�$I��C��4=f�%���=��P��ʲ����xw�N je�rM����KR��oI:��H�$I�$I�J,s5�vص&��o��T8_�}/�LZ¸m =%̥�[���Z�����%�b "I�$I�$
�g�7����C����<'�so���������H�P�wB#��oC��ql^�? �$I�$I���mL	K���,�vu0�<5���ϼ��G^_��
 NmS�a��QP?'^�K�a� D�$I�$I:�l�c`�X�E ��.��� +�h4�kn��IKX�k �s�ep;z����%��g "I�$I�$He�0�Qx�!(���FA���eo���]��`} �sӹ�[��ؐ�p(�KRb1 �$I�$I��h>|���������Ь{eٲͻ3a1�o +-�+z����IOI�G璔�@$I�$I��ok�4�26/ֹM��H8�,��RTS��w��Ar8�y'5�}ZS;+-��KRb2 �$I�$I���M`�m�bz�Nυ�C��!%����n�J~��J��" <�7lK�:Y��\���$I�$I��u���G����S�����!#��H�����.e��R :6����tn���%��` "I�$I�$�"��0�~*�{G�	}F@^ b��o��	�Y�%�޴V7h��c�
9�\�I�$I�$�D�a�X�q7o��t�7�\Y��'����9+w P3#�_�n͏NnJjr8�Kґ� D�$I�$I�2�,SF��e�^^K�w;��~�cݎb���� @jr��tk��{�"�FJ����#��$I�$I��E>��o��o�Z�st���P����Gg,g�ՔE� �ٱ!��oC��2�Ը$	���t@�3�O<���l���9�3X�dI�������JjժEVVg�}6�7o�R�v�Z�BFF����p�TTTT��1c'�piii�jՊ�c�~��G}�f͚����I'��ܹs�{�$I�$I	f�jx�bx�w~$�C������e��BiE���\�i����f��,唖���U�y���T��z�7���+�3gS�L��������w��ʚk���������7�`Æ�u�Y��G"�BYYo��6�<�cǎeĈ�5�V�bȐ!��Ջ���s�5�p饗2iҤʚ���/:��#G����s���3`� �l�rh��$I�$��R�&�GN�Bp�ypռ`�yz�X��k}x�;�-bWq9m�f��E'�ܥ'qL��x�Iҿ�b�X,�M(qmݺ���|�x�N=�T
�S��?�<���� X�x1̞=��O>�	&��|�6P�n] �x�	n��&�n�Jjj*7�t�ƍc������Ȯ]��8q" '�t'�x"�<� �h�ƍs�UWq��7e�EEE���RXXHNN΁��H�$I��ꢢ��f�%���=��P��ʲwW�`��E�_��g�1�_�ש�I~�����|M����:�
���`޼y���ӷo�ʚv��ѤIfϞ��ٳ9��c+��PTT��\Y��k|Z��5��ʘ7o^��p8L߾}+k�[ii)EEEU~H�$I����G/O|L�5?�����^�?Vl���z��?1���v���ĵ}�0㆞��K�I�����&�r�5�Э[7�9� 6m�Djj*5k֬R[�n]6m�TY������?}���o�>v��I$�ŋa�cƌaԨQ���J�$I�����YA���`�]z��A8	�m{Jyx�2����H4FR8�9'6暾���N�c��a ����+�d�����[�ne�6��C�V����hܸq;�$I�$Iܶe0e$,�S������JH�`_Y�?���'�Xɞ�
 ��s�v��ώW璤�� D�/~����2s�L5jT�_�^=���صkW��@6o�L�z�*k�Ν[�z�7o�|��~��ٚ��jԨARRIII_X��5�[ZZiii��K�$I���m�V�1捅XBI��B�9���Dc���Ox`�R6� p\�\�*�k�Zql^��Mx@��X,�/~�^y��O�N��ͫ�ީS'RRR�6mZ�ޒ%KX�v-]�v�k׮|��Glٲ��fʔ)���о}�ʚ�^�ӚO����J�N���D�Q�M�VY#I�$I�� e�0�^�Mx�A��f�|6|����㍥[�7������FG���v�՟w3���ÔO�耺��+y�������Nvvv�̎��\jԨAnn.�\r	C�%//������*�v���'�@���i߾=\p��s�6m��[o��+��|B�g?��<�7�x#_|1ӧO��_dܸq��:�/��Ν;ӥKz�!����O~�C���$I�$I�V4� �G���^����Nhֽ�l�"�LXě˶����U�[��S������%IH(���݄G(�����~��.�������:^x�JKK0` �=�X���֬Y�W\��3�����/���&9�?�݌3���kY�p!�5��n��ǧy���^6m�D���o~�I'��_泌����\
����z_I�$I�?˧���yA��m}G��gA88ec�>��?��XR����kS~ѻ53R�ؼ�8�|M�f "}	��$I�$�0�iL�VL����z�r9��PTR�3V���VQZ��7��mi���Υ���k�7���$I�$I��p=�>�?� ���^y �G�<��Z���{� ��,�[�Сq���.I:h@$I�$I�tx*)�Y��G�b_�w���g�  �1��M�z�Vm�@�:��<�������%I�?I�$I�$^"�0o,̸����4�8oԹ�lޚ��������vV*W�m�OlLJR8�K�%I�$I�$b1X2����˂�����vh7��4��m{�g�b��	���0��h�OOkIV��Iґ���%I�$I�T�}2&�
k�����0�t$� �co������YCy$F(��Ԉ���R/7=~�K��� D�$I�$I����0�vX�`��]��n�@z %������f,gwI ���ð��hW/'>}K��� D�$I�$I�O�x�~��;��!8�\�=r������w�6� о~�.�{��ql^�T�H�$I�$���(B���Aɮ`�EO�w�?�����۸k�"�/�~n:��o˙�}ߒ�j� D�$I�$I���\M�v�	����G�>�Ηl�͘	���d+ �i�\ѫ%wkNzJR���$UC �$I�$I��ճ��������p�p��PcKQ	LYʋ�#��p��ܔ�z��VVZ��$UW �$I�$I��m�`�HX2.X�fA���!穙 �-��ə+��̕�+� 0�z�8��kgƫsI�a� D�$I�$I�֞�0c�����Ӆ�sd�P�������el�S
�	Mj2|H���űyI��� D�$I�$I�FY1�y�z��{mA�QP�- �X�i��p���,��4���M�1�z�B8�$�I�$I�$\�|�L�7{:B�;�Y�ʲ}�����Ϊ ����}Zs�IMIMǣsI�a� D�$I�$I��i0el^�s�@ߑp�YB�u;��w�^�0GҒ�\ܽ9W�lINzJ�:�$�@$I�$I�t�mZ Sn�Ӄuz.���\)� �����x��5�E��Bpfǆ\׿-kֈc�D` "I�$I���p=�>�?� ���^���Ҋ�7{�����}� tkU�a�
8�an��$%I�$I�$}{%E0�!��T���>����@0����Ƚ��nGPӶn67nG�6up.I:�@$I�$I���E�a�X�q7o��t�7�\Y�����5~~R@~v��o��:5&)l�!I:�@$I�$I����b�xL	ۗ{y-����n��i��[�p���L]����$~vZK.�ќ�T?��$<�_F�$I�$I_�'����`���:���.�� ��.塩K���Dc$�C����\ӷu���׻$�a "I�$I����cL�>~9X'�C�+��5��@qYO���'�X�޲ }�r�v��ϊS㒤#��$I�$I����0�>��;��!8�\�=r��xi�:����E� �(�[pR�Zql^�t�2 �$I�$I��(B���BI0��=��P�8 b�3�n���Y�y7 �������c�v��$)N@$I�$I�TU4s5m�Z����V}*�/X_Ș	���|; �5R��w+.�ڔ��xu/I` "I�$I���Z=&�
������p�p��Pcî}�7y	�|��XR��\xJS~ѫ5�)ql^���0 �$I�$Il]
SG��:5�]9O������g���o���"
���7��mi����%I�B �$I�$IG�=[`��0o,�"J�NB�a��@YE���Y�o�/g��2 Nj��-�8�q���.I��` "I�$I�t$*+�ُ¬��lO��f�u����	6q��Ŭ�^@�:�T@��|B!�K��/I�$I��#I4� ��������Ь{eټ5;=n��@�4��ךs:7&9)��%I�z@$I�$I��˧�����`������ςpj�ڶ�{&.fM �HI�S[p��-�J�$I����kI�$I�$%�M���`���:=z\].��t v�-�7Ӗ��5TDc�C��΍��_��ǱyI��I�$I��DU�^�bN	B�S���< J�#�q�*}�K+ �ն7*�m��86/Iҷc "I�$I��hJ������}���gA����h4�+����K�PX�4���tkU;N�K�t��H�$I�$%�H9�3��m�^�����F�+��Z����/b��" ֬������oH8�C�$x �$I�$I��X���#a��`�V+�;
��Pj,�TĘ�yc�V �ӓ��W+.:��)I��^���� D�$I�$�p��{���o����f�t$� �����,�y��Ar8�]�rU���e�ƯwI�"I�$I���юU0�v���`��]��n�@z {J+x���͕��G|l=nЎf�3�Ը$I���$I�$I��x̼����@:���CnC *"Q^xwO]ʶ=e tjz�.�Sӣ�ؼ$I���$I�$I�ᠢ4=f�%��^�^���w, �X�)7s��Ŭܺ��3�i`[]�P�璤#��$I�$IRu��\M��{�GC�ۡU�ʲ��vq��E�]����T��Ӛ�NjBJR8�K�W �$I�$I���Y0�V��~�ήu��<'�v{1�LZ�?�����0�to��z�$'=%^�K�w �$I�$I��֥0u$,�S����]����]�e�v�r�4{5���ձ��oC��5�׻$IՄ�$I�$IRu�g̸捅XBI��B�9��()��������(*� �G���<�G7ȍc�$U/ �$I�$I�VV��YAٞ`��`�;
� ��m��IK�d�> ���f��NkS'N�K�T}�H�$I�$�K4� ����� ��f�+����]��O
����u��r�	�H
��ѹ$I՞�$I�$IR<,�
�G����u�&�g$}��Aɖ��=a1Sm 35�+z���-�����%I:,�H�$I�$J�>�ɷ��׃uz.�zt��� ز����.�/�#��q^�&\ݷ5����ؼ$I�I�$I��C�p=�>�?� ���^y �U����xr�
��" �o_����e��86/I��� D�$I�$�`*)
���~*���}�y��Dc���u<0e)[v�p|�\@��yqj\��Û�$I�$I��)�yca��P�-�k���	�:�Ř�d+c&,b��=AI^7lːc�
9�\��o� D�$I�$�@��`�8�:�/�j�������w��`}!w�_��+�P3#��z��G'7!-��$}[ �$I�$I�'��׾�3jCϛ��E����]��o�^�`= �Ia~ҭ?�ي܌�85.IR�1 �$I�$I��v��i���/��t�z%t��s (�W�c3����ՔUD�p}��4�ˈS�$%.I�$I��o�x̼����@:���CnC �*�<;g������� ��"�[p\����]��g "I�$I��uU����{��0�k��������?��=��f{1 ��ep;z��w��$I��$I�$I���F�c����]k�������Ъoe�{�w0z�">X���Yi�׆tnDrR8�K�t�1 �$I�$I��g��[a���:�~p�U�� ��ʭ{����L�x3 5R����\~j2��F��C���J�$I�$D#��mس��B�S�`c�R�:���R����]�� l�S��Ӗ��;k������sm�6����=I�t3 �$I�$IZ�L�	�6�g/��=V΀XBI��B�9���WᏳV����)� �w�|nԎ6u���F$Iҧ@$I�$Iґm�k�⏁X��=�� mC�QP� �h������,eca	 �4����Ҳ�!l^�$}I�$I�t�F�'?�;�����pγ�s>�\����/f��" ֬��r���C��iI��?@$I�$Iґk��U���"��`��,J?�13s�V �ӓ�E�V\xJ3�S�A��$��0 �$I�$IG�O�ݯ�����E�b��ₓ�qU�V��z��$Iߔ�$I�$I:����G������+��b0���8�-Mke�%Iҷe "I�$I��%E0�a��(T� ��N���/���&jk|2�9��M�:�K��o*�$I�$I��H9��=��#�y_~4�J�����t}�'<wy7�I�3 �$I�$)q�b�x<��_4�k	�<?�����yO�(��M�U��������}'���qz�$��,I�$I����σɷ��Y�:���.�� �l.`R�SJ;�%��|v���̍�#���ݲ�$�@�$} �$I�$)��\�n����p�ϡ�5����r�����\Y�Ӣ��m�����N?�MK��� D�$I�$%�};a�}0�w)Bp���{8�6�"兹kyh�2��- 5)DY$����r���<�_�$I՗�$I�$I:�U��g�%����A�;��q �b1�/��]��b�^ Z���A�G��������\6����n{��!$I��� D�$I�$�b1��e�:
v�	���C�ۡU_�ł������+�����5}[sn�&�$3>��	���B6�g�G��tF~�=��hߗ$I: @$I�$I��g��0��`�9@V�ਫ�C8	�����w�^�`=��&���[s~ޫ%9�)U.7���k_���v�ew	����W>�!I��� D�$I�$>�-��#a�?�uJ&t�N��f����'f�੷VRR��uh�����8/�K/�ѵe���$Iҡa "I�$I�����`��0�i�V@('\=�Av] p��{�����l�S
@�fyR��kƱyI� �$I�$��*+�9��[A��`��@�;
�����K�2f�"�n�@�Z�<��G�%�+I��D �$I�$���F�_��wB��`�����Nh~je��E�5~o-�@͌��Ӛ�OjJjr8�K��j� D�$I�$U/+^�ɷ�揂unc�3����PcsQ	�O^�_�}8O
sQ�f\ٳ�)���$�Ha "I�$I����Ô�|j�N˅C᤟AJ: �e<��J~7s%��# |���8�Mj}��sI�t�1 �$I�$I�U�^�X��p�ep��Y�H4�K��q��l�8?�IMn�N{NhrT<��$IՔ�$I�$I����0�70�(/���?�3j��,{s�VF�[��M��&y�<�����sI���@$I�$Iҡ�������[��F]��MN�,[�i7w�_�K�����/��悮MIKN�G�$�0b "I�$I��X�N
�|l[�嵀�������Osl�]S��w��AJR�Nn�/���fFj���$I�I�$I�t�m� &����5�ഛ��Ő���"<��J�xc{˂烎��M�Ѭvf�:�$I�)I�$I�t��Z�^�Iip���Z�Q�h4����IK�TT��kr�Nl���%I��� D�$I�$x�v����;OB�4�;��}+�lRY���m�9n7аfnԎ�W��$�[1 �$I�$INE��x�װog�׬��t�,[�e7c�/f��`zvz2��ՊOiFz��%Iҷg "I�$I���X�
SG��U�^�v��vhݿr���=�<4u)/�]G$#9����pu�6�e:�\�$8 �$I�$��Y�L�>��3��p��#H
>z()����V����)� �_���<�-�dūsI���@$I�$I�7�}L�,z-X�d�)��S��� ԈFc�����;q	
���6�e��NnQ+N�K��#��$I�$I�z�nf|���V@(=o����esVng��E|������0�-������8�$I��$I�$I�?����'����(�k�/��Q�}e�ʭ{3a1Sn +-�+z����p.I�I�$I���E���_a��P�I�W�X�'��YY�coO]�sﬥ"#)��.���ojg�ŧwI�t�2 �$I�$I_n�0�6��a��i�o��΁p�?��jy}9�K��}��3lp;Z�gǫsI�t�3 �$I�$I��eL�&��~-�|��  ��m䞉��d�> ���a�������%I� I�$I��Y�7��w���(�����p�M���P��;�c�">\��z9�\?�-gut��$I�@$I�$I��ُ���@��`��w��(�ݪ�l����z�b&,�@FjW�֒K{��F��%IR�a "I�$Iґ,R���س9�k�9p޴keٮ�2~3m9�7g5���sbc��׆���85/I���@$I�$I:�b�lJ0�c�`�f��W���X�VD���k�ʹe�{��im�p����s��$I��@$I�$I:�l�&�����5�'^�i@0�|�G����Ŭ�Q@�z��2��S�ԉS�$I�� D�$I��#Ůu0�N��_�$��I?��A��*��_����1o�N �d�q}�6|�Sc�p.I� �$I�$%��Bx�A��DJ��c��o���V���Q��3�_����姶��S[���G�$���^$I�$IJT�rx��Ư�x{�״;���PYVX\Σ3�3v�j�"QB!�~�F�זz�8�$I�'I�$I�M,��S;V{��@�Q�vP��(Ͻ����-cWq9 �[����o���%I�I�$I�ɺwa�nN�ά=��	BR�1@,c�Ǜ���Ŭڶ���Y�2���m�
9�C�$�@$I�$IJ;V��Q���`�\N�t�Ҳ+�>\����1w� jg�2�_[~й�I�84.I�tp�H�$I�t8+�3��h9���C��Ӡ�쓝��;i	�����0��h��z�$��$)�'I�$I�G�%0�I�y?�{-�@�ۡ�1�eE%�<��
�8ke���3;6�m��[#N�K�$| �$I�$N�QX�7�v;�����T��G��0w-M]Ǝ�e tmQ��C
8�an<:�$I:�@$I�$I:\�z3p�q~��n �o���$ p>u��LX�ʭ���u2�eP}
�p.I�� �$I�$Uw[�����tB�N͂����WBjFeق���9n!sV��2S��ok~إ	)8�$IGI�$I���=[`����"J��?��n��:�ev��IKx��� �&���{s��ْ���xu/I�W �$I�$U7e{a��0�a(��}u�T��)����y��U�VD8�C�ЖFGe|��%I�� �$I�$U��^�7{N��wB�n�e�(yoNYʶ=���.��>���׌C�$IՏ�$I�$I���0yl�8X�l}F��gA8���Ř�d+w�_Ĳ-��!�kgr�v�o_��$I�a "I�$IR<m�&�+_��p���rHN�,[�����/��� 8*#����漓����sI���f "I�$IR<�����<�p
��S�qd�U�m.*�IKx��O�� 5)�Eݚqe�V��p��$Iҗ1 �$I�$�P*)�Y��Ǡb_�w�Y�g�5�,�[Z��3W���+�W�;��禁�h��sI���b "I�$Iҡ)�yca��PcE�����F��S�����q���l�]
@��G1|H'49*�K�$�@$I�$I:�b1X<����˃�Z���(h7>3�|��`���M�h���̓�1�z8�$I��@$I�$I:X>��o��o�Z�st���3�cɦ݌���K��[#��z�₮MIKN�C�$I�?I�$I����a���o�:9�^	ݮ���ʲ-�Kxp�R���:�1HI
��͸�w+jf�ƥuI��Da "I�$IҁR�޼��"e@�?z��F�)+��7W��+(.�:�7lG�ڙqj^�$)��H�$I��mU������{�dW�ע'���WY��x��O�o�6�;4�ɭC
��,���-I���@$I�$I��b1��e�:
v�	����G�>U��Z�����pc ����M����;�\�$� 0 �$I�$�X�v0�|��`�U/8�������e�w3f�b�/�@vz2��ՊOiFz��%I��p�Pb�9s&���wiР�P�W_}���7o梋.�A�ddd0p�@�-[V�����+���Z�j�����g���͛�Ԭ]��!C����A~~>7�pUjf̘�	'�@ZZ�Z�b�ر�-K�$I:�l[/�O
�L�5~�>�����c��R���~�鋷�q�)�x�^������$I�O��ڻw/�<_|1g�uV��b�g�q)))���'''�x��}��p�B23�A�^{-�ƍ��+������ଳ�b֬Y D"�B�z�x��ٸq#?��IIIᮻ�`ժU2����g<��sL�6�K/�����3`��C�E�$I���l�7����XBa8�B�9��V���G��[�x|�
��ߨտ}]nԎu��ս$I�'��b�nB�)
��+�p�g �t�Rڶm˂8���F�ԫW��K/����B�ԩ���?����= /^LAA�g���Of	|�;�aÆԭ�%�'�ছnb�֭���r�M71n�8,XP���Cv���ĉ�����"rss),,$''� ~e$I�$Vʊa�c��CP�;�k3����v�e�h�W��IK�PX��s>���[ԊC�$ŗ��)�<K�Lii) ���{�p���4�z�- �͛Gyy9}����i׮M�4a��� ̞=�c�=�2� 0` EEE|��Ǖ5��Ƨ5�^���+**��C�$I�,����v��w�G�p�?ἿT	?����{tC_���%4�M�s:��+�~H�$ŉG`��4�6lO>�$���<���|��'lܸ�M�6���J͚5��ܺu�iӦʚφ����k������}��Q�F���7f�F�u@ޫ$I���܊�0yl�(X�6�>#ᘳ!���%\�uc�/f�`naVZ2?�Ւ��5wƇ$IR���III��_�K.!//���$���ˠA��'�6��C�V����hܸq;�$I�t�m�����S�uZ.�zt�)���i��{Jyx�2�{g-�h��p��4�꾭�����%I��Y :�:u�����),,����:u�p�I'ѹsg �իGYY�v����͛�W�^e�ܹs�\w��͕�}��O�>[����O ������_T$I��#R�x}4�bQ�����i7BF^eYIy��o���������}�yP;Z�gǫ{I�$}�Enn. ˖-����;� ��$%%�iӦq��g�d�֮]K׮]�ڵ+�G�f˖-���0e�rrrh߾}e�����sʔ)�א$I�$ Jwì���G�b_����;�ZT��b1^�p�L\��]A��r>��SZՎC�$I�* :��������+׫V�b������ѤI��׿R�N�4i�G}��W_�g�A���� ��K:t(yyy���p�UWѵkWN>�d ���O�������{شi��z+W^ye�?���x�G�����⋙>}:/��"�ƍ;�_I�$I�O��f���[���'A�;�q�*��������] ��I�m9�cC���!n\�$I�� D�{�G�^�*ן�Ը��;v,7nd�Сl޼���������n���5|�A��0g�}6���0��{�����$���r�WеkW233�������+k�7oθq���ky��iԨO=�8�_I�$I�Z,K'��mI�����

N������r���L�x �I\qZK.�т�8�$I��B��0}Z�������ͥ������x�#I�$��Z�>L�ּ�k�Aϛ��O 9��l��2~3}��YCy$F8�؄k��&?;�K..I�����)�|D�$I���v���w�G�Iip��c(��V��VD���k���e��{���-�hS��$I�I�$IRbڷ޼�y"e��q?�޷B�ƕe�X�qm���nG0�]�l�)�G�:qh\�$I��$I�$)�T���O��{`��`�����hСJ�5;=n!��@~v��o�ٝ��sI��Ú�$I�$)1�b��U��+ع:ث�.>Z��2�|��b~=q1�>�@��$~zZ.�т�4��,I���S�$I�$��vL�>y7XgՅ^�@�A���[X\�#�/㙷�P�
��;5��m���sI��Db "I�$I:|m_SG¢�8�p�U��UYVV��9k���e�*.�G���2����9��\�$I��$I�$��w��kx���P:^<��]��,�1��M�=a1��Цn�.�6u���!I���@$I�$I���}0�qx�A(-
�Z��~�C~A����v1z�B�]B�����~m�A�F$'�u�$I:�@$I�$I�_4
��O��z�B�;�E�*��vs�%��� �S�\֣?=�%Y8�$I:b�'?I�$IR��rL�6�+X�4�>���?����(*)��ח���ՔU���؈���~n���.I���1 �$I�$UO[���lr�Nˁ����W@���H���Y��Ӗ�co ][�b���i���%I�T�H�$I���ݛ�������X����8�FȬ]Y�Ř�hc&,b�ֽ ����-���.��$IG8��3�P�vm���7���~�;ڷo�/�@ӦM�ܡ$I��#B�x����� Р���WP�U�ҏ>)d����Y��Z��\ӯ?<�1)8�$I��b�x7��j۶-�?�8�{�f�����ۗ|���$''���/ǻŸ(**"77���Brrr�ݎ$I���"0��੏=���F'Λ�\�tî}�;i	�|����0�vo��z�$'=�Pw.I��?_S���X�n�Z�M�ꫯr��gs��ӭ[7z����$I�$%�X,��1el]����
ڟ�9�jwI9O�����\EiE�3:4����hX��$I�<�������iҤ	�'Of�С ����o߾8w'I�$)!m�Sn�U3�u��ഛ�Yɩ�e�(~wM]ʶ=���.��uH�5�y���$I�a� D��׏K/���;�t�R��L�f��ۜ$I��ĲkL����`��
'�zB���b��dw�_��-{ h^;������8�$I�W2 �>�(��z+�֭�o��j�`޼y�{�q�N�$IRB()�7�9�C�4�;����68�i�ҏ7r��E�Z���2R��Ok�?���%I�����/�g�6m�T9�H�&I�$� �(�yOÌ�aߎ`�iw�4<�J������	��&��I�f��W+rk8�\��Í��)�|D̜9��,X�ȑ#ٺu�!�H�$I�a/�E���_����^�6��vh3�ʀ�<��
~��JJʃ��=�7hK㼌84/I��D` "z������P��~����I�$I��usa��`�Yz�.����54���{��R��	�����(nR@�&G}ѕ%I���f "v��Ye�DX�b�_=ݻw�SW�$I�;�W��Q����:��rt�%�eW)}c�V���%�wдV7l��c�9�\�$I�3@���ϟO�޽ٱcG�[��(�$I��S�x�x�)��!�x>�9��.�T��q�xs�6 rk�pU�V��k3R�p.IR"��5śO��K��aRSS�݆$I��ꪼ�>	3���`�e�`�G�c��n)*�)Ky�uDc����]�qU�V�����$I:�@Ŀ�����m޼��o���/�����wܡlM�$IRu��`�P�6ث{,��Z��RZ\V��g��ə+(.� 0��z�4�Mke��%I�t�,�	�B|�/�O_�BD"�C�]����$I��V̈́ɷ����:����;�I�e�h����	�O^��`�y�&5�uH���šqI�t������'@ĪU��݂$I���n��2�N֩���8�琚Q���e�=~�6���4��9���%I�t����M�ƻI�$I����0c��'�E ����Yu��.ݼ�1����� d�'sU�V\xJ3Ғ����$I�Ac "I�$I������#0�a(������n]�t��R���?�]K4��?:�)��Ӛ�L�K�$)>@$I�$I�����`�hس)�kpMO�R��,��Z��3V����]����E��Cݹ$I�T��$I�$	b1X>-����`�f�3�>����h4ƫ��s�%l,,�F�\�I-jţ{I�$�s@$I�$�H��_0�6X9#X�ׄSo�.�ArZ���+�3z�B��7�Y����5 v��$I���FY�|9[�l!�Vy��SO�SW�$I����0�N�� I���r�qd�U)]�ewOX��E[ �NK��Z�n�HOq��$I��1g��;�<֬YC,��Z("�ĩ3I�$IEI�zf?
�Vs6�G5�R�}O)O[�s�%��q^�&\ӷ5���>wiI�$��0 ?����ܹ3�ƍ�~���B>�.I�$%�H9�3��m�^�S���ШS�Ғ�O�Z�c�/gwi }�yP��p.I���� D,[���^z�V�ZŻI�$IC,���ԑ�}y�W������|T4����=��~�> �n���!�Ҳv<��$I��q�I'�|�rI�$)}�L����������"HJ�R:w�F�[ȇ�P/'���̎p.I��Î��ꪫ���شi�{,))U�t�q�ũ3I�$I�؎U0�v���`��]��n�@zN��U��r��EL�x3 ��I\ѳ%�toA�T�K�$������kq�����B��X��^TTDnn.������|�O�$I����0�>��;��!�p������[��Ӗ��5TDc�C��8��N�O��$)a�����'@ĪU��݂$I��o��4=f�%�V����z�V)-����۫�����.	��l[�[Цn���\�$I:(@DӦM�݂$I��o*��i�`��`/�}|���_�1�}��_O\̺���v��>������%I���� ���k�1h� RRRx���g�駟~���$I�����8��~�ήu��<W��1o������ ?;�������sI�$% g����0�6m"??�g�|� �Q(I��jh�2�2��֩Y���`�yjf��5��r��%��h# 5R���i-���d��=q�$����5ś�=BE��/�wI�$I�؞��������@(	:]=�AV~����r~;}��^My$F(?�Ԙ���!?��$IJ| �$I�TݕÜGᭇ�lw��f�u�V-���s��i�(�W@�ֵ�ep���KI�$9@$I�$���F��?��;a��`�~�'4�Q�4�1q�&�5ۋhS7�[гm>�$Iґ� D�$I�����`�ؼ X�6�>#������}�v'��-�5;����u����N�HN���$IR"3 �$I���dӂ���}�WU��L�H�I� ���`�P���j]�����
(ⶶ*��u����Z+�Ze�,E�� $ +ag����j4�
��f����~����9<�}�9�H����81z������{wlؾ��W���HwH����qW�܌���uO�$I�?K�$IRi��	���	�~=�A嚅�f��婩�y��O��
���5��>�P7%):�K�$I��H���}�k���(Q�$I*6v���YO@޾�\�s��]P�BKs������˻�ر7���I�jq뀖���RK�$I��HU�zuB��a����/�j$I��
(?>~	���=_D�v�lpްS��A0y�f����[� ptjUnЂ^Ǧ����$IREb RAM�:���?��Sn��f~��_ҵkW fϞ�K/�Ĉ#�U�$I�T>���[WF�j�g·E���ޱ˘�n; ��$0��c��Ćnp.I�$}�PA��Pt�v�i��׿��/.4��+����2mڴ�e��٤������k�$I�T46~���fF�I5ᔛ��_A\B�;����弹 ��yb\Wuoʵ�4�Z����\�$������ DT�\��Ҽy�B�+W��C��ݻ7J�E�@K�$������#,y=2��]���C�R�;v����ik���u�pn�����X�Ww�sI�Tv�����W`����s�1r��B���_iذa���$I�ʁ};ཇa�3���kw�z;T/��v^~�}��?O^ɶ=��������-iנz	.I�$�} ��G����g���t����s�j�*���D�:I�$��ˁ�
3FFB��=��?A���A���[�o�2�|�����U��No���$Iҏ�+���x��Y�|9 -[��k��� ��I�$�|��{7��42W�%��Gh~�A�/٘�}�1k�6 jT�gp�c�E�FĻ��$I*��~M�f "}���$I��l6L�6~WM�^�A�K �p�}F�>������� ���~ս	�=�hR���\�$�~��h�X����g�a�ڵ�=��������M�ҽ{�h�'I�$�^[W�;w��1�q|e�v=t��Z��@�L_�s�end��3��㦾�Ұf咮\�$I*�@���.��2.��>��c8 @VV��w�ƍ�r��$IR)�g+L >z�y����A�[�Zz��y�aF����'�d�����'4��m[ұQ�hT/I�$�{ �{�aԨQ\~�����ݺu�{�be�$IR)��>x
f�dG�����Ԗ-��"����ͻh\�2��oA���np.I�$#�b�
z��y�|JJ
;w�,��$I���(�E��)�@�瑹�v��8�䃖/���q�xo�V R����i͹�Kc���\�$I*n "==�իWӤI�B�3g�䨣��NQ�$IRi�vL�2E���;��� �p��9{?�LZ�k�6⊮M�ݩ�I���$IRI1 ���o����y���	�Blڴ�ٳgs�7r�wD�<I�$)z6/��w��ɑqb2�
�����BK����쌵<3}-�r�ض.7�;�Ƶ��t�$IR�g "n��f��0��v{��gϞ$&&r�7���.��I�$I%oW&L��Ab�������P�V���������&�`ˮ��U���-9�q�hT/I�$	AD��999�^��ݻwӪU+�V�풢*;;������HNN�v9�$I*	vì�a�c��72��,���������{�.cy�. �Lbx�l[��%IR���k�6;@T !!�V�ZE�I�$���������{sd�����u9h��ͻ�o�2����j�����͹���$�Ŗd�$I����ؿ?�?�8S�Ne˖-���B�?���(U&I�$� �U�"�||�<2W�i�����.�/v���+����	Ⲯ����ͩQ%���$I���@�UW]ŤI�����ԩ����$I�6-�I�ç�E�I5"{|�p�3�������2j���D68��:�����im78�$I�J#1f�ƍG�nݢ]�$I�T�vn�)�E���c���A� �z���p��o䡉+���@�)�6������$I�T������S�Z�h�!I�$�};a�#��(�?�k�38������l�ޱ��dS6 ��'qS�c9�]=bb욖$I�J;���3|�pF�E�ƍ�]�$I�T��r��a��o{d�I8��P�����޲�����- TK�㷽��WݚP)��%I���� D�p�	�߿���:�ʕ+_����ۣT�$I��,{��l_��}��'8��A�o�}�����W�'?�΍����Ԫ�X��K�$I�I@��_�ƍ���HKKstI�$�}�F68�0'2��
�n���Cl�����������5�>�@�i�ܿG�V-��%I�$1k�,fϞM���]�$I���l[��K��W���A��Cb�}��့n���+ظs m�'s뀖�ԬvIW.I�$����-Z�o߾h�!I�$�x{������_!������6H�{��9k�q�e,�<��)���X��P��%I��r� D����p��{ｴm���=@����T�$I��r�ÜQ��#p fpt���i�Z�����?~9��n�JB,מҌ��ER��K�$I�I(� �E(�bbb ��#B�����(+겳�III!++�H�$)Z����,ؽ��A� &�aX�:��G��Y������z�i����wW�����	�E�1��1ԩ��$I����mv���S�F�I�$�`K߂	�!{��s���+`�8�X��\}8�vh��H8��s����Oy|�jv�lp���:�:�%��
�	"I�$�|�D�&Ԓ$IQ��-x�r�{���Pz�.����B�� `̢����wD��k�^����{s78�$I*	~��h�D̘1�{���ٳ�*�$I����j�p�?���}�������3v6� �Z"7�=��k@��K�$I��8�S���~ uI�$E�g�
���Pr���U��϶������$��	��_�f��gS*'�WI�$���obǎ�ƹ��̟?�;{�7JUI�$��ڽ����ܛ��SV��ٟ�����g'4d��ǐ�\��$I�T��������N?�t:t(��͋BU�$I��삥o�Ҝ�:����<>e5Y�r�Ѽ6�lI�t�1-I�$Ut �Niii�X�"�eH�$�"X>��썑)�P;v�؟�F�����e �V�[���c�\͒$I�J5�hѢB� �������C��)J�$Iǎ�`�M�rBd\�1���sԲQ�7�- ��.����TK�ӏ�����$I��B@D��BAPh�K�.<���Q�J�$I�^~.�~�= y� &�]O~���ٴ˭�]���>�I-�ν���N\w��\{r3�$��I�$I�o
bݺu��111ԩS�J��0R�$I���0f|y�����@�c��fY�ɠ��@��夲�-Tgn�ab �֬��$I�����D�ƍ�۹s��$I�����0�N���ȸr-�s��B�WXmٵ�`y�>�:䩾�N�$I��-&�(�x��������Q�fM�ׯ��X�$I�ʍ ���'|~w9\�t�EA�P�r�a�2���Î$I���f "F�EÆ�<y2�'Of	��ߟaÆE�:I�$�y_��π7���� �\9�z*�,�t��,���{O�T�SӚ߻N�$IR��+�DfffA 2f�~���ѧO�4iB�Ν�\�$I�ʬ����C��c΅�$8�f�:b�/����U<5m�ဪ�q�>�G���>���lElLI�$I�.v��5j�a� &L�@�޽�����h�&I���j�;�Tx��H�qL?4�>(�X�1������SV��6�i�NaԥǑ�R�5W�)�x����צn	ތ$I����q�y��_���͛�m�6�������9�裣\�$I�ʔ��p3,}32N���g��"]OLYœ_v}Ԭ����n��v�p�_����*��붳e�~R�E^{e�$I���a "}�Q�4i9r$U�V ##�����Q�N�$IeB8�>S]��.�F^y�X��K6fq��,���������6Ԯ�Xh]lL���j��-H�$I*_BA?�L�x���III!++����h�#I�Tzm������q���G�n������g��v�J�fI�$;�_S��" V�Z�ԩSٲe�p�б;�3JUI�$�T۟����@b
�������෻>��I�O���!I�$IE� D<��s\{�Ԯ]���tB�x7s(2 �$IRaA ��&��7G�����USZ��扩�yj�j��5*��s���!I�$�X��{{ｗ�ÇG�I�$�v����aͻ�q�fp�#p�)�\nׇ$I��h1 ;v���/�v�$I*������{A�~�M�7@��!��A����ǳ�pF���:�%I�$����/��I�&q�5�D�I�$�F�f����mUd|�)0�����?ٔō��,#��C�$IRt����>�;>���m�_�����(U&I�����L��+2��
�F@���]v}H�$I*MBA�.B�մi��<
�X�vm	VSzdgg���BVV����.G�$���0��0�.ؿ�	W�iwBR�C~��]�ZG�>�T��C�$����5E� bݺu�.A�$I�E�3>����3�N8��0ON]͓v}H�$I*e@T�WA�eU�$�����F�� ȇ����6�t5���v}H�$I*�b�]�J�����mۖ��$���h׮���?�]�$I�J��q�dg��x$�hy&�]{��#'/̣�Wr��,#���y��<}�q��$I�J;@�#�<�w��u�]G�n� �9s&�\s[�neȐ!Q�P�$I�b�?V���S����~���ow}�m��=�5��$I�T�	�hڴ)w�}7�_~y���^z�?��v�7i�$I�V~.�SG@�����~=�AB�C~$'/�S�V�Ĕ������6��^�$I�~��h�Ddddp�I'4�I'�����$I�Tl6̍lr�yIdܨ+��(���Ώ��!I�$�,2 G}4�����zk�����4o�<JUI�$�H�����'Հ��.��Co���ɩ_w}T���g�������$I�T����ﾛ����̘1�`����w�}��^{-��I�$�'	X�L��n��u�$~T���[�)�G/d�]�$I��(q���3g�}�Q�|�M Z�l�ܹs�رct��$Iҏ�uU�uW���>�x�t�Ώ��!I�$��pt�;�I�$I*�r���G`棐�q��䛠�� .�;?fׇ$I���߯)�� �ƍ#66��}���8q"�p����G�2I�$�����`Ǻ����a��P��w~$7?�SS����Uv}H�$I*7�ۡ*��o������� ��o�BE�$I:b�2��+���"�G��p�Kp���?�n���'���wV���*�ICzrv����$I��4;@ĪU�hժ�A�-Z�`���Q�H�$I�-�=��dC(:���*}�k���$I�T�����֮]K�&M
ͯ^��*U�D�(I�$��M"��o�82����3���[����M��>No�ƽ�!�Z�b-W�$I�J��8��<x0o��͚5"��7��Yg���$I�t���0�>��aHL���������Xn~���E�>r����$I�T����#Gү_?Z�hA� �����ѣ=�P���$IR� ����	7î��\���}P-�{?jׇ$I���� D���0k�,&O��IJJ�]�v���3ڥI�$�+;>�q�`դȸFS���{?����x�x�]�$I�ʿPA���J���lRRR���"9��7�$I*Vy90�q�� �탘x�>z�����貌l����%���$IR���5E� �$IRi���0v(|�<2n�>u��ޏ����Zsv�>$I�$U �$IRi�gL��W�������>$I�$)� D�$I*-�aX�O�|���;��p�]P���~ԮI�$I*� D�$I*�,�1Ca���8�5��(4���]��͍������2���mCj�]�$I�*.�f�^x�֬Y�_��RSS?~<�5�u���.O�$����3F¬�!���[�˵����3j���C�$I��}ӧO�m۶̙3������޽��r�]wE�:I��rl�Dx�3�|4~;ͅn����cyf6�>�>O^In~@�iLғs:�7��$I�$@�|���s�=L�<������SO=�>����5c��<�L�Ջ�_�o��f��w��뮣A�$%%ѪU+F�Uh����4h�jբjժ���l޼�К���3p�@*W�Ljj*Æ#//�КiӦq�qǑ����G͋/�xD�"I�Tl�6¿/�W~;�Cr�������{?���)�8��,٘MJR<���=�]~����$I��o0 �/��s�=h>55��[�ѹ���C���y��'y|�СL�0��_~�e˖1x�`���:�z뭂5C����f���L�>�M�6q�y����g������0k�,^z�%^|�E��΂5�֭c�����Ջ0x�`~��_3q��#�I��"�����';���!'�́��_u}<4髮�T&�ɹ��!I�$I�� �z��dddдi�B���ϧ~��Gt����ӿ��<>k�,���
N9� ���j�y��Ν�Yg�EVV���x�W8��Sx�hٲ%|�]�taҤI,]��w�y���4:t�����'����5jM�6���e˖̜9�G}��}��=I�$��������(2n�)��yz��hn~�g���/�~����j�9|ݕ$I�$};@�E]�������$
�y���������ˋ�Z'�to��7n$�N��ʕ+�ӧ ���#77�޽{|�E�4jԈٳg0{�lڶmKZZZ���}�����'�|R����j�W�8����]�$I�O�o'���zZ$��T��\9������$I���q�}�1h� 6lH~~>�Z�"??�_���~��Ez�������GLL�=�={� 33����W�^�siiidff��f����}ߚ��l���GRR�A��1��ﾻH�S�$� �%��	���-��vA�{�j��x^~�Q���H���j͹nr.I�$I�� D$$$��s�q�w�d�v��Mǎi޼y�_����>୷ޢq��̘1�A�Q�^��:6J�-���СC����4l����J�$Ҷ5����S#�Z��G�i������]�8z!�7fлe*����M�%I�$���@�F�hԨQ��߾}�z뭼����]�v,X���z�޽{���NNN;w�,��y�f���HOOg�ܹ�νy��c_��o�INN>d�@bb"���Er��$���; 3��=� 6z�ݮ���9îI�$I*: "^�u�N�ʖ-[�Å�����-����撛�KLL�gbcc�y���ϻ������+X�~=]�v�k׮�{�lٲ���T &O�Lrr2�Z�*X3nܸBי<yr�9$I����i���m�#�f���V������>Nk��}�%ͮI�$I�Q@����y�g�իiii?��.ܽ{7�W�.�[��P�fM5j��'�̰a�HJJ�q��L�>�����<��# ���p�UW1t�Pj֬Irr2�����ڵ+]�t�O�>�jՊ�.���#G������ΠA�
:8����x�	n��&���J�L��k���رc��$I�!��o�ůE�UӠ�h}��Uy�a�����������]�$I�TDBA�.B�U�fM^~�e��5m�4z��u��W\��/�Hff&��r�&Mb���4nܘ����!C������p���_������ۗ��z���V �}��^{-ӦM�J�*\q��������eȐ!,]��p�w��_���%;;������HNN��)�$�|
����?��, �~���R�+7G�>}nׇ$I���_S����M�2~�xZ�h�RJ���$I�)s1�����3���?�����3[s�qv}H�$����5E��������y���s�pI�$vô����CB�H�ǉ��������]��He�]�$I�T�@��~�3������J�&M���/t��?�Re�$I�D��0�&���kuNd���z�u
�>$I�$�d��+���y��q饗��M�%I�ʝ��a�M�r|d\�1x��sا��C�$I�J��;v,'N�{���.E�$���υ�O�� w/��C��C�!��a���]վ��8߮I�$I*v �aÆnB$I��M�?�lr�eid��$8�QHmqاX�y�F/d�7�>�;�-�)v}H�$IRI0 ?�07�t�F��I�&�.G�$)z�n�w�'Մ>�@�_�avl��!I�$I������Kٻw/͚5�r��m��}��(U&I�TB� �&�{�E�:^��*�<�Ӭ�r��>$I�$)�@ğ���h� I�=_��1C᳙�q����]5�zا����{k��d�>$I�$��0 W\qE�K�$I*y��`�C��_ �qIp�p�2��4����ulF��ήI�$I�2�
*;;�`������]��$��Y���v|7���������V\p|�>$I�$�0 ��jԨAFF���T�^��I��P(D~~~*�$I*�0���ȸZ=0Z�q؛�×]�/bᆝ�]�$I�T�TPS�L�f�Ȇ�S�N�r5�$I�,������Pt�z����4y�a�{o�N^iׇ$I�$�r ��'�\��M�6�aÆ��=6l�PҥI�$�M������ 2�|d����4v}H�$IR�b "�6mZ�:�oھ};M�6�X�$�lڟS��� �)��N8�W{ا)��xg%9yv}H�$IRYa ���>�m���T����(I�ʘ ���1�؝�k{!����ѩVo������8��:�8�-uS���hI�$IRQ3 ���
@(�;�r������3g:t�Ru�$I?���0n�~'2��>�z�i��q���ЮI�$I*3@*������ŋ���Pp,!!����s�7F�<I��×w f=3���� ݇B�!d�v}H�$IR�` R�M�:�_��W��/!999�I�$��΄1C`��ȸ��0��}��&?��{kyd�]�q�q�]�$I�TV��^x!�%H�$�=[a���ȸJ�;�^ GX�޲�G/b��]'S��Ϸ�C�$I��2I�$�-�0��L���Bp¯�;!���ʮI�$I*�@$I�Tvl�$�s"㴶pƣ���#>��-��q�B�>$I�$��2 �$IR闳�? ���p�W�So�N��G�#m~8����ov}�ъO��C�$I��I�$�n+�øa��!2nq� R���1⼶ԫnׇ$I�$�7 �$I*��>���a���8�	��?�S��!I�$I��$I�J��<�3
���{ &�^'�	U��t���f����~' =����v}H�$IR�g "I���cÇ�M�7/��v�3���G|�Cu}�~FK~vBC�>$I�$�0 �$IR������^H���:\
11G|:�>$I�$I �$I�� �ţa⭰��\�K"�G��G|��p��f��Iv}H�$IREg "I���غ
��u3"���F^wդ��:�]�$I��o2 �$IR���3���B~�U�����C\��ήI�$Iҡ�H�$�䬙co��k#�{À��f�w�/v3l�B>���G��<p~;�>$I�$I �$I*�6G��X�zd\5���΁ѥ�x~�:���ya�&�q�����D�>$I�$I �$I*>�|����G8���t5��*%��S������Q߮I�$I�7�H�$�xd,�1C`�ȸ^G8���?�>$I�$IG� D�$IE��.�z�A��iwWAL�:�/vs�님����I�$I�3 �$IR�X�6��6E�Z�}��?ꔇ���m`K.��C�$I��@$I��������&F�5�������?��k���0�>$I�$I?��$I�~����L	y� &��7@��*��/���'��!I�$I��@$I���|6��/�E�Mz��G��1?��v}H�$I����$I��̞m�Ν0��ȸr-�s/��~d��]�$I���f "I������t;���;�
���\�G�v�����E|dׇ$I�$��H�$�mYc��g�GƩ��G�Q�}�ow}TI�嶁����]�$I���� D�$I�-g/�xf=�<����]~��?������~tm�?�-jT.��%I�$I��$I�m�$w�\����~�)���$I�$�I�$��	&�K�'7�-��Ӯۺ�a���!I�$I* �$I��σ��)�@�n�B�k�[ ��?�]�$I��(0 �$I|>���E�q�#�����I���C�$I�- �$I��,x�O��_� *�@��+ &�G�6xa֧<8q9�s#]�l�/:5��C�$I�T"@$I�*� �%������͑�v?�>�@�ԟt�u[�p�����H�G��k�������$I�$�(I���f�w#���:>G���Nkׇ$I�$�41 �$I�(����A��M��7B��!.�'��ӭ{������kGÚv}H�$I��� D�$�"X;��m�#�z����V��t�p8��Y�2ҮI�$IR)c "I�T���&���WI�~#����
�>$I�$I���$IRy��/�;w��, '^��I�����e@K.�lׇ$I�$��0 �$I*o2Ø�����8���ghp�O>��[�p�님��v NjV�η�C�$I�T��H�$�vô����CBU8�v8�7��~��v�G�Xn��C�$I�T��H�$���¸� ��ȸ�Y��H���Omׇ$I�$�,2 �$I*�v����aŸȸz#���'��P]�h�%�cׇ$I�$�t3 �$I*��sყ`����b���C�a���;3���$I�$�u �$Ie��90fl�$2nt�����ɧ�^��)L��C�$I�T��H�$�{��;��_���jB�?A�K�6"�l�������"]]�������$I�$�M �$I�]�����`���\�K���J��|�p8��?�	+ؗ�oׇ$I�$�\0 �$I*;X	c�§�E�uZ��G�I�"9�]�$I���� D�$�4���=3��\�K��o���A\�O>�!�>����΍���$I�$� �$I���w`����ȸy� �hR$��l�nz}s����rTM���]�$I��r� D�$��ؕ	n�O�W����g�&�v}H�$I�*I��h�Ç�)������@�[!�Z�\®I�$IREc "I�M��Ø!��;��3�m_$�?T����[p�]�$I��r� D�$)�g��{a��!1z�	��
bb����e��u}�<�=�j��!I�$I*�@$I�JR��7a�Ͱ;32���{TK+�K�����3��ܮI�$IR�e "I�TR���q�`��ȸ�Q0�ahvj�]®I�$I�"@$I��[^�zf<y�!6���C!�R�\"xyN��coN>I��2��I�$IR�e "I�T�>�	c����qӞ0��ݼ�.�~�^n��B>X���ܴ&^`ׇ$I�$�b3 �$I*{�¤;`�+�q�:�}>�^����8T����[pY�>$I�$I2 �$I*J�0,x&�	�vD�����j�e��1�v4�U�Ȯ!I�$IRYf "I�TT6/��Ca���8���(4�Td���C�$I���c "I��S���#a�΃�*��V�|�ݏ[��e��v}H�$I�t8@$I�~�`�0�Z�8�? )��v}H�$I�t�@$I�~���0�&X>&2Ni�GB�Ez���r�님�v ����A�>$I�$I�A �$IG"?�>S��������!��B�p8��s>c�7�>��;�˻6��C�$I���` "I�t�>���G�;G69Ok]����C�$I���� D�$���	��>z�Ru8����2��)����!I�$IR�1 �$I�.A �_�����/"s�}�Uj����$I�$�h�H�$���0v(���jy�U�Ez�p8��s�3b�2�>$I�$I*B �$Iߔ���3��0��@\%�y#��{�K,�K��Ѥ&^hׇ$I�$IE� D�$�+k���`��ȸ�i0�!�yT�^��]��cޯW��!I�$IR�1 �$Iڵ&��GG�Uӡ�h}.��6�ذ}/����Yk���yA;�Զ�C�$I���d "I�*�p�=��d!�t5�zTJ)�K��!I�$IRI2 �$IS�"36~�mg��W䗲�C�$I���g "I�*��`���4aH���'�bb��RA��9���=_v}�Է�<ɮI�$I����$I�� �����!{cd����w$�-����!I�$IRt�H���o�g0�&X9!2��<�{�����$I�$�t0 �$I�W~.�~�= y� &�]=o���"���;"]﯎t}�ؤ#/hOS�>$I�$I*q �$�|�lvd��/�Eƍ���@�c��RA�����7֮I�$I�JI�T���������+ׂ>�@��!T�a�]�$I�$�N �$�|X�
L��m��w9��*�,����1�ˮ�X�>$I�$I�:I�T�}�"��ޏ�S[��B�.�r��w����,f�� �и^hׇ$I�$I���$I*�r��{���A8������ ��/����!I�$IR�a "I�ʦU�a������~�$�h\,���C�$I���� D�$�-ٛ`�Ͱ��qr�H��b`�lr������-c��<�b��X~խ�]�$I�$�b �$�l����`�=��B���Z8�H�Z,���C�$I���� D�$�~?�1�!cad\���&�u������$I�$��3 �$I����H���� S��]p�� &�X.�q�>n��"�[��8�q��G�)�.I�$I�T<@$IR���a�-�{sd��Ϡ�P5��.���w�]�$I�$� �$�tٶ��k�D�5����Q��%���$I�$��1 �$I�C�x�1�� ���D�qt��+�%���$I�$��2 �$Iѷn�
�VE�G��Z͊풇��yA;���!I�$IR�` "I��g�0�vX�jd\%���6�C�x:0���$I�$�b0 �$I%/����w���@N�
N����e���$I�$��0 �$I%+s	��ύ�����'�%� ��n��>$I�$I�0@$IR����F�� ȇ����6�t5�ߏ$���8�Qu���]�$I�$�s �$��-�o���q�3���R��.y����˕����$I�$�"0 �$I�g�?V���S����~�z�M;�q�3c��]�$I�$UD �$�����OG^y��b���Aϛ �r�]6^�h��Y�.�>$I�$I��@$IR��07����%�q��pƣ�ڲX/kׇ$I�$I�&I�t�����,ؽ��A��@6����bdMR8�O����)�R���$I�$I�b "I���ҷ`�p����\�΃�]�q�K��?B�Z�Zʦ���忋��e�G�F�yȮI�$I���$I:K߂�.����wD�Y���WhҭX��v�GB\7�9���eׇ$I�$I@$I��
�G:?�~|S(��kY���?��>��=G���!I�$I��f "I��g�
���P�7F�5�Q����}Ο�,��C�$I�$� I���ve¬�o���E~y�>$I�$Iґ2 �$I�mǧ��_`�ː�sx���Vd�?T���ï{��!I�$I����$I:ؖ�0�QX<���\�N�}��Ρ�	Ar=h|R��`ׇ$I�$I�)@$I��6~�=��|=��4�qC$�X�6�v9�p�e7F��!&�'���}���߮I�$I����H�T�|�~$�X3����gB��P����Z�?�;L^xC��z���Y?����}����L[���а:]؎�S����J�$I���� D���*`��H���\(�^݇@j�C��Y�b |6+��yմHw�O����C�$I�$5I�*�p>,{+|d.���&@�K���P���#&��(�r2��s�1ծI�$I�T�b�]�ʗ3fp�gR�^=B�o��f��P萿|���5۷o�K.!99��իs�UW�{��B�Y�h=z��R�J4lؐ�#GT��ѣiѢ�*U�m۶�7�X�Y�ʌ�\��2<�	F�2~�W��~���^�QD� ൏6p��ә���b��^����$I�$I��� Q�ڳg�۷��+����;�xFFF�����ꪫ8����.��222�<y2�����W��ꫯ�W^ ;;�>}�лwoF���ŋ���+�^�:W_}5 �f���/fĈ�q����+�s�9|��ǴiӦ$����f=Y"s��C�k���A�%^ҷ�>�7���v}H�$I��"
� �v*�B�o���s�w�9�sصk��. ˖-�U�V|�ᇜp�	 L�0����S�^=�~�in��6233IHH ��o��7�d��� ���?gϞ=�3��Z]�t�C��5�����&%%���,����o�$E��l��o0�I�	��
']'\	�%6A���>����c������M���1U�$I���_S����ټy3cǎ套^*��={6իW/? z��MLLs����s�e�����ٳ � �۷/<� ;v�F�̞=��C��^߾}z%�$�K{����a?+2���_.��JQ)ˮI�$I�T�@5/��ժU+�����LRSS�����f͚dff�iڴi�5iii�jԨAfff��7�|u�C9p� (ggg����h�����y/@���\�c��Ph{��G����>bcr�1���]�$I�$���(j��y.��*U�����m#F����v�t䶯���^����\����Fhq�D/d8T��C��y�]�$I�$�x�(*�{�=V�X�����B����lٲ��\^^۷o'==�`��͛��j�Ck�:~(��rK��feggӰa�#�3I*A����G`� G��=o�f�A(�҂ �?o��?��C�$I�$E����o��<�۷/4ߵkWv��ɼy�8����2e
�p�Ν;�������%>>�:�ɓ's��R�F��5��.�.8��ɓ�ڵ�w֔��HbbbQަ$����{Ê�_�}:�
�O�^]_���ϭo,f��H�ݾA
]�ޮI�$I�T�@T�v����ի��֭c��ԬY�F��ΊѣG������-[ү_?~��0j�(rss���袋�W� ���/��ꪫ>|8K�,�/��>�h�y���zN>�d~�aȫ���G}ĳ�>[̿�TL� >}/|����dZ�=n������Ζ]�I�V�NMk®I�$I�Tj�� �]�ʏiӦѫW��毸�
^|�E �}�YLFF)))�ݾ};�]wo��6111���<��cT�Z�`͢E�4h~�!�k��w��Ç/t�ѣGs���駟ҼysF�ɀ�^���III!++�������$� ��"���F�b��ϡ�`�sL��4aIw������s��IMNd��l��I�$I�߯)�@���В�*���3��K"s��p�����P�QTʚ�$�k_�����!.&��>�pu�����$I��
���m�K���$/�	>����%T���.��ZZ�J������? jTN��z6#6&z�K�$I�$��$I�C�^���0�1���K�]~�~��(��n{��^��0w�v�6�UBUI�$I�$��$IѴ?�><{�E檦�I���	�U���%�@^>��ʨ�kk��]��H�$I�$�I��a��H�1�98�8�ꍡ�`�p	�%F�����L[��d��-�:�w؟M�V�+�$I�$I:< �$����a�0�E�����z� �σ����yρ<�����řL]���9��ғ+ѧuce�cO�!�	�)��Դf��,I�$I��]@$I*	��D66_�*�s#s�:B��������2e��-�`��/8�.8V�zڦӯM]:6�NLL�����ڗ?&�B���<���Vn�.I�$I�JI��S���|�_�MzD:>�:B%�ܛä����$�������u�ѤVe���K�6鴭�B�[��kS��/=���^ZhC���J�uf+���[b�!I�$I��}@$I*>����㿞k�7|4�\��l�}�I�lf��f��F^�����U��&��m��"��A�Ƿ�kS��[�3w�v���Oj��k����$I�$I���$IE%`�t��|�ޗ�!h}.tuەh9���3�L�-�`��|#�e�d�I��t�N�v�玍	ѵY�"�V�$I�$�h�H��S�ÑN�����"s1q��"�6j]b�lܹ��3��$�y�w|#�h� ��m"��jR�J��$I�$I� �$�X�y��=f>[�F����+��uP�a���ٶ=�_����,�<�б�נ�t��N�a��%R�$I�$IRi` "Iґ�; �3�;�E����_C��B�:�^��-���$�q�3Y��]0
A�&5ж.}[���R��k�$I�$I*�@$I:\9{`ދ0�qؕ��\�\'���ۥ� `��]�[�Ʉ%�ܼ��XlL��Gբ�t��J�N��b�C�$I�$��0 �$���s�
<��G�Ճn���.����O#>ٔ͸��_�ɺ�{
��ǆ�~tm�����ҨQ%�Xj�$I�$I*�@$I�.����'�ÿAή�\���}Hd����|��	K2�8��w�+8�����a@�tNm�FJR|�__�$I�$��0 �$��vn�Y���������V��hu��>���>����L�$����ǒ�c�բ��ԥW�T�&��nI�$I����(�$}e����^�p^d��	��Fh�bb��Ry�a��θ%LX������ǩ-R�6���I%)!�Ȯ+I�$I�TQ�H����{��"sMO�t|4�	�P�\&'/̬5[��$�IK7�}ON���Jq��*��m��޼6��=$I�$I�~
IRŵ��H�j��s���C��Er�����\��qK2xg�f����Y%�>���߶.]��EB\�u�H�$I�$Ut ���%`�x��lfd.�ϋln���'_b_N>�Wna��L�,���_�u�%ҷu�ԥSӚ��zH�$I�$IR�Ê����M�#s1�����z���'�~��<�,�%L]��r���M�D�6��oS��� 6�h^�%I�$I���f "I*��sa�"[WD����_A�� ���>u־\�]���K2���r����L����k�N�Չ1��$I�$I*Q ���)w?,�'��gع>2���~]��*��iw��a��͌[�������kZ�
�ۤ3�m]Z�K&TD��K�$I�$���H�ʗ�a�0�	؝��\����J)G|�/v`�'�LX�����z�V��m�ҿm:ǦU3��$I�$I*%@$I����0�Y�3
���%7�n����AB�#:]f�~&,�`��L�~����̃Vu��6�~m�rtj�"�	I�$I�$IRٶ+f?	=9�#s5�A�!����pا�|�^&,�d��>^��б��ӿM:�ۤӸV�"�I�$I�$IRٴ�3x�/0�e�?�Kk=�B��!&��N���=�[���%�,�<�бנ��F���'�H�$I�$��H�ʖ/V��Ga�k�G�t��7B�>p{p�޲�q�3�$�e��1!�Դ&�֥o�tҒ+�]H�$I�$���H�ʆM��G`����r�z� M�o��3w1~q�d�z��c�1!NjV��m�ҧu��&�H�$I�$�$�H�J��f���`ͻ_ϵ8#����ǂ `��,�/�d��>ݶ��X|l���пM:��J�z���'D�$I�$Ie��$��	X�.������B�"����<�����v2~q�d�q羂c�q1�|L��˩-SI�_w"I�$I��(1 �$��0,{�{2E�b��%��z������>�t;�d2aI&����%��rj�T��M�ױ�TI�?{�$I�$I��I��/?��ln�ued.�2�p%t���Z��惵��$���d�uwN����q�n�J�6u9��:$%Ė�H�$I�$��0 �$EO�>��2��d���UJ���D~U�Y�4'/��k�2~q��nf��܂c)I��*�m��vtm�=$I�$I�*:IR�;�>��~�l��UI���"]��؟��{��=�mf����SԪ�@��i�oS���j�;�$I�$IR)e "I*9{�ÜQ�_��"s)#�{t��؛�Ǵ/71��l3{r�>�Z-�~m���&�NMjg�!I�$I���` "I*~�0�	�������z���+�|���3��r�s���R�~m�2�m:�5�ALL(J7!I�$I���� D�T|������	�_nT��z�@V�~��b+�_^���[���:�hT�2�ۤӿm]�7H!2��$I�$Iґ1 �$�-�`棰�u�|�U����t=c��b��ͼ��)䅃��U�
�ԥ_�tZ�K6��$I�$I�Ob "I*:��{���1S��bZ�弴�s^�N~xI������&�m��<����$I�$I����$�	�t&��0���"�g���t�ټ���r�m ���L�/;=�թ��%I�$I�T��H�~� �U�"�ǆ9 �C�LO<�{���f}���Vg@�t���K�Z��U�$I�$I�*Iґ	����E^u�y1 9��３y&�L>�W�PNlR��ӣ^��(-I�$I���� D�tx�r�J��GH�Z��/���oy���A��j�m���:���JQ.X�$I�$I��$�{9{Ȝ�U>z���$ ;�*��׏��~�>�	7�I��ViԪ��r%I�$I�$� D�tA�d��N{��I]� �T���lh�3z�oƔ�i�T��r��$I�$I��@$I �������˩��y��K��^ >�0��%$w��A�R����$I�$I�J7I����s�mg��>^�	�����N�r� � #�1�����^�%���\�$I�$Ie��$U0��a>X��q�3��4�*{���os{���Ȫњ�S�S���ԍ��rŒ$I�$Iґ3 ��
�@^>�Voc��&/��ν�Z�qoqF�lb	 7�FL�Hiv*�BQ�Z�$I�$I��@$��ڟ����_0aI&�,�̮y t�fH�[�|����}���4��j%I�$I���e "I�ȞyL[��d0u����y$`@�U�Pi�vD��#�ΆC�n�(V-I�$I�$=I*�v��e��-�[���_p /\p�AJ"�k���Y�P������vA��P�y�ʖ$I�$I����$�"�္붳e�~R�U�SӚ����ν9L^��	K2yo�Vr�=ת̀֩\T�#-Eh��ȁ�Jp��p��zÒ�%I�$I�$)*@$����$���^JF�����)����V�kS�m�0i�f�-�`��m䅃�u��Ta@ۺhY�[�z(l_9�PN�
����%}[�$I�$IRT�HR)0aI׾�1���3��s��sLZUVo��72Z�Wc@ۺ�o�N�1�����`צȂ������אT���E�$I�$I*@$)���w������Vn�@��)�o�N�6uiZ�
��	������"��Յ�~�]�U��~I�$I�$�42 ��(��n{��^}��.��Y�G���w��
�#s5�@�!��b�K,��%I�$I��2� D��lˮ�Ï�t�YN*;�Bu�[& �!��9�z�y�"��z� �υX�X�$I�$I�� D���jb��1s�+���m/8�)��ݹ��2hH��o�[oB87r��q��F8�?��D�rI�$I�$��2 ��(Z�u��]Jߘ�<�烎���Q�&
���]B��MO�P�d�$I�$I��I�����2蕏ٵ� �T��<�q,4�=o���J�XI�$I�$��1 ��/���?�]F~8����I߹~����?$I�$I���d "I%('/�]o-�_s7 p�q���=��a|x��b�M�$I�$I*O@$��l�}�k��1s�m'�[����=�Z���NP5�x�$I�$I��I*�2����?������cw�W�Tغ
&���Ar=h|R��*I�$I�$� �T�&}���/`oN>MjU�W��ѩ�`��`����A�."��������bb�P�$I�$I�T6�HR1	��'���I+�vt-���qT�́7�����,l��{>�&��M_�$�^$�huV�@�$I�$I*�@$����g��x{a$���IM�m`K��F�
���P�r��!����,h1>���jZ�Wv~H�$I�$IG� D��Xf�~~���X�1���<����>�+L��@�zp�_�I������=�S�$I�$I�T��HR��~W�c_�:@���<}��t��]�ފ,:���T��b%I�$I��r� D����?g����شj���h��u%d���x8�n��[��]�$I�$I�T��H�O�9q9�L_���x�g�:�ix��΃M������-V�$I�$I� @$�'ص?��_]���[ ԫ7�T���/���D�>��3TJ�^��$I�$IRc "I?�g����>bՖ�$��0�v����9vgB\%�� w����$I�$I�J��$���l�����{sIKN��K:�~���H ���/@Z�h�*I�$I�$UH �t����g���'��7��_ϩG�I��g�Gt�����*�-T�$I�$I��@$�0����[���9�8�C=F��$��Ka�vH�
g��]�B%I�$I�$�H��ر'�k�9��n'��Oo��9'�ړ�u��/@�f�-T�$I�$I` "I?h��]\�҇lؾ�*	�<{F-�-�6}Y��8����B%I�$I�$0 �������\��|���Өfe^�A�w��Ru8�)h10�eJ�$I�$I�I:� 5}-#'.'�G�*�5��$N~)��ag8�oP�at�$I�$I�tH ��-�s��?�xs�& �t���Z�A��p�-�B%I�$I�$}'I��������X�a'�1���VqҊ w/TI��f�F�LI�$I�$I?� D���p�N���Gl�>@��<���?�Y����N�s��jiQ�Q�$I�$I��1 �$�6r��8��_��<�8���B(z�
݇BLL�˔$I�$I�t�@$Uh�p�ÓW���5@���f���Ɂ�p�ߠQ�h�)I�$I�$��H��v�cȿ0y�fR��ku�ɱۧG; �~*׌n��$I�$I�~I҆�{��K�b�.:ǭ�j���#b��?A���P(�eJ�$I�$I��@$U8��Ƶ/�c���<���ڗ5��^�z�]�$I�$I���� DR��ʜ����%T��՞�c��ȁ���G�Rrt�$I�$I�T$@$U��a����fF���<]eɹ; .	</��W�$I�$IR9b "��۹7�A�|���pC��.���Hmy�Uj�h�(I�$I�$���H*�Vo�ů_���6�Z�Z9p�/��H���$I�$I�$I����[�����9wWz�vCB58�/���h�'I�$I�$��H*w� ���������W&L���.xj�%I�$I�$;I����|n}c1�������h�i�@�A�����$I�$I�$�I�Ɩ]���̣�����7���$� t�(8�_�˓$I�$I�T�@$�K6fq�K�s��g�(aZd��I���+�ԏjm�$I�$I�J���2o̢M�=�gC昸���'�X���$I�$I�*"��Tf���|�D���HR��sb���-3�ct��I
���J����N�v��$I�$I��� DR�0�Kԛ}7��V0�9�=�u81~% A�ӈ9��Z'ZeJ�$I�$I*%@$�z�'�D�Y��B_ϧ�����Cl���{���N��$I�$I�J�)�T����Qo�� Ą
�  �j�w���C�$I�$IR�-�T�-�3�4�~|%��d�|�Ē-L�$I�$IR��+�$�Jr������x���۱��+�$I�$I�T��H*5�����;���ߢ������HR���X�$I�$I���� DRteob���ٹ�m�m�Csr
�'��)'�������C�+��P-Zt�[�EK�$I�$I*�@$��p2�s����Y2���˨	���pFP��5�S�Ù�e �$Vf�ėh?��������/?��.����L�$I�$I����PR�;��N#�b��'��+�@"B��fM����x&]���[��B���
��f�M�7^��%T���wѱ�%z;�$I�$I�J�PA���J���lRRR���"999��=;>��	VN X7���ׯ��$1#ܖO�t%��3�۩uS�~��yy,�3�};6�T�>-:�%��I�$I��R���m~s(�h������	�__, ��O�i�>�N�~��8�����L(t��=�Cl\��,��%I�$I�$�+ �~�};`���r"��)/���X���Ȍ�	ݲ�߀˛�!>6&�EK�$I�$I�@$� �������gC�_p8+�p��wdz��6i�y�5ຶuII���K�$I�$IR�2 �*�p>|6vo��i��$��=�ڼX?+x�� ��:�&ԐI�x7�#��4�U��:6`X��4�U�nF�$I�$I�f "U4K߂	�!{��s�������x��WZ�� ��@ή����xƵ�{�2%܁Aɕ�8��z�r\}�kT����$I�$I���` "U$K߂�.������e����|�Q�5k37�^�ъ���Cq1!Ni�ʭ�էW�T*�G�$I�$I�$E��TQ��#��?��%���ٚ�;����� �����5HἎ�9�}=jUM,��%I�$I�$�G0 �*��f~��w�W�ܷ�4�mJ*���R�s;����stj��R�$I�$I����TQ��|X�^��&��ITN�����\}�U�����$I�$I�Tv�HD~�Tg���z�x�[{��N�r�DH�$I�$I*��vS� �淠qP�t�s�f�p ���Ծ�ҵyj�(I�$I�$IE(&�H*[��rw��@$�����w�^Ɩ=�%\�$I�$I�$=��H�V���N\�;�Lj:�I-����p'R�U�R��$I�$I�Tt|�TAtjZ��)���Չ�N�S�rR���37܂��T�SӚ?|2I�$I�$I*�� �*�ؘw��
��>���I|nE��w�ي�Cm"I�$I�$Ie��T��kS��/=���¯�JO��ӗG�6u�T�$I�$I�$-�3fp�gR�^=B�o���Ak�-[�Yg�EJJ
U�T��Od�������ϠA��U�U�V����g��ͅα~�zH�ʕIMMeذa���Z3m�4�;�89��y����˜~m�2s����7]��E��o�0s����$I�$I���={�о}{�|��C_�fݻw�E�L�6�E�q�wP���	C����f���L�>�M�6q�y����g������0k�,^z�%^|�E��΂5�֭c�����Ջ0x�`~��_3q����2$6&D�f�8�C}�6��k�$I�$I�$�;� �h��)
��op�9��]t�E�����㐟��ʢN�:���+\p� ,_���-[2{�l�t�����9�3شiiii �5��Ç��_�������;v,K�,)t�;w2aê?;;������HNN����$I�$IR���k�6;@Tb��0cǎ�c��o߾���ҹs�B�ɚ7o�����ݻ`�E�4jԈٳg0{�lڶm[~ ��ۗ��l>�䓂5�<�Wk�:�$I�$I�$�|3 Q�ٲe�w�����_�~L�4�s�=���;��ӧ���IBBիW/�ٴ�4233�|3����WǾoMvv6���;d} ;;��/I�$I�$IR��Tq��a �>�l�@��5k�F���O�fy�1���;�5H�$I�$I��� *1�k�&..�V�Z�oٲ%�ׯ ==���v��Yh��͛IOO/X�y�惎u���$''���t��n�����
~mذ��ݨ$I�$I�$)�@Tb8��Y�bE���+WҸqc �?�x���y��w��X�����ӵkW �v���ŋٲeK��ɓ'���\�t�ڵ�9�Z��9%11����B�$I�$I�$Ie���R�ڽ{7�W�.�[��P�fM5jİa����NϞ=�ի&L���fڴi ���p�UW1t�Pj֬Irr2�����ڵ+]�t�O�>�jՊ�.���#G������ΠA�HLL��k��'�ছn��+�dʔ)���k�;��O$I�$I�$I%/A�"T~L�6�^�z4�W��/����3b�>��s�=�X��n�>�삵����n�_���o߾<��S����ϸ��k�6mU�T�+�����'.��Loڴi2��K�ҠA��~��_��dgg���BVV�� �$I�$I���5E����Z�$I�$I���~M�� �$I�$I�$��1 �$I�$I�$I��$I�$I�$I*w@$I�$I�$IR�c "I�$I�$I��I�$I�$I�T��H�$I�$I��r� D�$I�$I�$�; �$I�$I�$��1 �$I�$I�$I��$I�$I�$I*w@$I�$I�$IR�c "I�$I�$I��I�$I�$I�T��E� ��
� ����(W"I�$I�$�=_}����lRI3 ��î]� hذa�+�$I�$I�ʮ]�v����2T��7���0�6m�Z�j�B�h�sX���iذ!6l 999��H�ϣT:�,J��ϣTz�<J�Gy� `׮]ԫW��wcPɳD�1114h� �e�(�����?�RY��(�>�R���(�>�R�Q��G;?M�n�$I�$I�$��1 �$I�$I�$I��T�$&&r�]w����R�
��Q*|����Q*=|����Q*^n�.I�$I�$I��;@$I�$I�$IR�c "I�$I�$I��I�$I�$I�T��H�$I�$I��r� D*'�|�I�4iB�J��ܹ3s�΍vIR�6b�N<�D�U�Fjj*�s+V�(�f���4�Z�jQ�jU�?�|6o�\h����8p �+W&55�aÆ���Whʹi�8��HLL�裏��_,�ۓʴ�￟P(�����|���q�F.��RjժERRm۶壏>*8w�y'u��%))�޽{�jժB�ؾ};�\r	���T�^�����ݻwZ�h�"z��A�J�hذ!#G�,���ʂ��|���6mJRR͚5�O�A��Y��ǌ38��3�W��P�7�|���|�F�M�-�T�m۶eܸqE~�RYg "�����:t(w�u�1�۷�o߾lٲ%ڥIe����4h|��'O&77�>}��gϞ�5C����f���L�>�M�6q�y����g������0k�,^z�%^|�E��΂5�֭c�����Ջ0x�`~��_3q���_�����y�gh׮]�y�G�d�ر�nݺ����Y�t)?�05j�(X3r�H{�1F�Ŝ9s�R�
}��e���k.��>��&O�̘1c�1cW_}u����l���C�ƍ�7o>� ��x��gK�~����駟�'�`ٲe<���9���`�ϢT<���C���y��'y����Y�fq��s�UW1�|�9��9��,YR|7/�E��2�S�N��A�
����A�z��#FD�*�|ٲeK ӧO� v������G�.X�lٲ fϞA�7.���	233�<���Arrrp��� �ছn
Z�n]�Z?��σ�}��-Ieή]���͛�'ON>��������Q*IÇ�w������p���<���s;w����_A�ҥK ���֌?>�B�ƍ� ���z*�Q�F���յ�=�آ�%�L8p`p�W�;��K.�$�E�� �o�Q0.�g�g?�Y0p��B�t��9�����"�G���D*�rrr�7o�{�.�����w��̞=;��I�KVV 5k�`޼y���z�Z�hA�F�
��ٳgӶm[���
���ۗ��l>�䓂5�<�Wk|~��4�����<J%筷��N��/$55��;��s�_�n��������:w�\�y�^�:'�pB��޽{Ü9s
���ٓ����5}��eŊ�ر��oS*�N:�$�}�]V�\	��9s&���|�h)�gϟ]��c "�q[�n%??��: iiidffF�*�|	��<�nݺѦM 233IHH�z���~�����<��ձ�[���;}���v�2��W_��?fĈ�y�J�ڵky��i޼9'N��k�����=/������}?�fff���Z�x\\5k�<�gV��n��f.��"Z�hA||<;vd���\r�%�Ϣ-%��}��M���h IRi7h� �,Y�̙3�]�T!mذ�믿�ɓ'S�R�h�#Uh�p�N8�����;�d�F��W\�ꤊ��^���'���
�[�.ػ�^�z>��$}� RW�vmbccټys��͛7���������c̘1L�:�̧������Ν;��泗��~�g�c߷&99�������L�7o[�l��#..���8�O��c�=F\\iii>�R	�[�.�Z�*4ײeK֯_|�<}�Ϧ���lٲ���<�o�~DϬT�6���m۶\v�e2��S�gQ���|��k�ϦT��T�%$$p������̅�a�}�]�v��ʤ�-���:�x��L�BӦM?��㉏�/��X�����<{]�ve��Ņ~��<y2���_u�ڵ�9�Z��+}��Nc���,X����	'��%�\R��>�R��֭+V�(4�r�J7n@ӦMIOO/�,egg3gΜB��Ν;�7o^��)S���ܹs��3f���[�f���{�ԨQ���O*+���KLL�tbcc	�ÀϢ-%�����t��������W_�_|1X�tip��WիW233�]�Tf]{�AJJJ0mڴ ##���޽{�\s�5A�F��)S�}�Qеkנk׮����6m�}��	,XL�0!�S�Np�-��Y�vmP�r�`ذa��e˂'�|2���&L�P��+�5'�|rp����}��1w�� ...���{�U�V���?�ʕ+/��r����?�^�z���/X�hQp��gM�6���W��_�~Aǎ�9s�3g��7o\|���w������]vY�dɒ��W_*W�<��3%z�Riu�W���ƌ�[�.���Ԯ];�馛
��,J�c׮]�������@��#����>�� J��{�������ࡇ
�-[�u�]A|||�x���͐� ��x��ǃF�			A�N��>� �%Iep�_/��B��}�����o�5j�+W�=�� ##��y>��Ӡ��ARRRP�v���nrss��:ujСC� !!!8ꨣ
]Cҡ}; �y�J��o��i�&HLLZ�h<�쳅������;���҂�����NV�XQhͶmۂ�/�8�Z�j�����W�
v��Uh���ݻ���A�����￿��M*+����믿>hԨQP�R�ਣ�
n�����k|��1u��C�]�+���d���^{-8�c�����u���رc���*A��I�$I�$I���� �$I�$I�$��1 �$I�$I�$I��$I�$I�$I*w@$I�$I�$IR�c "I�$I�$I�ʝ�o�^c�,>�����Ԫ�&D���Z#0�Q��������hՠ��� ��L#���({10��D�7��4*ZAA�<Ѡ�U�v/����Ӄ�~>		���u_��7�o��@     ��@     ��@  �����ΔJ����ˇz*I����455}�k�ϟ�3�<�G�  �_  ������;���O?���X�hQJ�Rߟ����7.K�,��� ��@   �UTT����{�3dȐtuu���+���>}zf̘��[�� � ��?  ~&M���n�-�g�Neee����׿�5�~�ifΜ������6O=�T��^}��\p����Huuu���|��}��'R__����TUU���!�~�i����-g�}v��C�f�ĉپ}{����#_|q���SQQ���:+�������Օ�.�(���9rd}�ь1">�`��|��ǹ�r�q�eȐ!�<yr6m�����@k�4iRn���̙3'�sL������c˖-9��ss�G��SOMkkkJ�R�-[�$9rd�d̘1)�J�4iR��x����Ԥ��*�f��_|���?��h}�1��T*eذa6lXF��{�7��͛�i  � �  ����ŋs��f������r�-��+�Ȅ	��K/eڴi��k��g�%�&O��1c�d�ƍY�|y���̘1#ɾ@q�UW����k������\z�����޽{��Ԕ��??�7o�ڵk��ҒR��$���΅^���~:�����������ر�o��^{m�{ｴ����'���k׮~k��+�k׮<��Sy��3v��L�2%�w�>�=9����4(�֭���ߟ{�'�V�J�������)GuT֭[��f�ܹ��_�~}����5]]]�5�z��tttd���Y�xq-Z�E����1zzz�x��$�رc�ս ��J�����z  �7�4iRzzz��s�%���G}t.���<��#I��;w���&k׮����s����ˊ+��y�w2|��lݺ5���7n\:;;s�'����ݻSUU�������5��O?=7�|sn���lٲ%�G�Ά�_�*I�m۶�5*�ӟ2{��<���袋�k׮q�}����fΜ9iii�����9rd���s�gp�uuu��]��}�ٙ<yr���?d���ill��o��aÆ%�:�N���K����i��~���9mmm���HYYY�dƌ0`@{챯ݧ���gٲe}��.c,Z�(3g�̠A��${���a���z(�����k �_���z  ��9�3��^VV��������}���:I�NYlڴ)�W�NEE�~cuttdڴi�2eJ���3}��L�6-�_~y*++s�1Ǥ��9ӧO�ԩS��А3f���&ɾ ����?��tuue�޽ٳgO�	��[�f����N#��֦�����M���ݽ��0��ٓ����ړ����n��K�����}ںuk��?�}��`�v�i}�⫱_y啃����1x����KI��>�,������SUU����ou  ("  ~&;�~�K�R��}�x�/��2ɾH��ؘ��o��jjjRVV�U�V�^�ʕ+��%s��ͺu�2r����o��ߞ�˗���ϼy�jժ�?>w�ygV�Z�x ���)//��_��?������ݝ����������C��ߴƯ|��}�O��1�wc�������|�gd�ʕ���  �   �5v��<��1bD����J�L�81'N��wߝO<1K�.�wܑd�K�ǌ���+�sN}�ь?>k֬Isss.��$�BDggg߸'�|r��ݛ����7.ɾG`}��G��s��80#F����x '�|r�~�����}�h6l���g?��$�=�SVVV�={��i  �O��� @A͚5+�w��UW]�6���#+V��̙3��ӓu������}6nܘ;vdɒ%���2z����[�뮻�v��l߾=+W��o��ѣG'IF��%K���_ΦM�r��W�;�p�)����!---Y�~}�����Ғ���*9�s��Ԕ�+W���3/��B�Ν��7� k<S�N�I'��뮻.�7oΚ5k2o޼$�=Us��ǧ����%���׿���c����Ν;�s�μ��[Y�paV�X��/��PO  ~  (�N8!k֬IOOO�M�����̞=;C�̀2dȐ<�쳹��SWW�y��e�����r�QGe˖-���RWW����̚5+7�tS���c*++3a466f�������$�<�H���s�y��K.ɍ7ޘ����#�L�/.����y睗�3g���.W^ye�o��w����`���eٲe����Yg��n�!s��M���80������N�ID���ߩ��IMMMF���{��;  �ҕz{{{�$  ��{�w2|�𴶶fʔ)�z:�h͚59��s�m۶�t�I�z:  �w �   ?�g�y&��ݩ��OWWW�̙�w�}7����~/�>Ԗ.]�����5*۶m�o~�TVV���?�S  �#/A  ~_|�E~�����7�����3a�����ŏ$��O����6;v�ȱ�����,X��PO  ��      
�K�    ��@     ��@     ��@     ��@     ��@     ��@     ��@     ��@     ��@     ��@     ��@     ��@     ��@     ��@     ��@     ��@     ��@     ��@     ��@     ��@     ��@     ��@     ��@     ��@     ��@     ��@     ��@     ��@     ��@     ��@     ��@     ��@     ��@     ��@     ��@     ��@     ��@     ��@     ��@     ��@     ��@     ��@     ��@     ��@     ��@     ��@     ��@     ��@     ��@     ��@     ��@     ��@     ��@     ��@     ����K�Hm1    IEND�B`�
```

## Key Encapsulation Mechanism

As for the signature we can divide the KEM in four main parts: the generation of the *private key*, the generation of the *public key*, the *encapsulation/encryption* and the *decapsulation/decryption*. Looking at the table below you can see that **kyber512 is even faster than ECDH in the computation of private and public keys**, while Stremlined NTRU Prime takes a lot more time to compute the private keys, but it is faster than Kyber512 in the generation of the public key. As before time is measured in μs (microsecond) and the memory in KiB (Kibibyte)

| Algorithm | Key         | Time (<span class="unit">&mu;s</span>) | Memory (<span class="unit">KiB</span>) |
|-----------|-------------|----------------------------------------|------------------------------------------|
| ECDH      | private key | 13657,8501                             | 614                                      |
|           | public key  | 15223,1383                             | 615                                      |
| Kyber     | private key | 13285,9647                             | 640                                      |
|           | public key  | 15031,2310                             | 632                                      |
| NTRUP     | private key | 39736,1747                             | 642                                      |
|           | public key  | 14713,5626                             | 636                                      |

Looking at the encapsulation/decapsulation part, ECDH simply encrypts a message so, in order to have a fair comparison, we encrypted a 32 byte random string. This because the secret exchanged using Kyber512 or Streamlined NTRU Prime is composed of 32 bytes.

| Algorithm | Enc/Dec       | Time (<span class="unit">&mu;s</span>) | Memory (<span class="unit">KiB</span>) |
|-----------|---------------|----------------------------------------|------------------------------------------|
| ECDH      | encryption    | 16039,1876                             | 625                                      |
|           | decryption    | 14878,8790                             | 615                                      |
| Kyber     | encapsulation | 15083,5262                             | 626                                      |
|           | decapsulation | 14388,3123                             | 621                                      |
| NTRUP     | encapsulation | 15878,6283                             | 629                                      |
|           | decapsulation | 16262,9084                             | 621                                      |

The results are amazing again and they show that, also in this case, **Kyber512 is faster than ECDH**, while Streamlined NTRU Prime is a little bit faster than ECDH in the encryption part, while it is slower in the decryption part.

# The script used to create the material in this page

All the smart contracts and the data you see in this page are generated by the scripts [generic_dilithium.bats](https://github.com/dyne/Zenroom/blob/master/test/zencode_qp/generic_dilithium.bats), [kyber.bats](https://github.com/dyne/Zenroom/blob/master/test/zencode/kyber.bats) and [ntrup.bats](https://github.com/dyne/Zenroom/blob/master/test/zencode/ntrup.bats) . If you want to run the scripts (on Linux) you should: 
 - *git clone https://github.com/dyne/Zenroom.git*
 - install  **jq**
 - download a [zenroom binary](https://zenroom.org/#downloads) and place it  in *./Zenroom/test*

# RSA

The implementation of the RSA signature scheme inside Zenroom is based on the RSASSA-PKCS1-v1_5 scheme described in Section 8.2 of [RFC8017](https://datatracker.ietf.org/doc/html/rfc8017).

In Zenroom, using the *Scenario rsa*, you will use the **RSA 4096** version, i.e., the value *n* in the keys must be 4096 bits. The public exponent *e* of the keys generated with Zenroom will always be 65537.

# Key Generation

## Private key

The script below generates a **RSA** private key.

```gherkin
Scenario rsa
Given I am known as 'Alice'
When I create the keyring
and I create the rsa key
Then print my 'keyring'
```

The output should look like this:

```json
{"Alice":{"keyring":{"rsa":"4f2d/behINr5MK2Qtz6cuqoFzENRYrqz+1pswBaG8H3FpAV07prGsvzWgSrzaymNPE235efQlFmMw6Q92JgtnTpRlf1MdkH/JiuB7f17rkT6UKrUJHSlxN+DKqxON4nSnGKI8nrfvmhspmxrwGD984JhPEukH+uMC+q5nEAmI3/wmY/zBAS3xfIZnCLvxebjJHcxsw3y7s9v+FPBboBFB0du1HYxHQy1yxNgL0s0Y/PXhJhvjEh1QB62J8rinXYjzpRf/tRikmkw098PMvSmRQzI32dQYGZLXYVo1udnUvzERCRxogWJC7Un4g5P1/jX505HborkBk0L8yRXrs19h6EgJobvnyKVfzYF7fF8wj9b7KaQWUrZyygR1R0v7jSe6TPMILvos2hDkBFne9jgCD0kEyOBFwosTTOsPxvSDpB4Ov2hYJ56xSBsb6Lz7Hwjq0qe9IAB/+/vbMlNpbzlZ6E0otFZEtYFm9+Xg7DTgf6fw9gGXv4prFFw1KMkQ/8PibnFFf0JnAhKhz1Z+16RyZiCzrCv6KlDZksm2qbwUX2cqljIzA1TsgqEu/avBWf82e4vOd3PJvPUULgp1HQIfYWC6Q8QiK7IJ1ySRrwKVZGS0g8rOB0KAwNb7s83GB0lVyPlpYm7BSQMoH1djb90kvwLwPkeGKNCsQmCaBidYSdjniF7yutbCUuZOpk1PYNnATWnEfGZPMXDwdt4XTXEYxyxLbqax11ZXvzLWXyNu3ZHo9axoJsgGc1kHE0q4gIRcbivDkYbRwJK+BjBKODRNBTHZFY5b7X277PpJqUf9EADsae+g42HaI6kWdyxo8+t/MYSByHk9Db6tdB14Q0uzuHnPz4XgmDj/9FsMzZQnXN5CpW84SQ6QvSPmZQFusMy7zkarLL/pC+qwfK/Rj5k5QMWrv9U7kfJKQCQz+1PDdnA4UTjlwmQko/0hTo08wUsIPOXDvquU8lbA0jwmnbAbS2zAAGbMydzIrre+gIWKNo7WxU/1Dep02K2HkoMgwaXZtusXKWptB01iVo9rNSU+HeJWkd6CTOB4oGHx8sqSMNNYfikyPBjX2MKHGIwiKF0APv/j8G/4ImpexwxaWQuUgG+vtz/XgxHvUwb9C29QP5QQiG5OeKM7TGuA9AixrS39AwzCGvRf3kzKYiC1CYhrVd2YXinuZ8G1zKtO7xSAAh+Rm5PfCpfRle1f+/qbVOqG0ceBWM2pp9VNRKHsNxnWUXi5SzCPpu4Y8iaaX8Pd3PN96SET1oHps5Z/UcOzkgBQXLxruFCMDmsDwd+Slpah8Tvfil79+XFSKaui+/C4BBPUaYvh/4w6PN6nK1VaOxVTLuAJEgXOFnBxK1QIK6PLzm2of+3v1p3EpqOwW6SrLrIoFrnkL0NsCnAZZ8Y+S4GCZSHkoBe1OlVoW1OG2CW2/gX4boXbsWmKn1Z4OxVRAGJBWINA0QdxoQSaCKaddnDaE8yvhNZqaF44hdldEWcR9zoA1KIZzDEh34pgWxx5nA0pDRzdZ7HmpRsawqahHEFIk574CX2q2m9pk5MiiPzu+veFK6ekeZFbtVS+cP+6CdxbvzgcTtptLEJaN5sR/yZmIt0G3R72Lynvtx/NHmJ6fyf2IFJEdC9qCsUx09OhAW7OQgJv9xJGfgKrztU2xVDam/x0oYCfs5/RE0bW8CqgwVlyurmau7l76B6cSJ/bT0="}}}
```



## Public key

Once you have created a private key, you can feed it to the following script to generate the **public key**:

```gherkin
Scenario rsa
Given I am known as 'Alice'
Given I have my 'keyring'
When I create the rsa public key
Then print my 'rsa public key'
```

The output should look like this:

```json
{"Alice":{"rsa_public_key":"jjziExPv52qCOBrErwrQ+tFRZ3FuEy1TYBgos/cCHZ4JrxY4ip3aQlvZ1FRKCBSklCv7TDpNN/uegtSXNu3NxrPYvc11XUL9lZNN+rkrDXrroCPUDJXlCvQeX9QTTDb5oO6riz2ygkQ/+gVxY6XIm0uCaavYCkNOElAbjJgvm6VmFLRz4iluAzFzZRPJHSHnPhTl9WaajJ6IHJaSthJQrWCFRapcwWAFa8icl5AzWYYunjFKpD8KoqTBqvMqsBn8nb4umrZVElsgUjASGe1DiHvcxn7KBzdg7+hiuKIEMbFp2IZcIpfolIXyFrsIjdc/I4ULtqvpwLQh7gGpSAtuldhJUB1KIcn9JtxK4Z5IvAGqTUjvyU0snGtFLkbyn7ozh4+tBLRdiCmdMt4m408rn/XdshUTnYPKUnfrFuWGNOcp1JDxIRHeJDF9OczA128JIS76qaGh2Tl8vTqFRf0eod/RXz/duxdh7pt4W4jaXo7FkbOmviARN5KnmG60pa094FNf/PSed9bMY//N7Yoh9o1fqiEDeio8cyT0aSu24GV13fFvgsyhXbvVwrcVh37tO/oXJ/K7agfdD96CoR/ixAVNYzb2Ma8y9VUzyrwBXmIDeCHKcPd861nKczrDwGnZb3UsmANKNrQxp/NoyxWQWcf1jSJeOxv+kvHHOiGpRpEAAQAB"}}
```

# Signature

In this example we'll sign a simple message. Along with the data to be signed, we'll need the private key. The private key is in the file we have generated with the first script.

The script to **sign** this message look like this:

```gherkin
Rule check version 4.32.6
Scenario rsa
Given that I am known as 'Alice'
and I have my 'keyring'
When I write string 'This is my authenticated message.' in 'message'
and I create the rsa signature of 'message'
Then print the 'message'
and print the 'rsa signature'
```

And the output should look like this:

```json
{"message":"This_is_my_authenticated_message.","rsa_signature":"Mnj6QLZ8LXz74zZkeiySnvzgu4sQ8Q6hBbofnodqO9BH+RN8SNdlX65RTVhtxKkQ9Bp2RKp7u+tHjwIc9s8e3H/rFVvWt0Lzvc5tvig5qixBLfHVYtMiRgJo6qm91UCWUNRnb7URQCi9lALnhFTByJRmCE5JIydFqBT6Q+jPmhrQ7XP2wUk5pdSfsjQXIxCRDHdv5jlKurQg+igzVGzMu3Zlv7H2bmU/0Jl1E2aQckS4517UXZmxlrn/BmKm8CLVUN88jqANoD2gydYmIXNlk72aIgz2/8A9IjP6J0SY4eJsOOlfq2puym+72Rioat5uCBX+VlHYPhG/Fu79EP0D7BO0gqxtmDj7E0Aq5nlsimokpfRip2x2c2jWrMqtkgyXs3ZQDYlsx5p+ll/VU0t3FyDdhLfDL8sAp4BpNnem3irzUuXJmVMBMIZUle4u2nxsWfsMZKYqI0Hk4jzX+2VOnuydpXoZuSHx30yS+TpX4uEtPyWz9AZo+141mTnCvsZyioUpIGErKvQFk58eoXHOBFKQZiG1BbUigki/nQx3iBPhs1dTtyhFdByR9ZF1BW0MZZgMAhAFsESvuiYpo8dxIfQwzpPV7ccB04gvNqcw8CpguJfB5c47JXILYl94v/faB8XhlEc3aoWKtSCCgzmWVw0eepyFhhM5MPOSL5x99FI="}
```

# Verification

In this section we will **verify** the signature produced in the previous step. To carry out this task we would need the signature, the message and the signer public key. The signature and the message are contanined in the output of the last script, while the signer public key can be found in the output of the second script. So the input files should look like:

```json
{"message":"This_is_my_authenticated_message.","rsa_signature":"Mnj6QLZ8LXz74zZkeiySnvzgu4sQ8Q6hBbofnodqO9BH+RN8SNdlX65RTVhtxKkQ9Bp2RKp7u+tHjwIc9s8e3H/rFVvWt0Lzvc5tvig5qixBLfHVYtMiRgJo6qm91UCWUNRnb7URQCi9lALnhFTByJRmCE5JIydFqBT6Q+jPmhrQ7XP2wUk5pdSfsjQXIxCRDHdv5jlKurQg+igzVGzMu3Zlv7H2bmU/0Jl1E2aQckS4517UXZmxlrn/BmKm8CLVUN88jqANoD2gydYmIXNlk72aIgz2/8A9IjP6J0SY4eJsOOlfq2puym+72Rioat5uCBX+VlHYPhG/Fu79EP0D7BO0gqxtmDj7E0Aq5nlsimokpfRip2x2c2jWrMqtkgyXs3ZQDYlsx5p+ll/VU0t3FyDdhLfDL8sAp4BpNnem3irzUuXJmVMBMIZUle4u2nxsWfsMZKYqI0Hk4jzX+2VOnuydpXoZuSHx30yS+TpX4uEtPyWz9AZo+141mTnCvsZyioUpIGErKvQFk58eoXHOBFKQZiG1BbUigki/nQx3iBPhs1dTtyhFdByR9ZF1BW0MZZgMAhAFsESvuiYpo8dxIfQwzpPV7ccB04gvNqcw8CpguJfB5c47JXILYl94v/faB8XhlEc3aoWKtSCCgzmWVw0eepyFhhM5MPOSL5x99FI="}
```


```json
{"Alice":{"rsa_public_key":"jjziExPv52qCOBrErwrQ+tFRZ3FuEy1TYBgos/cCHZ4JrxY4ip3aQlvZ1FRKCBSklCv7TDpNN/uegtSXNu3NxrPYvc11XUL9lZNN+rkrDXrroCPUDJXlCvQeX9QTTDb5oO6riz2ygkQ/+gVxY6XIm0uCaavYCkNOElAbjJgvm6VmFLRz4iluAzFzZRPJHSHnPhTl9WaajJ6IHJaSthJQrWCFRapcwWAFa8icl5AzWYYunjFKpD8KoqTBqvMqsBn8nb4umrZVElsgUjASGe1DiHvcxn7KBzdg7+hiuKIEMbFp2IZcIpfolIXyFrsIjdc/I4ULtqvpwLQh7gGpSAtuldhJUB1KIcn9JtxK4Z5IvAGqTUjvyU0snGtFLkbyn7ozh4+tBLRdiCmdMt4m408rn/XdshUTnYPKUnfrFuWGNOcp1JDxIRHeJDF9OczA128JIS76qaGh2Tl8vTqFRf0eod/RXz/duxdh7pt4W4jaXo7FkbOmviARN5KnmG60pa094FNf/PSed9bMY//N7Yoh9o1fqiEDeio8cyT0aSu24GV13fFvgsyhXbvVwrcVh37tO/oXJ/K7agfdD96CoR/ixAVNYzb2Ma8y9VUzyrwBXmIDeCHKcPd861nKczrDwGnZb3UsmANKNrQxp/NoyxWQWcf1jSJeOxv+kvHHOiGpRpEAAQAB"}}
```

The script to verify these signatures is the following:

```gherkin
Rule check version 4.32.6
Scenario rsa
Given I have a 'rsa public key' in 'Alice'
and I have a 'rsa signature'
and I have a 'string' named 'message'
When I verify the 'message' has a rsa signature in 'rsa signature' by 'Alice'
Then print the string 'Signature is valid'
and print the 'message'
```

The result should look like:

```json
{"message":"This_is_my_authenticated_message.","output":["Signature_is_valid"]}
```

# The script used to create the material in this page

All the smart contracts and the data you see in this page are generated by the scripts [rsa.bats](https://github.com/dyne/Zenroom/blob/master/test/zencode/rsa.bats). If you want to run the scripts (on Linux) you should: 
 - *git clone https://github.com/dyne/Zenroom.git*
 - install  **jq**
 - download a [zenroom binary](https://zenroom.org/#downloads) and place it */bin* or */usr/bin* or in *./Zenroom/src*
# Scenario 'SD-JWT' (Work in Progress)
 
**SD-JWT** stands for **Selective Disclosure for JWTs** that is 
"a mechanism for selective disclosure of individual elements of a JSON object used as the payload of a JSON Web Signature (JWS) structure. It encompasses various applications, including but not limited to the selective disclosure of JSON Web Token (JWT) claims." following this [specification](https://datatracker.ietf.org/doc/draft-ietf-oauth-selective-disclosure-jwt/).

In this context we have three main characters:

- The **Issuer**: an authority that issue Verifiable Credentials containing claims that are selectively disclosable to other partecipants;
- The **Holder**: any partecipant that request for a credential;
- The **Verifier**: any third party that want to verify the validity of an Holder's credential or a subset of claims contained in it.

## Credential Issuance

The **credential issuance** includes all the necessary steps that an Holder and an Issuer have to perform in order to create a new **Verifiable Credential** (VC).
This includes the authentication process of the Holder and the verification of its personal data, both in the sense of completeness of the information needed to issue the particular credential, and the correctness and reliability of it.

In order to give more details about the credential issuance flow, we need to introduce two more parties:
- The **Authorization Server** which is the server issuing access tokens to the client after successfully authenticating the resource owner and obtaining authorization;
- The **.wellknown** which is a directory on http server that contains the Issuer public metadata and that can be accessed also by the Holder.

Then we can describe the credential issuance flow with the following diagram:

```mermaid
sequenceDiagram
autonumber
participant A as Auth
participant H as Holder
participant I as Issuer
participant WK as .well-known

I->>+I: create public JWK and SSD
I->>-WK: Issuer JWK and SSD
H->>A: Holder send authorization request through browser
A->>H: Authorization endpoint issues authorization code
H->>A: Holder present authorization code to token endpoint
A->>H: Token endpoint issues access token (JWT)
WK->>H: Issuer JWK and SSD
H->>H: create Holder JWK
H->>+I: send to the credential endpoint the access token and the VC id
I->>I: create SDR with SSD, id, and Holder's data
I->>I: create signed SD with SDR
I->>-H: issue signed SD
```
Where we have:
- SSD = **Supported Selective Disclosure** is a JWT containing information about the Issuer and the Authorization Server and a list of supported credentials, each containing (at least) a unique identifier id, a list of mandatory attributes to issue the credential, a list of supported ciphersuites;
- SDR = **Selective Disclosure Request** is a dictionary with the JWT containing all the claims for the selected credential filled with the Holder's data and a list of the fields to be made seletively disclosable.

**TODO** first 9 steps. Now we are assuming that the Holder has identified himself to the Authorization Server, and have sent the request for a specific type of credential to the Issuer. Moreover we assume that at this point the Issuer can somehow access the Holder's data in such a way that he already trust this informations.

At this step of the flow both the Issuer and the Holder can access the Issuer Metadata in ./well-known that contains the list of supported credentials, each of them identified by a unique **id**.

The Issuer checks that the id selected by the Holder corresponds to a supported credential, and construct a **Selective Disclosure Request** which contains a list **fields** of the claims that must be made selectively disclosable, and a dictionary **object** containing all the claims with the Holder's data.

The input file to create the request should look like:

```json
{
    "supported_selective_disclosure": {
        "credential_issuer": "https://issuer1.zenswarm.forkbomb.eu/credential_issuer",
        "credential_endpoint": "https://issuer1.zenswarm.forkbomb.eu/credential_issuer/credential",
        "authorization_servers": [
            "https://authz-server1.zenswarm.forkbomb.eu/authz_server"
        ],
        "display": [
            {
                "name": "DIDroom_Issuer1",
                "locale": "en-US"
            }
        ],
        "jwks": {
            "keys": [
                {
                    "kid": "did:dyne:sandbox.genericissuer:GPgX3sS1nNp7fgLWvvTSw4jUaEDLuBTNq5eJhvkVD9ER#es256_public_key",
                    "crv": "P-256",
                    "alg": "ES256",
                    "kty": "EC"
                }
            ]
        },
        "credential_configurations_supported": [
            {
                "format": "vc+sd-jwt",
                "cryptographic_binding_methods_supported": [
                    "jwk",
                    "did:dyne:sandbox.signroom"
                ],
                "credential_signing_alg_values_supported": [
                    "ES256"
                ],
                "proof_types_supported": {
                    "jwt": {
                        "proof_signing_alg_values_supported": [
                            "ES256"
                        ]
                    }
                },
                "display": [
                    {
                        "name": "Above 18 identity",
                        "locale": "en-US",
                        "logo": {
                            "url": "https://avatars.githubusercontent.com/u/481963",
                            "alt_text": "Dyne.org Logo"
                        },
                        "background_color": "#12107c",
                        "text_color": "#FFFFFF",
                        "description": "You can use this credential to prove your identity as name and surname, to prove your date of birth and if your age is above 18 or not."
                    }
                ],
                "credential_definition": {
                    "type": [
                        "Identity"
                    ],
                    "credentialSubject": {
                        "given_name": {
                            "mandatory": true,
                            "display": [
                                {
                                    "name": "Current First Name",
                                    "locale": "en-US"
                                }
                            ],
                            "value_type": "string"
                        },
                        "family_name": {
                            "mandatory": true,
                            "display": [
                                {
                                    "name": "Current Family Name",
                                    "locale": "en-US"
                                }
                            ],
                            "value_type": "string"
                        },
                        "birth_date": {
                            "mandatory": true,
                            "display": [
                                {
                                    "name": "Date of Birth",
                                    "locale": "en-US"
                                }
                            ],
                            "value_type": "number"
                        },
                        "above_18": {
                            "mandatory": true,
                            "display": [
                                {
                                    "name": "Is above 18",
                                    "locale": "en-US"
                                }
                            ],
                            "value_type": "string"
                        }
                    }
                }
            }
        ]
    },
    "object": {
        "family_name": "Lippo",
        "given_name": "Mimmo",
        "birth_date": 640856826,
        "above_18": true,
        "iss": "http://example.org",
        "sub": "user 42",
        "iat": 1713859327,
        "exp": 1903161721
    },
    "id": "Identity"
}
```

The following code is used to obtain a Selective Disclosure Request:

```gherkin
Scenario 'sd_jwt': create request

Given I have 'supported_selective_disclosure'
Given I have a 'string' named 'id'
Given I have a 'string dictionary' named 'object'
When I create the selective disclosure request from 'supported_selective_disclosure' with id 'id' for 'object'
Then print the 'selective_disclosure_request'
```

The output file should look like:

```json
{
  "selective_disclosure_request": {
    "fields": [
      "given_name",
      "family_name",
      "birth_date",
      "above_18"
    ],
    "object": {
      "above_18": true,
      "birth_date": 640856800,
      "exp": 1903161721,
      "family_name": "Lippo",
      "given_name": "Mimmo",
      "iat": 1713859327,
      "iss": "http://example.org",
      "sub": "user 42"
    }
  }
}
```

When the Issuer has a Selective Disclosure Request, 
it creates the **Selective Disclosure**, which contains the JWT payload of the SD-JWT and the list of all the Disclosures.
Then the Issuer sign the payload contructing a JWS and return the **Signed Selective Disclosure** that contains also the list of all the Disclosures in serialized form.

The Disclosures should be kept private by the Holder, unless he wants to prove to a Verifier some specific claims.

The input file to create the SD-JWT should look like:

```json
{
    "The Issuer": {
        "es256_public_key": "gyvKONZZiFmTUbQseoJ6KdAYJPyFixv0rMXL2T39sawziR3I49jMp/6ChAupQYqZhYPVC/RtxBI+tUcULh1SCg==",
        "keyring": {
            "es256": "XdjAYj+RY95+uyYMI8fR3+fmP5LyQaN54vyTTVKxZyA="
        }
    },
    "selective_disclosure_request": {
        "fields": [
            "given_name",
            "family_name",
            "birth_date",
            "above_18"
        ],
        "object": {
            "above_18": true,
            "birth_date": 640856800,
            "exp": 1903161721,
            "family_name": "Lippo",
            "given_name": "Mimmo",
            "iat": 1713859327,
            "iss": "http://example.org",
            "sub": "user 42"
        }
    }
}
```

The following contract construct the SD and the Signed SD:

```gherkin
Scenario 'sd_jwt': create sd-jwt
Scenario 'es256': public key

Given I am known as 'The Issuer'
and I have my 'keyring'
and I have my 'es256 public key'
# public key will be contained in a did document

Given I have 'selective_disclosure_request'

When I create selective disclosure of 'selective_disclosure_request'
When I create the signed selective disclosure of 'selective disclosure'

Then print 'selective_disclosure'
Then print 'signed_selective_disclosure'
```

The output file should look like:

```json
{
  "selective_disclosure": {
    "disclosures": [
      [
        "SYRPbpHhkPH7Wra5Eh-xVg",
        "given_name",
        "Mimmo"
      ],
      [
        "_DAsJQ0LVzGAsSDyUqlbZA",
        "family_name",
        "Lippo"
      ],
      [
        "-yuyuj9XtpUl3BQZ0_tgtQ",
        "birth_date",
        640856800
      ],
      [
        "codjG-WqsREtxUAXnQM9aQ",
        "above_18",
        true
      ]
    ],
    "payload": {
      "_sd": [
        "U2kEVLx7yyeGvHjv-Ooe-9L83quBaQsZoVt0czrXHJ0",
        "dco6Gf7wrOPdU1JegneIn757ZMTcyfuBhXzDepUSyJ8",
        "Urz5C5fup95JNRYIfAfUd4Fv_3nfZOKh0hrzpALWVSk",
        "HSZaO57OEELA7lznX-6zL-XXg-CSt0DFIiwuowg_DLY"
      ],
      "_sd_alg": "sha-256",
      "exp": 1903161721,
      "iat": 1713859327,
      "iss": "http://example.org",
      "sub": "user 42"
    }
  },
  "signed_selective_disclosure": "eyJhbGciOiAiRVMyNTYiLCAidHlwIjogInZjK3NkLWp3dCJ9.eyJfc2QiOiBbIlUya0VWTHg3eXllR3ZIanYtT29lLTlMODNxdUJhUXNab1Z0MGN6clhISjAiLCAiZGNvNkdmN3dyT1BkVTFKZWduZUluNzU3Wk1UY3lmdUJoWHpEZXBVU3lKOCIsICJVcno1QzVmdXA5NUpOUllJZkFmVWQ0RnZfM25mWk9LaDBocnpwQUxXVlNrIiwgIkhTWmFPNTdPRUVMQTdsem5YLTZ6TC1YWGctQ1N0MERGSWl3dW93Z19ETFkiXSwgIl9zZF9hbGciOiAic2hhLTI1NiIsICJleHAiOiAxOTAzMTYxNzIxLCAiaWF0IjogMTcxMzg1OTMyNywgImlzcyI6ICJodHRwOi8vZXhhbXBsZS5vcmciLCAic3ViIjogInVzZXIgNDIifQ.XP1SerkTSZbO_8zB2CZsfc-w4fjruHTdDeQlkgSeEj3v4u9v6UhJXW0d5c_-mfMJtD3EEt3hFloGceeegrbESg~WyJTWVJQYnBIaGtQSDdXcmE1RWgteFZnIiwgImdpdmVuX25hbWUiLCAiTWltbW8iXQ~WyJfREFzSlEwTFZ6R0FzU0R5VXFsYlpBIiwgImZhbWlseV9uYW1lIiwgIkxpcHBvIl0~WyIteXV5dWo5WHRwVWwzQlFaMF90Z3RRIiwgImJpcnRoX2RhdGUiLCA2LjQwODU2OGUrMDhd~WyJjb2RqRy1XcXNSRXR4VUFYblFNOWFRIiwgImFib3ZlXzE4IiwgdHJ1ZV0~"
}
```

It is also possible to return the SD-JWT as a JWT substituting the last line of the contract above with the following:

```gherkin
Then print 'signed_selective_disclosure' as 'decoded_selective_disclosure'
```

This should give an output like:

```json
{
  "signed_selective_disclosure": {
    "disclosures": [
      [
        "RLdC7X_9G2F1wWh5MV-3eg",
        "given_name",
        "Mimmo"
      ],
      [
        "LKvfDcEeWUG7_C2MpxKfIg",
        "family_name",
        "Lippo"
      ],
      [
        "9RZKoww0KRG2B3pifootyA",
        "birth_date",
        640856800
      ],
      [
        "OuTKYvHV8Y0vYf2xey9X-Q",
        "above_18",
        true
      ]
    ],
    "jwt": {
      "header": {
        "alg": "ES256",
        "typ": "vc+sd-jwt"
      },
      "payload": {
        "_sd": [
          "M3RP6ySmblfFkv27XzNPmN5F6W_NsupnlpaAqeWPYho",
          "72sgBajcha4T0FWC7an7DKxciCKXcyhmHCbt7XkTFRs",
          "jL4iW-7zzPMc7Qjlh2Ct_RWFN0vPjacptJ8w-RHgR88",
          "szIFS-AzE6PR7b0MsNVybDZ2-4cjiWduyzXFIN1S-70"
        ],
        "_sd_alg": "sha-256",
        "exp": 1903161721,
        "iat": 1713859327,
        "iss": "http://example.org",
        "sub": "user 42"
      },
      "signature": "hek_HnH0jb2wYimlJfZhqLYOD66tFScj-9CgbV1JlIYma5G5IhFYzmYIw6NqLo_htJF10kGItSkzbP2YRB0IYQ"
    }
  }
}
```

**Note** that one can also upload a SD-JWT in decoded form with a statement like:

```gherkin
Given I have a 'decoded_selective_disclosure' named 'signed_selective_disclosure'
```

## Credential Presentation

An Holder who is already in possession of a SD-JWT can be asked to present its credential to a third part called the **Verifier**, who can (optionally) require the Holder to disclose some of the claims that are blinded in the JWT.

In order to contruct the **Selective Disclosure Presentation**, the Holder can use an input file that looks like:

```json
{
    "some_disclosure": [
        "given_name",
        "family_name"
    ],
    "decoded_selective_disclosure": {
        "disclosures": [
            [
                "RLdC7X_9G2F1wWh5MV-3eg",
                "given_name",
                "Mimmo"
            ],
            [
                "LKvfDcEeWUG7_C2MpxKfIg",
                "family_name",
                "Lippo"
            ],
            [
                "9RZKoww0KRG2B3pifootyA",
                "birth_date",
                640856800
            ],
            [
                "OuTKYvHV8Y0vYf2xey9X-Q",
                "above_18",
                true
            ]
        ],
        "jwt": {
            "header": {
                "alg": "ES256",
                "typ": "vc+sd-jwt"
            },
            "payload": {
                "_sd": [
                    "M3RP6ySmblfFkv27XzNPmN5F6W_NsupnlpaAqeWPYho",
                    "72sgBajcha4T0FWC7an7DKxciCKXcyhmHCbt7XkTFRs",
                    "jL4iW-7zzPMc7Qjlh2Ct_RWFN0vPjacptJ8w-RHgR88",
                    "szIFS-AzE6PR7b0MsNVybDZ2-4cjiWduyzXFIN1S-70"
                ],
                "_sd_alg": "sha-256",
                "exp": 1903161721,
                "iat": 1713859327,
                "iss": "http://example.org",
                "sub": "user 42"
            },
            "signature": "hek_HnH0jb2wYimlJfZhqLYOD66tFScj-9CgbV1JlIYma5G5IhFYzmYIw6NqLo_htJF10kGItSkzbP2YRB0IYQ"
        }
    }
}
```

Then it can execute the following contract:

```gherkin
Scenario 'sd_jwt': create presentation

Given I have a 'decoded selective disclosure'
Given I have a 'string array' named 'some disclosure'
When I use signed selective disclosure 'decoded_selective_disclosure' only with disclosures 'some disclosure'

Then print the 'decoded selective disclosure'
```

This return the output:

```json
{
  "decoded_selective_disclosure": {
    "disclosures": [
      [
        "RLdC7X_9G2F1wWh5MV-3eg",
        "given_name",
        "Mimmo"
      ],
      [
        "LKvfDcEeWUG7_C2MpxKfIg",
        "family_name",
        "Lippo"
      ]
    ],
    "jwt": {
      "header": {
        "alg": "ES256",
        "typ": "vc+sd-jwt"
      },
      "payload": {
        "_sd": [
          "M3RP6ySmblfFkv27XzNPmN5F6W_NsupnlpaAqeWPYho",
          "72sgBajcha4T0FWC7an7DKxciCKXcyhmHCbt7XkTFRs",
          "jL4iW-7zzPMc7Qjlh2Ct_RWFN0vPjacptJ8w-RHgR88",
          "szIFS-AzE6PR7b0MsNVybDZ2-4cjiWduyzXFIN1S-70"
        ],
        "_sd_alg": "sha-256",
        "exp": 1903161721,
        "iat": 1713859327,
        "iss": "http://example.org",
        "sub": "user 42"
      },
      "signature": "hek_HnH0jb2wYimlJfZhqLYOD66tFScj-9CgbV1JlIYma5G5IhFYzmYIw6NqLo_htJF10kGItSkzbP2YRB0IYQ"
    }
  }
}
```

## Credential Verification

A Verifier that wants to validate the credential of a partecipant needs the Holder SD-prensentation and the Issuer public key to verify the signature.
So given an input file like:

```json
{
    "The Issuer": {
        "es256_public_key": "gyvKONZZiFmTUbQseoJ6KdAYJPyFixv0rMXL2T39sawziR3I49jMp/6ChAupQYqZhYPVC/RtxBI+tUcULh1SCg=="
    },
    "signed_selective_disclosure": {
        "disclosures": [
            [
                "RLdC7X_9G2F1wWh5MV-3eg",
                "given_name",
                "Mimmo"
            ],
            [
                "LKvfDcEeWUG7_C2MpxKfIg",
                "family_name",
                "Lippo"
            ],
            [
                "9RZKoww0KRG2B3pifootyA",
                "birth_date",
                640856800
            ],
            [
                "OuTKYvHV8Y0vYf2xey9X-Q",
                "above_18",
                true
            ]
        ],
        "jwt": {
            "header": {
                "alg": "ES256",
                "typ": "vc+sd-jwt"
            },
            "payload": {
                "_sd": [
                    "M3RP6ySmblfFkv27XzNPmN5F6W_NsupnlpaAqeWPYho",
                    "72sgBajcha4T0FWC7an7DKxciCKXcyhmHCbt7XkTFRs",
                    "jL4iW-7zzPMc7Qjlh2Ct_RWFN0vPjacptJ8w-RHgR88",
                    "szIFS-AzE6PR7b0MsNVybDZ2-4cjiWduyzXFIN1S-70"
                ],
                "_sd_alg": "sha-256",
                "exp": 1903161721,
                "iat": 1713859327,
                "iss": "http://example.org",
                "sub": "user 42"
            },
            "signature": "hek_HnH0jb2wYimlJfZhqLYOD66tFScj-9CgbV1JlIYma5G5IhFYzmYIw6NqLo_htJF10kGItSkzbP2YRB0IYQ"
        }
    }
}
```

One can use a script like the following to verify the validity of the presented credential:

```gherkin
Scenario 'sd_jwt': verify presentation
Scenario 'es256': public key

Given I am known as 'The Issuer'
Given I have my 'es256 public key'

Given I have a 'decoded selective disclosure' named 'signed selective disclosure'

When I verify signed selective disclosure 'signed_selective_disclosure' issued by 'The Issuer' is valid

Then print data
```
# Testnet vs Mainnet

There are format difference between Bitcoin *testnet* and *mainnet*. We wanted to enable both the networks, making it comfortable for the developer to switch from one to another (note: keys and protocols have slight differences between testnet and mainnet. 

For this reason in any statement that is specific for the network, by swapping the word **testnet** with **bitcoin**, you change the way the statement works.  

For example, In order to create a **key for the testnet**, you can use the statement 

```gherkin
When I create the testnet key
```

On the other hand, to **create a key for mainnet** you can use:

```gherkin
When I create the bitcoin key
```

The example below is created for the **testnet** as we believe that's a convenient starting point.

Note: you don't need to define a scenario, as the zencode statements for **bitcoin are always loaded**. 


# Key generation

On this page we prioritize security over easy of use, therefore we have chosen to keep some operations separated. 

Particularly the generation of private and public key (and the creation and signature of transactions, further down), which can indeed be merged into one script, but you would end up with both the keys in the same output. 

## Private key
The script below generates a **bitcoin testnet** private key. 

Note: you don't need to declare your identity using the statement ***Given I am 'User1234'***, but you can still do it if it comes handy, and then use the statement ***Then print my 'keys'*** to format the output.

```gherkin
Given nothing
When I create the testnet key
Then print the 'keys'
```

The output should look like this: 

```json
{ "keyring": { "testnet": "cPW7XRee1yx6sujBWeyZiyg18vhhQk9JaxxPdvwGwYX175YCF48G" } }
```

You want to store this into the file 
<a href="../_media/examples/zencode_cookbook/bitcoin/keys.json" download>keys.json</a>

### Generate a private key from a known seed 

Key generation in Zenroom uses by default a pseudo-random as seed, that is internally generated. 

You can also opt to use a seed generated elsewhere, for example by using the [keypairoom](https://github.com/ledgerproject/keypairoom) library or it's [npm package](https://www.npmjs.com/package/keypair-lib). 

The statements looks like:

```gherkin
When I create the testnet key with secret key 'mySeed'
```
Which requires you to load a 32 bytes long *base64* object named 'mySeed', the statement is defined [here](https://github.com/dyne/Zenroom/blob/master/src/lua/zencode_bitcoin.lua#L156).



## Public key 

Once you have created a private key, you can feed it to the following script to generate the public key:


```gherkin
Given I have the 'keys'
When I create the testnet public key
Then print the 'testnet public key'
```


The output should look like this: 

```json
{"testnet_public_key":"AndrWMNBRclVO1I1/iEaYjfEi5C0eEvG2GZgsCNq87qy"}
```

You want to store this into the file 
<a href="../_media/examples/zencode_cookbook/bitcoin/pubkey.json" download>pubkey.json</a>


# Create testnet address


Next, you'll need to generate a **bitcoin testnet address**, you'll need the <a href="../_media/examples/zencode_cookbook/bitcoin/keys.json" download>keys.json</a> you've just generated as input to the following script: 

```gherkin
Given I have the 'keys'
When I create the testnet address
Then print the 'testnet address'
```


The output should look like: 

```json
{"testnet_address":"tb1qc5wzp53l39v499nvycmcvu2aaqlu84xnkhq3dv"}
```


# The transaction: setup and execution

The statements used to manage a transaction, follow closely the logic of the Bitcoin protocol. What we'll do here is:

* Prepare a JSON file containing the **amount** to be transferred, **recipient, sender and fee**.
* **Add to the JSON file a list of the unspent transactions**, as it is returned from a Bitcoin explorer (we're using Blockstream in the test).
* Then we use the file above, to create a **testnet transaction**.
* After creating the transaction, first we'll **sign it** using the key we generated above, then we'll create a **raw transaction** out of it, which can be posted to any Bitcoin client. 


## Load amount, recipient, sender and fee

Now prepare a JSON file containing the amount, recipient, fee and sender: the sender in this example is the one we have just generated as **testnet_address**. The file should look like this: 

```json
{
  "satoshi amount": "1",
  "satoshi fee": "141",
  "recipient": "tb1q73czlxl7us4s6num5sjlnq6r0yuf8uh5clr2tm",
  "sender": "tb1qc5wzp53l39v499nvycmcvu2aaqlu84xnkhq3dv"
}
```

## Load unspent transaction

Then, get a **list of the unspent transactions from your address**, which is again the **testnet_address** we have generated above, but at this point we have already transferred some coins to this address (otherwise the list of unspent transactions would be empty). In the example we ***curl*** blockstream.info with the address we generated above:

```
curl -s https://blockstream.info/testnet/api/address/tb1qc5wzp53l39v499nvycmcvu2aaqlu84xnkhq3dv/utxo
```


The result should be a JSON file looking like: 

```json
{
  "satoshi unspent": [{"txid":"dd6d3c58fe0cd8729e731545830307fcdd36620c14bc5988308e0485d23ea53c","vout":1,"status":{"confirmed":true,"block_height":2103197,"block_hash":"0000000000000004e0ff305a04c1b23e26cf4c6a903b2304eb58a8b18c81414d","block_time":1636388875},"value":79716},{"txid":"f435e5f2139b7a919b51ee6950b82f8b60031158960d66ec67135320d68f54a2","vout":1,"status":{"confirmed":true,"block_height":2102869,"block_hash":"000000000000f4cb5540d429d37e3716317acc34f071a90f14c8a4536716382e","block_time":1636187124},"value":1563967},{"txid":"63145fe24a787a25e721e6be4fc3db08dbec21f7924d54d68d139c6506f509f7","vout":0,"status":{"confirmed":true,"block_height":2102869,"block_hash":"000000000000f4cb5540d429d37e3716317acc34f071a90f14c8a4536716382e","block_time":1636187124},"value":80000},{"txid":"98aea64e8c923240f8abc9af577bd68ecc5a20d9f6b1b6d8e174a57b68d825bf","vout":1,"status":{"confirmed":true,"block_height":2103471,"block_hash":"00000000000000287d5251d6be9a8d8f18fdf91bb4e20a14471a025384d593a8","block_time":1636567249},"value":96560},{"txid":"7166ff2dd8cd0893253c984c031896335d68f31d18aafffb1020f024735fc5c9","vout":1,"status":{"confirmed":true,"block_height":2102869,"block_hash":"000000000000f4cb5540d429d37e3716317acc34f071a90f14c8a4536716382e","block_time":1636187124},"value":100000},{"txid":"592c35a7e710828746988926317f6929073ece459b55f935e0a8091b97564f24","vout":1,"status":{"confirmed":true,"block_height":2101106,"block_hash":"0000000000000020e76792ea88ad80ed6cf634b9bc08f0adc2cc7c8db5f22a5a","block_time":1635376667},"value":995036},{"txid":"60431824fa7a2b085b7cabf72bbaa3cfe97ffe69708e0d8bccbe5c301eed30e5","vout":1,"status":{"confirmed":true,"block_height":2103470,"block_hash":"0000000000003317181c3239426b7e9a1aed9164cb4726b2777ca50b2c54309d","block_time":1636566498},"value":79716},{"txid":"17a37cdbab83718435a0bebd747337a943add4af34b9c124c14f679b5a0b1cd0","vout":0,"status":{"confirmed":true,"block_height":2101201,"block_hash":"000000000001aad40c5be20f667630f2a85dc0da3003c4605bdb628ee180c325","block_time":1635436736},"value":100000},{"txid":"3fcdad9b6289fbba25d306fadac78062949c63164eabd35e4541c3f84992ffb1","vout":12,"status":{"confirmed":true,"block_height":2102981,"block_hash":"000000000000000f9e0f2e29a4756a7564a38eade977d5253271c41fa8de2760","block_time":1636256674},"value":3527419}]
}
```

Now merge the <a href="../_media/examples/zencode_cookbook/bitcoin/transaction_data.json" download>transaction_data.json</a>
  and <a href="../_media/examples/zencode_cookbook/bitcoin/unspent.json" download>unspent.json</a>  two files together into <a href="../_media/examples/zencode_cookbook/bitcoin/order.json" download>order.json</a>. 
  
You can do so for example by using **jq**: 
 
```bash
 jq -s '.[0] * .[1]' unspent.json  transaction_data.json
```

## Create the transaction 

Now, you can feed the file **order.json** to the script:

```gherkin
Given I have a 'testnet address' named 'sender'
and I have a 'testnet address' named 'recipient'
and a 'satoshi fee'
and a 'satoshi amount'
and a 'satoshi unspent'
When I rename 'satoshi unspent' to 'testnet unspent'
and I create the testnet transaction
Then print the 'testnet transaction'
```


Which will produce an unsigned transaction, formatted in human-readable JSON, that should look like:

```json
{"testnet_transaction":{"nHashType":"AAAAAQ==","nLockTime":0,"txIn":[{"address":{"raw":"xRwg0j+JWVKWbCY3hnFd6D/D1NM="},"amountSpent":"ATdk","sequence":"/////w==","sigwit":"AQ==","txid":"3W08WP4M2HKecxVFgwMH/N02YgwUvFmIMI4EhdI+pTw=","vout":1}],"txOut":[{"address":{"raw":"9HAvm/7kKw1Pm6Ql+YNDeTiT8vQ="},"amount":"AQ=="},{"address":{"raw":"xRwg0j+JWVKWbCY3hnFd6D/D1NM="},"amount":"ATbW"}],"version":2}}
```

If the recipient address is saved under a name other than **recipient** then the transaction can be created using the statement:

```gherkin
When I create the testnet transaction to ''
```

## Sign the transaction and format as raw transaction 

You can now pass the transaction produced from the above script, along with <a href="../_media/examples/zencode_cookbook/bitcoin/keys.json" download>keys.json</a> to the following script that will sign the transaction and format it so that we can pass it to any Bitcoin node. 

```gherkin
Given I have the 'keys'
and I have a 'base64 dictionary' named 'testnet transaction'
When I sign the testnet transaction
and I create the testnet raw transaction
and I create the size of 'testnet raw transaction'
Then print the 'testnet raw transaction' as 'hex'
```

The signed transaction should look like:

```json
{"testnet_raw_transaction":"020000000001013ca53ed285048e308859bc140c6236ddfc0703834515739e72d80cfe583c6ddd0100000000ffffffff020100000000000000160014f4702f9bfee42b0d4f9ba425f98343793893f2f4d636010000000000160014c51c20d23f895952966c263786715de83fc3d4d30248304502210084b8f57ea1820ab190e0171c0bb95b99c084828d87f98a8c71d653a0a7aaf2dd02203328fb692b7f07c6066a18f98b740cfdf8f7dbadaa73d34421311c7709664134012102776b58c34145c9553b5235fe211a6237c48b90b4784bc6d86660b0236af3bab200000000"}
```

**Note: this script and the previous one can be merged** into one script that creates the transaction, signs it and prints it out as raw transaction. 

In this example we kept the script separated as this script was originally meant to demonstrate how to make an **offline Bitcoin wallet**, where the signature happens on different machine (which can be kept offline for security reasons). You can merge the two scripts and feed the resulting script with <a href="../_media/examples/zencode_cookbook/bitcoin/keys.json" download>keys.json</a> we created on top of this page and <a href="../_media/examples/zencode_cookbook/bitcoin/order.json" download>order.json</a>



# The script used to create the material in this page

All the smart contracts and the data you see in this page are generated by the scripts [bitcoin.bats](https://github.com/dyne/Zenroom/blob/master/test/zencode/bitcoin.bats) . If you want to run the scripts (on Linux) you should: 
 - *git clone https://github.com/dyne/Zenroom.git*
 - install  **jq**
 - download a [zenroom binary](https://zenroom.org/#downloads) and place it */bin* or */usr/bin* or in *./Zenroom/src*




<!-- Temp removed, 

We grouped together all the statements that perform object manipulation, so: 


 ***Math operations***: sum, subtraction, multiplication, division and modulo, between numbers
 
 ***Invert sign*** invert the sign of a number 
 
 ***Append*** a simple object to another
 
 ***Rename*** an object
  
 ***Delete*** an object from the memory stack
 
 ***Copy*** an object into new object
 
 ***Split string*** using leftmost or rightmost bytes
 
 ***Randomize*** the elements of an array
 
 ***Create string/number*** (statement "write in")
 
 ***Pick a random element*** from an array
 



-->
### 
# Key generation

On this page we prioritize security over easy of use, therefore we have chosen to keep some operations separated.

Particularly the generation of private and public key (and the creation and signature of transactions, further down), which can indeed be merged into one script, but you would end up with both the keys in the same output.

## Private key
The script below generates a **ethereum** private key.

Note: you don't need to declare your identity using the statement ***Given I am 'User1234'***, but you can still do it if it comes handy, and then use the statement ***Then print my 'keys'*** to format the output.

```gherkin
Scenario ethereum
Given nothing
When I create the ethereum key
Then print the 'keyring'
```

The output should look like this:

```json
{"keyring":{"ethereum":"078ad84d6c7a50c6dcd983d644da65e30d8cea063d8ea49aeb7ee7f0aaf6a4f7"}}
```

You want to store this into the file
<a href="../_media/examples/zencode_cookbook/ethereum/alice_keys.json" download>keys.json</a>

### Generate a private key from a known seed

Key generation in Zenroom uses by default a pseudo-random as seed, that is internally generated. 

You can also opt to use a seed generated elsewhere, for example by using the [keypairoom](https://github.com/ledgerproject/keypairoom) library or its [npm package](https://www.npmjs.com/package/keypair-lib). Suppose you have an Ethereum private key:

```json
{
	"ethereum private key": "150ad66741dd4f917d1e7877e2cb5d47ce1baa8e635b41675fa4f1ca51b681bb"
}
```

Then you can upload it with a script that looks like the following script:

```gherkin
Scenario ethereum
Given I have a 'hex' named 'ethereum private key'

# here we upload the key
When I create the ethereum key with secret key 'ethereum private key'
# an equivalent statement is
# When I create the ethereum key with secret 'ethereum private key'

Then print the keyring
```

## Get a private key by password
If we use [private ethereum blockchain](https://medium.com/scb-digital/running-a-private-ethereum-blockchain-using-docker-589c8e6a4fe8), then our keyring located in docker conteiner: geth-miner.

Path like that: /root/.ethereum/keystore/UTC--2024-07-16T10-09-46.525942921Z--e...1

Usually, access from the network is not possible to this file. But there is more or less [standard access](https://github.com/ethereum/go-ethereum/blob/master/cmd/clef/tutorial.md)

The following script allows you to log in using only a password and automatically receives keyrings already generated by the miner.


```
from web3 import Web3
import eth_keys
from eth_account import account
from zenroom import zenroom
import json

password = 'My_pass'
keyfile = open('./UTC--2024-07-16T10-09-46.525942921Z--e...1')
keyfile_contents = keyfile.read()
keyfile.close()


private_key = eth_keys.keys.PrivateKey(account.Account.decrypt(keyfile_contents, password))
print(private_key)
public_key = private_key.public_key
print(public_key)

private_key_str = str(private_key)

conf = ""

keys = {
    "participant": {
        "keyring": {
            "ethereum": private_key_str
        }
    }
}

data = {
}





contract = """Scenario ethereum: sign ethereum message

# Here we are loading the private key and the message to be signed
Given I am 'participant'
Given I have my 'keyring'
When I create the ethereum address
Then print my 'ethereum address'
Then print the keyring
"""

result = zenroom.zencode_exec(contract, conf, json.dumps(keys), json.dumps(data))
print(result.output)
```


## Public key

Ethereum does not use explicitly a public key, it uses it only to create an Ethereum address that represents an account. So in Zencode there are no sentences to produce the public keys, but only the address.

If, for any reason, you need the ethereum public key, then you can simply compute it by understanding that the Ethereum private key is an ECDH private key so the following script will do the trick:

```gherkin
Scenario ecdh
Scenario ethereum

# load the ethereum key
Given I have a 'hex' named 'ethereum' in 'keyring'

# create the ecdh public key
When I create the ecdh key with secret key 'ethereum'
When I create the ecdh public key
# rename it to ethereum public key
and I rename the 'ecdh public key' to 'ethereum public key'

# print the ethereum public key as hex
Then print the 'ethereum public key' as 'hex'
```



# Create Ethereum address


The **Ethereum address** is derived as the last 20 bytes of the public key controlling the account.
The **Ethereum address** is represented as an hexadecimal string with encoding given by [ERC-55](https://eips.ethereum.org/EIPS/eip-55). The public key is produced starting from the private key so you'll need the <a href="../_media/examples/zencode_cookbook/ethereum/alice_keys.json" download>keys.json</a> you've just generated as input to the following script: 

```gherkin
Scenario ethereum
Given I am known as 'alice'
and I have the 'keyring'
When I create the ethereum address
Then print my 'ethereum address'
```

The output should look like:

```json
{"alice":{"ethereum_address":"0x0Ba910bA5FcceD2A2538718367ea0A57C0ca881A"}}
```

It is also possible to verify that a given string is a valid **Ethereum address** and also load it by running the following script:

```gherkin
Scenario ethereum

# To verify the address you have to upload it as a string
Given I have a 'string' named 'ethereum address'
Given I rename 'ethereum address' to 'address string'

# To use it you simply write the following statement.
Given I have a 'ethereum address'

When I verify the ethereum address string 'address string' is valid
# Insert here other "When" statements which use 'ethereum address'

Then print the 'ethereum address'
Then print the string 'The address has a valid encoding'
```

The output should look like:

```json
{"ethereum_address":"0x1e30e53E87869aaD8dC5A1A9dAc31a8dD3559460","output":["The_address_has_a_valid_encoding"]}
```

# The transaction: setup and execution

The statements used to manage a transaction, follow closely the logic of the Ethereum protocol. With Ethereum we can store data on the chain or transfer eth from an address to another. What we'll do here is:

* Prepare a JSON file containing:
  * the **ethereum nonce**, it is the number of transactions sent from the sender address
  * the **gas price**
  * the **gas limit**
  * the **recipient address**
* If the transaction is used to store data then we will add to the JSON file the **data**
* Otherwise if it used to transfer eth we will add the value of the transaction which can be  expressed in wei (**wei value**), gwei (**gwei value**) or eth (**ethereum value**)
* Then we use the file above, to create a **ethereum transaction**.
* Finally we'll **sign** it using the key we generated above.

## First step: JSON file

Now prepare a JSON file containing the nonce, the gas price and the gas limit. The file should look like this:

```json
    { "ethereum nonce": "0",
      "gas price": "100000000000",
      "gas limit": "300000"
    }
```

## Create the transaction

### Eth transfer

Now, if you want to transfer eth, then you will need to add the recipient address and the value to be transferred in the JSON file. That will look like:

```json
{
  "ethereum nonce": "0",
  "gas price": "100000000000",
  "gas limit": "300000",
  "gwei value": "10",
  "bob": {
    "ethereum_address": "0x0Ba910bA5FcceD2A2538718367ea0A57C0ca881A"
  }
}
```

you can feed the above JSON to the script:

```gherkin
Scenario ethereum

# Load the JSON file
Given I have a 'ethereum address' inside 'bob'
and a 'gas price'
and a 'gas limit'
and an 'ethereum nonce'
and a 'gwei value'

# Create the ethereum transaction
When I create the ethereum transaction of 'gwei value' to 'ethereum address'

Then print the 'ethereum transaction'
```

Which will produce an unsigned transaction, formatted in human-readable JSON, that should look like:

```json
{"ethereum_transaction":{"gas_limit":"300000","gas_price":"100000000000","nonce":"0","to":"0x0Ba910bA5FcceD2A2538718367ea0A57C0ca881A","value":"10000000000"}}
```

### Data storage

On the other hand, if you want to store data on the chain then you will add to the JSON file a **storage contract address** and the **data** to be stored. The file should look like this:

```json
{
  "ethereum nonce": "0",
  "gas price": "100000000000",
  "gas limit": "300000",
  "storage_contract": "0xE54c7b475644fBd918cfeDC57b1C9179939921E6",
  "data": "This is my first data stored on ethereum blockchain"
}
```

you can feed the above JSON to the script:

```gherkin
Scenario ethereum

# Load  the JSON file
Given I have a 'ethereum address' named 'storage contract'
and a 'gas price'
and a 'gas limit'
and an 'ethereum nonce'
and a 'string' named 'data'

# Create the ethereum transaction
When I create the ethereum transaction to 'storage contract'
# use it to store the data
and I use the ethereum transaction to store 'data'

Then print the 'ethereum transaction'
```


Which will produce an unsigned transaction, formatted in human-readable JSON, that should look like:

```json
{"ethereum_transaction":{"data":"b374012b0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000003354686973206973206d7920666972737420646174612073746f726564206f6e20657468657265756d20626c6f636b636861696e00000000000000000000000000","gas_limit":"300000","gas_price":"100000000000","nonce":"0","to":"0xE54c7b475644fBd918cfeDC57b1C9179939921E6","value":"0"}}
```

The data stored in this case was a **string** because ethereum allows only array of bytes as data and the string is the simplest example of that. However you can upload the type of data that you want (array or dictionaries) and then use [mpack](https://dev.zenroom.org/#/pages/zencode-cookbook-when) to serialize it before uploading it in the ethereum transaction.


## Sign the transaction

You can now pass the **transaction** produced from the above script (here we are using the transaction created to store the data), along with <a href="../_media/examples/zencode_cookbook/ethereum/alice_keys.json" download>keys.json</a> to the following script that will sign the transaction for a specific chain with **chain id** specified in the statement and produce the raw transaction. Here, for example, we are using fabt as **chain id** (https://github.com/dyne/fabchain).

```gherkin
scenario ethereum

# Load the private key and the transaction
given I have the 'keyring'
and I have a 'ethereum transaction'

# sign the transaction for the chain with chain id 'fabt'
when I create the signed ethereum transaction for chain 'fabt'

then print the 'signed ethereum transaction'
```

The signed raw transaction should look like:

```json
{"signed_ethereum_transaction":"f8ee8085174876e800830493e094e54c7b475644fbd918cfedc57b1c9179939921e680b884b374012b0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000003354686973206973206d7920666972737420646174612073746f726564206f6e20657468657265756d20626c6f636b636861696e0000000000000000000000000084ccc2c50ca0776b58c34145c9553b5235fe211a6237c48b90b4784bc6d86660b0236af3bab2a07b57259d71f12666d962eb7a06b2b8332323a614071d0b39c35181b2aee04b8e"}
```

**Note: this script and the previous one can be merged** into one script that creates the transaction, signs it and prints it out.

Moreover, if you want to sign the transaction for the local testnet you can use the following script:

```gherkin
scenario ethereum

# Load the private key and the transaction
given I have the 'keyring'
and I have a 'ethereum transaction'

# sign the transaction for the local testnet
when I create the signed ethereum transaction

then print the 'signed ethereum transaction'
```

that use 1337 as default chain id.

## Broadcast and read ethereum transactions

Once you have created your signed ethereum transaction then you can use [RESTroom-mw](https://dev.zenroom.org/#/pages/restroom-mw) to connect to a node and broadcast your transaction in the Ethereum chain you have chosen. Obviously you have to have some Eth in your address to broadcast the transaction, if you want to do some test you can use the [fabchain](https://github.com/dyne/fabchain) test network, where you can claim 1 eth per day inserting your ethereum address [here](http://test.fabchain.net:5000/).

Now that you have broadcasted your transaction you can use also RESTroom-mw to retrieve the data stored in the transaction, but the data you will get will be of the form:

```json
{
  "data": "0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000003354686973206973206d7920666972737420646174612073746f726564206f6e20657468657265756d20626c6f636b636861696e00000000000000000000000000"
}
```

and we can read the original data with the following script:

```gherkin
Scenario ethereum
Given I have a 'hex' named 'data'
When I create the 'data retrieved' decoded from ethereum bytes 'data'
Then print the 'data retrieved' as 'string'
```

The output will be:

```json
{"data_retrieved":"This is my first data stored on ethereum blockchain"}
```

# The ethereum signature

A user may want to sign an object different from a transaction, and may want others to be able to verify such signature using only the ethereum address. 

**Note:** the resulting ethereum signature uses the ECDSA deterministic algorithm as specified in [RFC-6979](https://www.rfc-editor.org/rfc/rfc6979).

## Creation of the signature

Given a string of which we want to compute the signature, assuming that the user already has an ethereum private key in the keyring, the signature can be created using the following script:

```gherkin
Scenario ethereum

Given I have a 'keyring'
Given I have a 'ethereum address'
Given I have a 'string' named 'myString'

When I create the ethereum signature of 'myString'

Then print the 'ethereum signature'
Then print the 'ethereum address'
Then print the 'myString'
```

The output should look like:

```json
{"ethereum_address":"0x380FfB13F42AfFBE88949643B27FA74Ba85B3977","ethereum_signature":"0x19373b64e400e237dd7fb23e76621675f8691c0eb14aa171a82f69593b1a2a0536203582c38585754a785ca504f51e4178bab5cc3f566e985358eaf7cb5d78761b","myString":"I love the Beatles, all but 3"}
```

**Note**: the *ethereum signature* can be encoded both as a single hexadecimal string or as a table containing three values *r*, *s*, and *v*. Zenroom can load and print ethereum signatures in both the encodings.

The following script shows how to print the tabular encoding:

```gherkin
Scenario ethereum

Given I have a 'ethereum signature'

Then print the 'ethereum signature' as 'ethereum signature table'

```

The output should look like:

```json
{"ethereum_signature":{"r":"19373b64e400e237dd7fb23e76621675f8691c0eb14aa171a82f69593b1a2a05","s":"36203582c38585754a785ca504f51e4178bab5cc3f566e985358eaf7cb5d7876","v":"27"}}
```

## Verification

Given the ethereum signature of the string and the ethereum address, anyone may verify the signature using the following script:

```gherkin
Scenario ethereum

Given I have a 'ethereum signature'
Given I have a 'ethereum address'
Given I have a 'string' named 'myString'

When I verify the 'myString' has a ethereum signature in 'ethereum signature' by 'ethereum address'

Then print the string 'The signature is valid'
```

When the signature is correct, the output will be:

```json
{"output":["The_signature_is_valid"]}
```

## Multiple signatures verification

Given an array that contains pairs of ethereum address and signature and a signed message

```
{
    "addresses_signatures": [
        {
            "address": "0x2B8070975AF995Ef7eb949AE28ee7706B9039504",
            "signature": {
                "r": "ed8f36c71989f8660e8f5d4adbfd8f1c0288cca90d3a5330b7bf735d71ab52fe",
                "s": "7ba0a7827dc4ba707431f1c10babd389f658f8e208b89390a9be3c097579a2ff",
                "v": "27"
            }
        },
        {
            "address": "0x3028806AC293B5aC9b863B685c73813626311DaD",
            "signature": {
                "r": "40d305373c648bb6b2bbadebe02ada256a9d0b3d3c37367c0a2795e367b22f73",
                "s": "72e40dfc3497927764d1585783d058e4367bb4d24d2107777d7aa4ddcb6593c7",
                "v": "27"
            }
        },
        {
            "address": "0xe1C2F1ACb2758c4D88EDb84e0306A0a96682E62a",
            "signature": {
                "r": "9e07477c31db612e8c99a950385162373ff41a5b8941470b1aeba43b76c53570",
                "s": "05fce6615567dc1944cc02fbed86202b09d92d79fbade425af0d74c328d8f6ae",
                "v": "28"
            }
        }
    ],
	"signed_string": "I love the Beatles, all but 3"
}
```

anyone may verify all the signatures using the following script:

```gherkin
    Scenario ethereum: verify sig
    Given I have a 'ethereum address signature pair array' named 'addresses_signatures'
    Given I have a 'string' named 'signed_string'

    When I verify the ethereum address signature pair array 'addresses_signatures' of 'signed_string'

    Then print the string 'ok'
```

This code will fail if at least one signature is not verified, to obtain a list that associates each address to the result of the verification the following script can be used:

```gherkin
    Scenario ethereum: verify sig
    Given I have a 'ethereum address signature pair array' named 'addresses_signatures'
    Given I have a 'string' named 'signed_string'

    When I use the ethereum address signature pair array 'addresses_signatures' to create the result array of 'signed_string'

    Then print the 'result_array'
```

For example with the following data, where the last signature is the copy of the third one in which the *v* parameter is set to 27 instead of 28, *i.e.* is not a valid signature:

```
{
    "addresses_signatures": [
        {
            "address": "0x2B8070975AF995Ef7eb949AE28ee7706B9039504",
            "signature": {
                "r": "ed8f36c71989f8660e8f5d4adbfd8f1c0288cca90d3a5330b7bf735d71ab52fe",
                "s": "7ba0a7827dc4ba707431f1c10babd389f658f8e208b89390a9be3c097579a2ff",
                "v": "27"
            }
        },
        {
            "address": "0x3028806AC293B5aC9b863B685c73813626311DaD",
            "signature": {
                "r": "40d305373c648bb6b2bbadebe02ada256a9d0b3d3c37367c0a2795e367b22f73",
                "s": "72e40dfc3497927764d1585783d058e4367bb4d24d2107777d7aa4ddcb6593c7",
                "v": "27"
            }
        },
        {
            "address": "0xe1C2F1ACb2758c4D88EDb84e0306A0a96682E62a",
            "signature": {
                "r": "9e07477c31db612e8c99a950385162373ff41a5b8941470b1aeba43b76c53570",
                "s": "05fce6615567dc1944cc02fbed86202b09d92d79fbade425af0d74c328d8f6ae",
                "v": "28"
            }
        },
        {
            "address": "0xe1C2F1ACb2758c4D88EDb84e0306A0a96682E62a",
            "signature": {
                "r": "9e07477c31db612e8c99a950385162373ff41a5b8941470b1aeba43b76c53570",
                "s": "05fce6615567dc1944cc02fbed86202b09d92d79fbade425af0d74c328d8f6ae",
                "v": "27"
            }
        }
    ],
    "signed_string": "I love the Beatles, all but 3"
}
```

the result is

```
{"result_array":[{"address":"0x2B8070975AF995Ef7eb949AE28ee7706B9039504","status":"verified"},{"address":"0x3028806AC293B5aC9b863B685c73813626311DaD","status":"verified"},{"address":"0xe1C2F1ACb2758c4D88EDb84e0306A0a96682E62a","status":"verified"},{"address":"0xe1C2F1ACb2758c4D88EDb84e0306A0a96682E62a","status":"not verified"}]}
```

## Sign complex object

It could be the case that one wants to sign an object different from a string or a transaction.
This is an example of the data which a user could sign:

```
{
    "address": "77c2f9730B6C3341e1B71F76ECF19ba39E88f247",
    "vote": "234",
    "typeSpec": ["address", "string"]
}
```

Given the above data, a user can first compute the hash of the ABI encoding of the data.  
This can be achieved using the following script:

```gherkin
Scenario ethereum

Given I have a 'hex' named 'address'
Given I have a 'string' named 'vote'
Given I have a 'string array' named 'typeSpec'

When I create the new array
When I move 'address' in 'new array'
When I move 'vote' in 'new array'
When I create the ethereum abi encoding of 'new array' using 'typeSpec'
When I create the hash of 'ethereum abi encoding' using 'keccak256'

Then print the 'ethereum abi encoding'
Then print the 'hash'
```

The output should look like:

```json
{"ethereum_abi_encoding":"00000000000000000000000077c2f9730b6c3341e1b71f76ecf19ba39e88f247000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000033233340000000000000000000000000000000000000000000000000000000000","hash":"pTFYbyovWkOT6CaHSRNCN7ySQ/AGbphs9WQnZ2JwPWQ="}
```

**NOTE**: in the end one can use the same scripts as above to create and verify the signature of the obtained *hash*.


## Create the smart contract for token ERC 721 by python

To create the contract itself, you can use [OpenZeppelin Contracts Wizard](https://docs.openzeppelin.com/contracts/5.x/wizard)

You can select the token type through the bookmarks in the wizard, and select the contract features through the menu on the left.

We will get something like this code:

```
// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "./contracts/token/ERC721/ERC721.sol";
import "./contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./contracts/token/ERC721/extensions/ERC721Burnable.sol";

contract zen721 is ERC721, ERC721URIStorage, ERC721Burnable {
    uint256 private _nextTokenId;


    constructor()
        ERC721("zen721", "ZEN")
    {}

    function _baseURI() internal pure override returns (string memory) {
        return "http://example.com/api/erc721/";
    }

    function safeMint(address to, uint256 tokenId, string memory uri)
        public
    {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    // The following functions are overrides required by Solidity.

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

```

We take the source codes of the contract from the repository [openzeppelin-contracts](https://github.com/OpenZeppelin/openzeppelin-contracts)

In the contract, we replaced relative paths @openzeppelin  with the path in the current directory. To do this, we copied the directory with contracts inside the working directory.

To deploy a contract we use a script:

```
#!/usr/bin/env python

from solcx import compile_standard, install_solc
import json
import os
from web3 import Web3
import eth_keys
from eth_account import account
from dotenv import load_dotenv

def get_private_key(password='My_pass', keystore_file='a.json'):
    keyfile = open('./' + keystore_file)
    keyfile_contents = keyfile.read()
    keyfile.close()
    private_key = eth_keys.keys.PrivateKey(account.Account.decrypt(keyfile_contents, password))
    private_key_str = str(private_key)
    return private_key_str


load_dotenv()

with open("./zen721.sol", "r") as file:
    simple_storage_file = file.read()

    install_solc("0.6.2")

    compiled_sol = compile_standard(
        {
            "language": "Solidity",
            "sources": {"zen721.sol": {"content": simple_storage_file}},
            "settings": {
                "outputSelection": {
                    "*": {"*": ["abi", "metadata", "evm.bytecode", "evm.sourceMap"]}
                }
            },
        },
        solc_binary="/usr/local/lib/python3.9/site-packages/solcx/bin/solc-v0.6.2",
        allow_paths="/root/3.1.0/"
    )

with open("compiled_code.json", "w") as file:
    json.dump(compiled_sol, file)


# get bytecode
bytecode = compiled_sol["contracts"]["zen721.sol"]["zen721"]["evm"]["bytecode"]["object"]

print(bytecode)

# get abi
abi = json.loads(compiled_sol["contracts"]["zen721.sol"]["zen721"]["metadata"])["output"]["abi"]

print(abi)

# For connecting to geth_rpc
w3 = Web3(Web3.HTTPProvider(os.getenv("GETH_RPC_URL")))

#Check Connection
t=w3.is_connected()
print(t)

chain_id = int(os.getenv("NETWORK_ID"))
private_key = get_private_key()

# Create a signer wallet
PA=w3.eth.account.from_key(private_key)

# Get public address from a signer wallet
my_address = PA.address
print(my_address)

w3.eth.default_account = PA.address

#Print balance on current accaunt
BA=w3.eth.get_balance(my_address)
print(BA)

# Create the contract in Python
Zen721 = w3.eth.contract(abi=abi, bytecode=bytecode )

# Get the latest transaction
nonce = w3.eth.get_transaction_count(my_address)

# Submit the transaction that deploys the contract
transaction = Zen721.constructor().build_transaction(
    {
        "chainId": chain_id,
        "gasPrice": w3.eth.gas_price,
        "from": my_address,
        "nonce": nonce,
#        'gas': 8000000,
    }
)

# Sign the transaction
signed_txn = w3.eth.account.sign_transaction(transaction, private_key=private_key)
print("Deploying Contract!")

# Send it!
tx_hash = w3.eth.send_raw_transaction(signed_txn.rawTransaction)
# Wait for the transaction to be mined, and get the transaction receipt
print("Waiting for transaction to finish...")
tx_receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
print(f"Done! Contract deployed to {tx_receipt.contractAddress}")

#Verification that code realy deployed (With OpenZeppilin 3.1.0 all work for ERC 721)
my_code = w3.eth.get_code(tx_receipt.contractAddress)
print(f"Verify code after deployed (Must be NOT b\' \' or change gas value to maximum 8000000) {my_code}")
```

You will also need an environment file .env

GETH_RPC_URL=http://example.com:8545

The ID of Ethereum Network

NETWORK_ID=1337

The password to create and access the primary account

ACCOUNT_PASSWORD=My_pass

To deploy contract for ERC721 token, you can also use the sample [deploy.sh](https://github.com/dyne/Zenroom/blob/master/test/ethereum/deploy.sh)

Also pay attention to the following examples:
[create_erc721.sh](https://github.com/dyne/Zenroom/blob/master/test/ethereum/create_erc721.sh)
[approve_erc721.sh](https://github.com/dyne/Zenroom/blob/master/test/ethereum/approve_erc721.sh)
[transfer_erc721.sh](https://github.com/dyne/Zenroom/blob/master/test/ethereum/transfer_erc721.sh)

If you select the Ownable feature in the OpenZeppelin Contracts Wizard, then in the contract constructor you need to pass the token owner's address in string format.

Submit the transaction that deploys the contract
transaction = Zen721.constructor(my_address).build_transaction(....



## Create the smart contract for token ERC 1155 by python

To create the contract itself, you can use [OpenZeppelin Contracts Wizard](https://docs.openzeppelin.com/contracts/5.x/wizard)

You can select the token type through the bookmarks in the wizard, and select the contract features through the menu on the left.

We will get something like this code:

```
// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.0;

import "./5.0.1/contracts/token/ERC1155/ERC1155.sol";

contract zen1155 is ERC1155 {


    constructor() public ERC1155("http://example.com:8080/api/tokens/") {
    }


    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
//        onlyOwner
    {
        _mint(account, id, amount, data);
    }


}
```

We take the source codes of the contract from the repository [openzeppelin-contracts](https://github.com/OpenZeppelin/openzeppelin-contracts)

In the contract, we replaced relative paths @openzeppelin  with the path in the current directory. To do this, we copied the directory with contracts inside the working directory.

To deploy a contract we use a script:

We add option "evmVersion": "paris" for support stable version of geth Ethereum Virtual Machine (EVM).
May by your location of SmartContract OpenZeppilin repo different from  allow_paths="/root/5.0.1/". So you need change that.

```
#!/usr/bin/env python

from solcx import compile_standard, install_solc
import json
import os
from web3 import Web3
import eth_keys
from eth_account import account
from dotenv import load_dotenv

def get_private_key(password='My_pass', keystore_file='a.json'):
    keyfile = open('./' + keystore_file)
    keyfile_contents = keyfile.read()
    keyfile.close()
    private_key = eth_keys.keys.PrivateKey(account.Account.decrypt(keyfile_contents, password))
    private_key_str = str(private_key)
    return private_key_str


load_dotenv()

with open("./zen1155_oz501.sol", "r") as file:
    simple_storage_file = file.read()

    install_solc("0.8.20")

    compiled_sol = compile_standard(
        {
            "language": "Solidity",
            "sources": {"zen1155_oz501.sol": {"content": simple_storage_file}},
            "settings": {
                "outputSelection": {
                    "*": {"*": ["abi", "metadata", "evm.bytecode", "evm.sourceMap"]}
                },
                "evmVersion": "paris"
            },
        },
        solc_binary="/usr/local/lib/python3.9/site-packages/solcx/bin/solc-v0.8.20",
        allow_paths="/root/5.0.1/"
    )

with open("compiled_code.json", "w") as file:
    json.dump(compiled_sol, file)


# get bytecode
bytecode = compiled_sol["contracts"]["zen1155_oz501.sol"]["zen1155"]["evm"]["bytecode"]["object"]

# get abi
abi = json.loads(compiled_sol["contracts"]["zen1155_oz501.sol"]["zen1155"]["metadata"])["output"]["abi"]

print(abi)



# For connecting to geth_rpc
w3 = Web3(Web3.HTTPProvider(os.getenv("GETH_RPC_URL")))

#Check Connection
t=w3.is_connected()
print(f"Connected {t}")

chain_id = int(os.getenv("NETWORK_ID"))
private_key = get_private_key()

# Create a signer wallet
PA=w3.eth.account.from_key(private_key)

# Get public address from a signer wallet
my_address = PA.address
print(f"Address {my_address}")
checksum_address = w3.to_checksum_address(my_address)

#Print balance on current accaunt
BA=w3.eth.get_balance(my_address)
print(f"Balance {BA}")

# Create the contract in Python
SimpleStorage = w3.eth.contract(abi=abi, bytecode=bytecode)

# Get the latest transaction
nonce = w3.eth.get_transaction_count(my_address)

# Submit the transaction that deploys the contract
transaction = SimpleStorage.constructor().build_transaction(
    {
        "chainId": chain_id,
        "gasPrice": w3.eth.gas_price,
        "from": my_address,
        "nonce": nonce,
#        'gas': 8000000,
    }
)

# Sign the transaction
signed_txn = w3.eth.account.sign_transaction(transaction, private_key=private_key)
print("Deploying Contract!")

# Send it!
tx_hash = w3.eth.send_raw_transaction(signed_txn.rawTransaction)
# Wait for the transaction to be mined, and get the transaction receipt
print("Waiting for transaction to finish...")
tx_receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
print(f"Done! Contract deployed to {tx_receipt.contractAddress}")

#Verification that code realy deployed (With OpenZeppilin 3.1.0 all work for ERC 1155)
my_code = w3.eth.get_code(tx_receipt.contractAddress)
print(f"Verify code after deployed (Must be NOT b\' \' or change gas value to maximum 8000000) {my_code}")
```

You will also need an environment file .env

GETH_RPC_URL=http://example.com:8545

The ID of Ethereum Network

NETWORK_ID=1337

The password to create and access the primary account

ACCOUNT_PASSWORD=My_pass

For mint ERC1155 token, you can also use the sample:

```
#!/usr/bin/env python

from solcx import compile_standard, install_solc
import json
import os
from web3 import Web3
import eth_keys
from eth_account import account
from dotenv import load_dotenv
from web3.middleware import geth_poa_middleware


def get_private_key(password='My_pass', keystore_file='a.json'):
    keyfile = open('./' + keystore_file)
    keyfile_contents = keyfile.read()
    keyfile.close()
    private_key = eth_keys.keys.PrivateKey(account.Account.decrypt(keyfile_contents, password))
    private_key_str = str(private_key)
    return private_key_str


load_dotenv()

with open("./zen1155_oz501.sol", "r") as file:
    simple_storage_file = file.read()

    install_solc("0.8.20")

    compiled_sol = compile_standard(
        {
            "language": "Solidity",
            "sources": {"zen1155_oz501.sol": {"content": simple_storage_file}},
            "settings": {
                "outputSelection": {
                    "*": {"*": ["abi", "metadata", "evm.bytecode", "evm.sourceMap"]}
                },
                "evmVersion": "paris"
            },
        },
        solc_binary="/usr/local/lib/python3.9/site-packages/solcx/bin/solc-v0.8.20",
        allow_paths="/root/5.0.1/"
    )

with open("compiled_code.json", "w") as file:
    json.dump(compiled_sol, file)


# get bytecode
bytecode = compiled_sol["contracts"]["zen1155_oz501.sol"]["zen1155"]["evm"]["bytecode"]["object"]

# get abi
abi = json.loads(compiled_sol["contracts"]["zen1155_oz501.sol"]["zen1155"]["metadata"])["output"]["abi"]

print(abi)


# For connecting to geth_rpc
w3 = Web3(Web3.HTTPProvider(os.getenv("GETH_RPC_URL")))

#Check Connection
t=w3.is_connected()
print(f"Connected {t}")


chain_id = int(os.getenv("NETWORK_ID"))
private_key = get_private_key()

# Create a signer wallet
PA=w3.eth.account.from_key(private_key)

# Get public address from a signer wallet
my_address = PA.address
print(f"Account {my_address}")

#Print balance on current accaunt
BA=w3.eth.get_balance(my_address)
print(f"Balance {BA}")

# Create the contract in Python
SimpleStorage = w3.eth.contract(abi=abi, bytecode=bytecode)

# Get the latest transaction
nonce = w3.eth.get_transaction_count(my_address)

# Submit the transaction that deploys the contract
#transaction = SimpleStorage.constructor(my_address).build_transaction(
transaction = SimpleStorage.constructor().build_transaction(
    {
        "chainId": chain_id,
        "gasPrice": w3.eth.gas_price,
        "from": my_address,
        "nonce": nonce,
        'gas': 2000000,
    }
)

# Address of SmartContract in SMART_CONTRACT
nft_contract = w3.eth.contract(address=os.getenv('SMART_CONTRACT'), abi=abi)
print(f"Contract {os.getenv('SMART_CONTRACT')}")

nonce = w3.eth.get_transaction_count(my_address)
print(f"Nonce : {nonce}")

dict_transaction = {
  'chainId': w3.eth.chain_id,
  'from': my_address,
  'gasPrice': w3.eth.gas_price,
  'nonce': nonce,
}

number_of_nfts_to_mint = 1
transaction = nft_contract.functions.mint(
    my_address,
    1,
    number_of_nfts_to_mint,
    bytes('', 'utf-8')
).build_transaction(dict_transaction)


# Signed
signed_txn = w3.eth.account.sign_transaction(transaction, private_key)
print(f"Sig. transaction : {signed_txn}")

# Mint
txn_hash = w3.eth.send_raw_transaction(signed_txn.rawTransaction)
print(f"Transaction {txn_hash.hex()}")

tx_receipt = w3.eth.wait_for_transaction_receipt(txn_hash)
print(f"Receipt {tx_receipt}")




nonce = w3.eth.get_transaction_count(my_address)
print(f"Nonce : {nonce}")

dict_transaction = {
  'chainId': w3.eth.chain_id,
  'from': my_address,
  'gasPrice': w3.eth.gas_price,
  'nonce': nonce,
}

transaction = nft_contract.functions.mint(
    my_address,
    2,
    number_of_nfts_to_mint,
    bytes('', 'utf-8')
).build_transaction(dict_transaction)

signed_txn = w3.eth.account.sign_transaction(transaction, private_key)
#print(f"Sig. transaction : {signed_txn}")
txn_hash = w3.eth.send_raw_transaction(signed_txn.rawTransaction)
print(f"Transaction {txn_hash.hex()}")
tx_receipt = w3.eth.wait_for_transaction_receipt(txn_hash)
#print(f"Receipt {tx_receipt}")


print(nft_contract.all_functions())

i=1
amount  = nft_contract.functions.balanceOf(my_address, i).call()
print(f"Amount  of token : {amount} with index : {i} ")

transaction = nft_contract.functions.mint(
    my_address,
    1,
    number_of_nfts_to_mint,
    bytes('', 'utf-8')
).call({'from' : my_address})



print(f"Mint one more token {transaction} without sign")


amount  = nft_contract.functions.balanceOf(my_address, i).call()
print(f"Amount  of token : {amount} with index : {i} ")


nonce = w3.eth.get_transaction_count(my_address)
print(f"Nonce : {nonce}")


dict_transaction = {
  'chainId': w3.eth.chain_id,
  'from': my_address,
  'gasPrice': w3.eth.gas_price,
  'nonce': nonce,
}

number_of_nfts_to_mint = 1
transaction = nft_contract.functions.mint(
    my_address,
    1,
    number_of_nfts_to_mint,
    bytes('', 'utf-8')
).build_transaction(dict_transaction)

#Personal not work (IMHO it depend from geth settings)
#e = w3.eth.personal
#e.unlock_account()
#nft_contract.functions.getOwner().call({'from': e.account})
#nft_contract.functions.getOwner().transact({'from': e.account})
print(f"Mint one more token {transaction} with sign")


# Sign
signed_txn = w3.eth.account.sign_transaction(transaction, private_key)
print(f"Sig. transaction : {signed_txn}")

# Mint
txn_hash = w3.eth.send_raw_transaction(signed_txn.rawTransaction)
print(f"Transaction {txn_hash.hex()}")

tx_receipt = w3.eth.wait_for_transaction_receipt(txn_hash)
print(f"Receipt {tx_receipt}")

print(f"Mint one more token {transaction} with sign")




for i in range(5):
    #i=1
    amount  = nft_contract.functions.balanceOf(my_address, i).call()
    print(f"Amount  of token : {amount} with index : {i} ")



```

This script also contains examples for a clear understanding of the need for a digital signature for each new token mint.


# The script used to create the material in this page


All the smart contracts and the data you see in this page are generated by the scripts [ethereum.bats](https://github.com/dyne/Zenroom/blob/master/test/zencode/ethereum.bats) . If you want to run the scripts (on Linux) you should: 
 - *git clone https://github.com/dyne/Zenroom.git*
 - install  **jq**
 - download a [zenroom binary](https://zenroom.org/#downloads) and place it */bin* or */usr/bin* or in *./Zenroom/src*
# Zencode *rules*

Rules in Zencode are directives that influence the whole computation of the script. Rules can be written before or after the 'Scenario' directive(s) but always before the first 'Given' statement


# Rule input/output encode: setting encoding for the whole script

When processing the output, Zenroom will use the own encoding of the object. 
This can be overriden by using the ***Rule output encoding*** statement, for example the line:

```gherkin
Rule output encoding base58
Scenario 'ecdh': pk

Given I have nothing
When I create the ecdh key
and I create the ecdh public key
Then print the 'ecdh public key'
```

will get all the output to be printed as *base58*:

```json
{"ecdh_public_key":"Prv7EbvuXevABNJytdsoXPqjJFJxnuiHVk3QqcuWHtn7yzEQHkctuEgezzjG9tCCNriD4HsmFNnFPFDcGfMs3kmR"}
```

which may come in handy when working with cryptography.

You can also redefine the input encoding, which would work only with ***schemas*** whose encoding is pre-defined. This will be again useful mostly when working with cryptography. For example the output of the above script can be reloaded into Zenroom like this:

```gherkin
Rule input encoding base58
Scenario 'ecdh': public key

Given I have a 'ecdh public key'
Then print the data
```

# Rule check version

The ***rule check version*** statement, will validate the script's syntax to make sure it matches the Zencode version stated. Not using the line in the beginning of each script will cause a warning. For example:

```gherkin
Rule check version 2.0.0

Given nothing
When I create the random 'random'
Then print the data
```


# Rule input number strict

The ***Rule input number strict*** statement will import all numbers, whose type is not explicitly stated (as for example inside a **string dictionary**), as floats. You can use the statement like this:

```gherkin
Rule input number strict

Given I have a 'string dictionary' named 'string_dict_with_number'
Then print the data
```

with input:

```
{
    "string_dict_with_number": {
        "string": "hello",
        "num": 1978468946,
        "bool": true
    }
}
```

the output will look like:

```
{"string_dict_with_number":{"bool":true,"num":1.978469e+09,"string":"hello"}}
```

When this statment is not used numbers whose type is not explicitly stated and that are integers in the range from 1500000000 (included) to 2000000000 (not included) will be imported as time. For exmaple with the same input of above and the following script (only the rule line is removed):

```gherkin
Given I have a 'string dictionary' named 'string_dict_with_number'
Then print the data
```

the output will be:

```
{"string_dict_with_number":{"bool":true,"num":1978468946,"string":"hello"}}
```


# Rule unknown ignore

When parsing a script Zenroom will throw an error in case unkown statements are found.
The ***Rule unknown ignore*** statement will do not throw the error but only at the contidition that the unknown statements are found before the *Given* phase and after the *Then* phase. You can use the statement like this:

```gherkin
Rule unknown ignore

Given a statement that does not exist
and what about this one?
Given nothing
When I write string 'test passed' in 'result'
Then print the data
Then another statement that does not exist
and maybe another one
```
## Usage

Zenroom configuration is used to set some application wide parameters at initialization time.
The configuration is passed as a parameter (not as file!) using the "-c" option, or as a parameter
if Zenroom is used as lib. You can pass Zenroom several attributes, wrapped in quotes and separated
by a comma, as in the example below:

```shell
zenroom -z keyring.zen -c "debug=3, rngseed=hex:74eeeab870a394175fae808dd5dd3b047f3ee2d6a8d01e14bff94271565625e98a63babe8dd6cbea6fedf3e19de4bc80314b861599522e44409fdd20f7cd6cfc"
```

Below a list of the config parameters with a description and usage examples.

## Debug verbosity

Syntax and values: **debug=1|2|3** or **verbose=1|2|3**

*debug* and *verbose* are synonyms. They define the verbosity of Zenroom's output.
Moreove if this value is grater than 1 the zenroom watchdog is activated and at each step a check on all internal
data is performed to assert all values in memory are converted to zenroom types.

*Default*: 2

## Scope

Syntax and values: **scope=given|full**

Scope represent wich part of the zenroom contract should be executed. When it is set to *full*, that is the default value,
all the contract is run, on the other hand when it is *given* only the given part is run and the result is the CODEC
status after the given phase, it can be used to know what data a user needs to pass to the contract.

*Default*: full.

## Random seed

Syntax and values: **rngseed=hex:[64 bytes in hex notation]**

Loads a random seed at start, that will be used through the Zenroom execution whenever a random seed is requested.
A fixed random can be used to test determinism. For example, when generating an ECDH key, using:


```shell
rngseed=hex:74eeeab870a394175fae808dd5dd3b047f3ee2d6a8d01e14bff94271565625e98a63babe8dd6cbea6fedf3e19de4bc80314b861599522e44409fdd20f7cd6cfc
```

Should always generate the keyring:

```json
{
  "keyring": {
    "private_key": "Aku7vkJ7K01gQehKELav3qaQfTeTMZKgK+5VhaR3Ui0="
  }
}
```

## Log format

Syntax and values: **logfmt=text|json**

When using *text* as log format, all the log is printed as a text, while using the *json* it is an array,
where, when an error happens, the trace and heap are base64 encoded and can be found respectively in the
values starting with *J64 TRACE:* and *J64 HEAP:*.

Example of log in text:
```
Release version: v4.36.0
Build commit hash: 760ca7bb
Memory manager: libc
ECDH curve is SECP256K1
ECP curve is BLS381
[W] Zencode is missing version check, please add: rule check version N.N.N
[W] {
 KEYRING = {
 bbs = int[32] ,
 bitcoin = octet[32] ,
 dilithium = octet[2528] ,
 ecdh = octet[32] ,
 eddsa = octet[32] ,
 es256 = octet[32] ,
 ethereum = octet[32] ,
 pvss = int[32] ,
 reflow = int[32] ,
 schnorr = octet[32]
 }
}
[W] {
 a_GIVEN_in = {},
 c_CACHE_ack = {},
 c_CODEC_ack = {
 keyring = {
 encoding = "def",
 name = "keyring",
 schema = "keyring",
 zentype = "e"
 }
 },
 c_WHEN_ack = {
 keyring = "(hidden)"
 },
 d_THEN_out = {}
}
+18 Given nothing
+23 When I create the ecdh key
+24 When I create the es256 key
+25 When I create the ethereum key
+26 When I create the reflow key
+27 When I create the schnorr key
+28 When I create the bitcoin key
+29 When I create the eddsa key
+30 When I create the bbs key
+31 When I create the pvss key
+32 When I create the dilithium key
+34 Then print the 'keyrig'
[!] Error at Zencode line 34
[!] /zencode_then.lua:158: Cannot find object: keyrig
[!] Zencode runtime error
[!] /zencode.lua:706: Zencode line 34: Then print the 'keyrig'
[!] Execution aborted with errors.
[*] Zenroom teardown.
Memory used: 606 KB
```
the same log in json
```json
[ "ZENROOM JSON LOG START",
" Release version: v4.36.0",
" Build commit hash: 760ca7bb",
" Memory manager: libc",
" ECDH curve is SECP256K1",
" ECP curve is BLS381",
"[W] Zencode is missing version check, please add: rule check version N.N.N",
"J64 HEAP: eyJDQUNIRSI6W10sIkNPREVDIjp7ImtleXJpbmciOnsiZW5jb2RpbmciOiJkZWYiLCJuYW1lIjoia2V5cmluZyIsInNjaGVtYSI6ImtleXJpbmciLCJ6ZW50eXBlIjoiZSJ9fSwiR0lWRU5fZGF0YSI6W10sIlRIRU4iOltdLCJXSEVOIjp7ImtleXJpbmciOiIoaGlkZGVuKSJ9fQ==",
"J64 TRACE: WyIrMTggIEdpdmVuIG5vdGhpbmciLCIrMjMgIFdoZW4gSSBjcmVhdGUgdGhlIGVjZGgga2V5IiwiKzI0ICBXaGVuIEkgY3JlYXRlIHRoZSBlczI1NiBrZXkiLCIrMjUgIFdoZW4gSSBjcmVhdGUgdGhlIGV0aGVyZXVtIGtleSIsIisyNiAgV2hlbiBJIGNyZWF0ZSB0aGUgcmVmbG93IGtleSIsIisyNyAgV2hlbiBJIGNyZWF0ZSB0aGUgc2Nobm9yciBrZXkiLCIrMjggIFdoZW4gSSBjcmVhdGUgdGhlIGJpdGNvaW4ga2V5IiwiKzI5ICBXaGVuIEkgY3JlYXRlIHRoZSBlZGRzYSBrZXkiLCIrMzAgIFdoZW4gSSBjcmVhdGUgdGhlIGJicyBrZXkiLCIrMzEgIFdoZW4gSSBjcmVhdGUgdGhlIHB2c3Mga2V5IiwiKzMyICBXaGVuIEkgY3JlYXRlIHRoZSBkaWxpdGhpdW0ga2V5IiwiKzM0ICBUaGVuIHByaW50IHRoZSAna2V5cmlnJyIsIlshXSBFcnJvciBhdCBaZW5jb2RlIGxpbmUgMzQiLCJbIV0gL3plbmNvZGVfdGhlbi5sdWE6MTU4OiBDYW5ub3QgZmluZCBvYmplY3Q6IGtleXJpZyJd",
"[!] Zencode runtime error",
"[!] /zencode.lua:706: Zencode line 34: Then print the 'keyrig'",
"[!] Execution aborted with errors.",
"[*] Zenroom teardown.",
" Memory used: 663 KB",
"ZENROOM JSON LOG END" ]
```
*Default*: *json* in javascript bindings and *text* otherwise.

## Limit iterations

Syntax and values: **maxiter=dec:[at most 10 decimal digits]**

Define the maximum number of iterations the contract is allowed to do.

*Default*: 1000.

## Limit of memory

Syntax and values: **maxmem=dec:[at most 10 decimal digits]**

Define the maximum memory in MB that lua can occupy before calling the garbage collector
during the run phase.

*Default*: 1024 (1GB)

## Secure memory block num and size

Syntax and values: **memblocknum=dec (default 64)**,**memblocksize=dec (default 256)**

Number of blocks and size of each block in size, defining the space of memory allocated for the secure pool used in Zenroom for sensitive values during operation (internal [sailfish-pool](https://github.com/dyne/sailfish-pool/))

# Zencode command list

Start reading here to understand how Zencode smart contracts are written and the philosophy behind the technology.

# Smart contract setup

First we'll look at **phases, scenarios, rules and configuration**.

*Phases*: let's rememeber that Zencode contracts operate in 3 phases:

1. **Given** - validates the input
2. **When** - processes the contents
3. **Then** - prints out the results

So each Zencode smart contract will contain at least three lines, each begining with one of the 3 keywords, in the given order.

## Scenarios

Scenarios are set in the beginning of a script and they make Zenroom use a certain set of rules to interpretate the Zencode contained in the smart contract. Different scenarios will typically contain different keywords. The syntax to set a scenario is:

```gherkin
   Scenario 'simple': Create the keypair
```

The scenario setting happens before the ```:```, everything right of that isn't processed by Zenroom and can be used as a title to the smart contract.

## Rules

Rules are *optional*, they are used to define input and output formats of the smart contract, they have to be set after the scenario and before the rest of the smart contracts. Current rules:

```txt
rule input encoding [ url64 | base64 | hex | bin ]
rule input format [ json ]
```

For example, a valid config is:

```gherkin
rule input encoding hex
rule output encoding hex
```

A rule can be set also check that Zenroom is at a certain version: if the rule is not satisfied, Zenroom will stop.

```gherkin
   rule check version 2.0.0
```

## Configurations

You can pass to Zenroom a configuration file, using the parameter ```-c```, description will follow soon.

---

# *Given*

There are different ways to state who you are in order to use **my** statements later

```gherkin
   Given I am ''
   Given my name is in a '' named ''
   Given my name is in a '' named '' in ''
```

Data provided as input (from **data** and **keys**) is all imported
automatically from the **JSON** string format.
There can also be no input to the code, in this case can be checked the emptiness with:

```gherkin
   Given nothing
```

Scenarios can add Schema for specific data validation mapped to **words** like: **signature**, **proof** or **secret**.

All the valid `given` statements are:

```
''
am ''
'' from ''
'' in ''
'' in path ''
'' is valid
my ''
my '' is valid
my '' named ''
my '' named by ''
my name is in '' named ''
my name is in '' named '' in ''
'' named ''
'' named by ''
'' named by '' in ''
'' named '' in ''
nothing
'' part of '' after string prefix ''
'' part of '' before string suffix ''
'' public key from ''
rename '' to ''
```


When **valid** is specified then extra checks are made on input value,
mostly according to the **scenario**


# *When*

Processing data is done in the when block. Also scenarios add statements to this block.

## Basic

Without extensions, all the following statementes are valid:

- basic functions

```
append '' of '' to ''
append string '' to ''
append '' to ''
compact ascii strings in ''
copy '' as '' to ''
copy contents of '' in ''
copy contents of '' named '' in ''
copy '' from '' to ''
copy '' to ''
create ''
create '' cast of strings in ''
create count of char '' found in ''
create float '' cast of integer in ''
create json escaped string of ''
create json unescaped object of ''
create '' named ''
create number from ''
create result of ''
create result of '' % ''
create result of '' * ''
create result of '' + ''
create result of '' - ''
create result of '' / ''
create result of '' * '' in ''
create result of '' / '' in ''
create result of '' in '' % ''
create result of '' in '' * ''
create result of '' in '' + ''
create result of '' in '' - ''
create result of '' in '' / ''
create result of '' in '' % '' in ''
create result of '' in '' * '' in ''
create result of '' in '' + '' in ''
create result of '' in '' - '' in ''
create result of '' in '' / '' in ''
create result of '' inverted sign
create '' string of ''
delete ''
done
exit with error message ''
move '' as '' to ''
move '' from '' to ''
move '' to ''
remove ''
remove all occurrences of character '' in ''
remove newlines in ''
remove spaces in ''
remove zero values in ''
rename object named by '' to ''
rename object named by '' to named by ''
rename '' to ''
rename '' to named by ''
set '' to '' as ''
set '' to '' base ''
split leftmost '' bytes of ''
split rightmost '' bytes of ''
verify '' is a json
verify '' is found
verify '' is not found
write number '' in ''
write string '' in ''
```
- array functions

```
```
- bitcoin functions

```
create bitcoin address
create bitcoin key
create bitcoin key with secret ''
create bitcoin key with secret key ''
create bitcoin public key
create bitcoin raw transaction
create bitcoin transaction
create bitcoin transaction to ''
create testnet address
create testnet key
create testnet key with secret ''
create testnet key with secret key ''
create testnet public key
create testnet raw transaction
create testnet transaction
create testnet transaction to ''
sign bitcoin transaction
sign testnet transaction
```
- debug functions

```
backtrace
break
codec
config
debug
schema
trace
```
- dictionary functions

```
create array of elements named '' for dictionaries in ''
create copy of '' from ''
create copy of '' from dictionary ''
create copy of object named by '' from dictionary ''
create new dictionary
create new dictionary named ''
create pruned dictionary of ''
create sum value '' for dictionaries in ''
create sum value '' for dictionaries in '' where '' > ''
filter '' fields from ''
find '' for dictionaries in '' where '' = ''
find max value '' for dictionaries in ''
find min value '' for dictionaries in ''
for each dictionary in '' append '' to ''
```
- hash functions

```
create hashes of each object in ''
create hash of ''
create hash of '' using ''
create hash to point '' of ''
create HMAC of '' with key ''
create key derivation of ''
create key derivation of '' with password ''
create key derivation of '' with '' rounds
create key derivation of '' with '' rounds with password ''
create key derivations of each object in ''
```
- keyring functions

```
create keyring
```
- random functions

```
create array of '' random numbers
create array of '' random numbers modulo ''
create array of '' random objects
create array of '' random objects of '' bits
create array of '' random objects of '' bytes
create random ''
create random dictionary with '' random objects from ''
create random object of '' bits
create random object of '' bytes
pick random object in ''
randomize '' array
seed random with ''
```
- table functions

```
copy '' as '' in ''
copy '' from '' in ''
copy '' in ''
copy named by '' in ''
copy '' to '' in ''
create copy of last element from ''
create size of ''
move '' as '' in ''
move '' from '' in ''
move '' in ''
move named by '' in ''
move '' to '' in ''
pickup a '' from path ''
pickup from path ''
remove '' from ''
take '' from path ''
verify '' is found in ''
verify '' is found in '' at least '' times
verify '' is not found in ''
```
- time functions

```
create date table of timestamp ''
create integer '' cast of timestamp ''
create timestamp
create timestamp of date table ''
```
- verify functions

```
verify '' contains a list of emails
verify elements in '' are equal
verify elements in '' are not equal
verify '' ends with ''
verify '' has prefix ''
verify '' has suffix ''
verify '' is a email
verify '' is equal to ''
verify '' is equal to '' in ''
verify '' is not equal to ''
verify '' is not equal to '' in ''
verify number '' is less or equal than ''
verify number '' is less than ''
verify number '' is more or equal than ''
verify number '' is more than ''
verify size of '' is less or equal than ''
verify size of '' is less than ''
verify size of '' is more or equal than ''
verify size of '' is more than ''
verify '' starts with ''
```

## Extensions

Each of the following scenario enable a set of sentences:
- `bbs functions`

```
create bbs disclosed messages
create bbs key
create bbs key with secret ''
create bbs key with secret key ''
create bbs proof
create bbs proof of signature '' of messages '' with public key '' presentation header '' and disclosed indexes ''
create bbs public key
create bbs public key with secret key ''
create bbs shake key
create bbs shake key with secret ''
create bbs shake key with secret key ''
create bbs shake proof
create bbs shake proof of signature '' of messages '' with public key '' presentation header '' and disclosed indexes ''
create bbs shake public key
create bbs shake public key with secret key ''
create bbs shake signature of ''
create bbs signature of ''
verify bbs proof
verify bbs proof with public key '' presentation header '' disclosed messages '' and disclosed indexes ''
verify bbs shake proof
verify bbs shake proof with public key '' presentation header '' disclosed messages '' and disclosed indexes ''
verify '' has a bbs shake signature in '' by ''
verify '' has a bbs signature in '' by ''
```
- `credential`

```
aggregate credentials in ''
aggregate issuer public keys
aggregate verifiers in ''
create credential key
create credential key with secret ''
create credential key with secret key ''
create credential proof
create credential request
create credentials
create credential signature
create issuer key
create issuer public key
verify credential proof
```
- `dp3t`

```
create ephemeral ids for today
create proximity tracing of infected ids
renew secret day key to a new day
```
- `ecdh`

```
create ecdh deterministic signature of ''
create ecdh key
create ecdh key with secret ''
create ecdh key with secret key ''
create ecdh public key
create ecdh signature of ''
create ecdsa deterministic signature of ''
create signature of ''
decrypt text of '' from ''
decrypt text of '' with ''
encrypt secret message of '' for ''
encrypt secret message '' with ''
verify '' has a ecdh deterministic signature in '' by ''
verify '' has a ecdh signature in '' by ''
verify '' has a ecdsa deterministic signature in '' by ''
verify '' has a signature in '' by ''
```
- `eddsa`

```
create eddsa key
create eddsa key with secret ''
create eddsa key with secret key ''
create eddsa public key
create eddsa public key with secret key ''
create eddsa signature of ''
verify '' has a eddsa signature in '' by ''
```
- `es256`

```
create es256 key
create es256 key with secret ''
create es256 key with secret key ''
create es256 public key
create es256 public key with secret key ''
create es256 signature of ''
verify '' has a es256 signature in '' by ''
```
- `ethereum`

```
create '' decoded from ethereum bytes ''
create ethereum abi decoding of '' using ''
create ethereum abi encoding of '' using ''
create ethereum address
create ethereum address from ethereum signature '' of ''
create ethereum key
create ethereum key with secret ''
create ethereum key with secret key ''
create ethereum signature of ''
create ethereum transaction of '' to ''
create ethereum transaction to ''
create signed ethereum transaction
create signed ethereum transaction for chain ''
create string from ethereum bytes named ''
use ethereum address signature pair array '' to create result array of ''
use ethereum transaction to approve erc721 '' transfer from ''
use ethereum transaction to create erc721 of object ''
use ethereum transaction to create erc721 of uri ''
use ethereum transaction to run '' using ''
use ethereum transaction to store ''
use ethereum transaction to transfer '' erc20 tokens to ''
use ethereum transaction to transfer '' erc20 tokens to '' with details ''
use ethereum transaction to transfer erc721 '' from '' to ''
use ethereum transaction to transfer erc721 '' in contract '' to '' in planetmint
verify ethereum address signature pair array '' of ''
verify ethereum address string '' is valid
verify '' has a ethereum signature in '' by ''
verify signed ethereum transaction from ''
```
- `fsp`

```
create fsp ciphertext of ''
create fsp cleartext of ''
create fsp cleartext of response ''
create fsp cleartext of response '' to ''
create fsp key
create fsp key with secret ''
create fsp key with secret key ''
create fsp response of '' with ''
create fsp response with ''
```
- `http`

```
append '' as http request to ''
append percent encoding of '' as http request to ''
create http get parameters from ''
create http get parameters from '' using percent encoding
create url from ''
```
- `petition`

```
add signature to petition
count petition results
create a petition tally
create petition ''
create petition signature ''
verify new petition to be empty
verify petition signature is just one more
verify petition signature is not a duplicate
verify signature proof is correct
```
- `planetmint`

```
create planetmint signatures of ''
```
- `pvss`

```
compose pvss secret using '' with quorum ''
create pvss key
create pvss public key
create pvss public shares of '' with '' quorum '' using public keys ''
create pvss verified shares from ''
create secret share with public key ''
verify pvss public shares with '' quorum ''
```
- `qp`

```
create dilithium key
create dilithium public key
create dilithium public key with secret key ''
create dilithium signature of ''
create kyber kem for ''
create kyber key
create kyber public key
create kyber public key with secret key ''
create kyber secret from ''
create mldsa44 key
create mldsa44 public key
create mldsa44 public key with secret key ''
create mldsa44 signature of ''
create mlkem512 kem for ''
create mlkem512 key
create mlkem512 public key
create mlkem512 public key with secret key ''
create mlkem512 secret from ''
create ntrup kem for ''
create ntrup key
create ntrup public key
create ntrup public key with secret key ''
create ntrup secret from ''
verify '' has a dilithium signature in '' by ''
verify '' has a mldsa44 signature in '' by ''
```
- `reflow`

```
add reflow fingerprint to reflow seal
add reflow signature to reflow seal
aggregate credentials in ''
aggregate issuer public keys
aggregate reflow public key from array ''
aggregate reflow seal array in ''
aggregate verifiers in ''
create credential key
create credential key with secret ''
create credential key with secret key ''
create credential proof
create credential request
create credentials
create credential signature
create issuer key
create issuer public key
create material passport of ''
create reflow identity of ''
create reflow identity of objects in ''
create reflow key
create reflow key with secret ''
create reflow key with secret key ''
create reflow public key
create reflow seal
create reflow seal with identity ''
create reflow signature
prepare credentials for verification
verify credential proof
verify material passport of ''
verify material passport of '' is valid
verify reflow seal is valid
verify reflow signature credential
verify reflow signature fingerprint is new
```
- `rsa`

```
create rsa key
create rsa public key
create rsa public key with secret key ''
create rsa signature of ''
verify '' has a rsa signature in '' by ''
```
- `schnorr`

```
create schnorr key
create schnorr key with secret ''
create schnorr key with secret key ''
create schnorr public key
create schnorr public key with secret key ''
create schnorr signature of ''
verify '' has a schnorr signature in '' by ''
```
- `sd_jwt`

```
create disclosed kv from signed selective disclosure ''
create jwt key binding with jwk ''
create selective disclosure of ''
create selective disclosure request from '' with id '' for ''
create signed selective disclosure of ''
use signed selective disclosure '' only with disclosures ''
verify disclosures '' are found in signed selective disclosure ''
verify signed selective disclosure '' issued by '' is valid
```
- `secshare`

```
compose secret using ''
create secret shares of '' with '' quorum ''
```
- `w3c`

```
create json web token of '' using ''
create jwk of ecdh public key
create jwk of ecdh public key ''
create jwk of ecdh public key with private key
create jwk of es256k public key
create jwk of es256k public key ''
create jwk of es256k public key with private key
create jwk of es256 public key
create jwk of es256 public key ''
create jwk of es256 public key with private key
create jwk of p256 public key
create jwk of p256 public key ''
create jwk of p256 public key with private key
create jwk of secp256k1 public key
create jwk of secp256k1 public key ''
create jwk of secp256k1 public key with private key
create jwk of secp256r1 public key
create jwk of secp256r1 public key ''
create jwk of secp256r1 public key with private key
create jws detached signature of header '' and payload ''
create jws header for ecdh signature
create jws header for ecdh signature with public key
create jws header for es256k signature
create jws header for es256k signature with public key
create jws header for es256 signature
create jws header for es256 signature with public key
create jws header for p256 signature
create jws header for p256 signature with public key
create jws header for secp256k1 signature
create jws header for secp256k1 signature with public key
create jws header for secp256r1 signature
create jws header for secp256r1 signature with public key
create jws signature of ''
create jws signature of header '' and payload ''
create jws signature using ecdh signature in ''
create '' public key from did document ''
create serviceEndpoint of ''
create verificationMethod of ''
get verification method in ''
set verification method in '' to ''
sign verifiable credential named ''
verify did document named ''
verify did document named '' is signed by ''
verify '' has a jws signature in ''
verify json web token in '' using ''
verify jws signature in ''
verify jws signature of ''
verify verifiable credential named ''
```

# *Foreach*

The foreach statements can be used directly without adding any scenario.

```
break foreach
exit foreach
'' in ''
'' in sequence from '' to '' with step ''
```

# *If*

The subset of the *When* statements that can be used with the *If* to create a conditional branch are:

```
verify bbs proof
verify bbs proof with public key '' presentation header '' disclosed messages '' and disclosed indexes ''
verify bbs shake proof
verify bbs shake proof with public key '' presentation header '' disclosed messages '' and disclosed indexes ''
verify '' contains a list of emails
verify credential proof
verify credential proof
verify did document named ''
verify did document named ''
verify did document named '' is signed by ''
verify did document named '' is signed by ''
verify disclosures '' are found in signed selective disclosure ''
verify elements in '' are equal
verify elements in '' are not equal
verify '' ends with ''
verify ethereum address signature pair array '' of ''
verify '' has a bbs shake signature in '' by ''
verify '' has a bbs signature in '' by ''
verify '' has a dilithium signature in '' by ''
verify '' has a ecdh deterministic signature in '' by ''
verify '' has a ecdh signature in '' by ''
verify '' has a ecdsa deterministic signature in '' by ''
verify '' has a eddsa signature in '' by ''
verify '' has a es256 signature in '' by ''
verify '' has a ethereum signature in '' by ''
verify '' has a jws signature in ''
verify '' has a jws signature in ''
verify '' has a mldsa44 signature in '' by ''
verify '' has a rsa signature in '' by ''
verify '' has a schnorr signature in '' by ''
verify '' has a signature in '' by ''
verify '' has prefix ''
verify '' has suffix ''
verify '' is a email
verify '' is a json
verify '' is equal to ''
verify '' is equal to '' in ''
verify '' is found
verify '' is found in ''
verify '' is found in '' at least '' times
verify '' is not equal to ''
verify '' is not equal to '' in ''
verify '' is not found
verify '' is not found in ''
verify json web token in '' using ''
verify json web token in '' using ''
verify jws signature in ''
verify jws signature in ''
verify jws signature of ''
verify jws signature of ''
verify material passport of ''
verify material passport of '' is valid
verify number '' is less or equal than ''
verify number '' is less than ''
verify number '' is more or equal than ''
verify number '' is more than ''
verify petition signature is just one more
verify petition signature is not a duplicate
verify reflow seal is valid
verify reflow signature credential
verify reflow signature fingerprint is new
verify signature proof is correct
verify signed selective disclosure '' issued by '' is valid
verify size of '' is less or equal than ''
verify size of '' is less than ''
verify size of '' is more or equal than ''
verify size of '' is more than ''
verify '' starts with ''
verify verifiable credential named ''
verify verifiable credential named ''
```

# *Then*

Output is all exported in JSON

```
nothing
print ''
print '' as ''
print '' as '' in ''
print data
print data as ''
print data from ''
print data from '' as ''
print '' from ''
print '' from '' as ''
print '' from '' as '' in ''
print keyring
print my ''
print my '' as ''
print my data
print my data as ''
print my data from ''
print my data from '' as ''
print my '' from ''
print my '' from '' as ''
print my keyring
print my name in ''
print object named by ''
print string ''
```

Settings:
```txt
rule output encoding [ url64 | base64 | hex | bin ]
rule output format [ json ]
```
# Embedding Zenroom

Zenroom is designed to facilitate embedding into other native applications and high-level scripting languages. The stable releases distribute compiled library components for Apple/iOS and Google/Android platforms, as well MS/Windows DLL, Apple/OSX shared library and Javascript/WASM.

To call Zenroom from an host program is very simple: there isn't an API to learn, but a single call to execute scripts and return their results. The call is called `zencode_exec` and prints results to the "stderr/stdout" terminal output. It will work more or less the same everywhere:

```c
int zencode_exec(char *script,
                 char *conf,
				 char *keys,
                 char *data);
```
The input string buffers will not be modified by the call, they are:
- `script`: the [Zencode script](https://dev.zenroom.org/#/pages/zencode-cookbook-intro) to be executed
- `conf`: a series of comma separated key=value pairs
- `keys`: JSON formatted data passed as input to the script
- `data`: JSON formatted data passed as input to the script

This is all you need to know to start using Zenroom in your software, to try it out you may want to jump directly to the [specific instructions for language bindings](https://dev.zenroom.org/#/pages/how-to-embed?id=language-bindings).

Here can you find the latest [zenroom.h header file](https://github.com/dyne/Zenroom/blob/master/src/zenroom.h)

## Configuration directives

The list of accepted configurations in `conf` argument are:

- `debug` is the level of log verbosity, default is `debug=1`
- `rngseed` is used to provide an external random seed for fully deterministic behaviour, it accepts an hexadecimal string representing a series of 64 bytes (128 chars in total) prefixed by `hex:`. For example: `rngseed=hex:000000...` up to 128 zeroes
- `logfmt` is the format of the error logs, it can be `text` or `json`, the default is `logfmt=text` of `logfmt=json` when using Zenroom from bindings.

## Parsing the stderr output

The control log (stderr output channel) is a simple array (json or newline terminated according to `logfmt`) sorted in chronological order. The nature of the logged events can be detected by parsing the first 3 chars of each entry:
- `[*]` is a notification of success
- ` . ` is execution information
- `[W]` is a warning
- `[!]` is a fatal error
- `[D]` is a verbose debug information when switched on with conf `debug=3`
- `+1 ` and other decimal numbers indicate the Zencode line being executed
- `-1 ` and other decimal numbers indicate the Zencode line being ignored
- `J64` followed by HEAP or TRACE indicate a base64 encoded JSON dump

## Extended API

In addition to the main `zencode_exec` function there is another one that copies results (error messages and printed output) inside memory buffers pre-allocated by the caller, instead of stdin and stdout file descriptors:
```c
int zencode_exec_tobuf(char *script, char *conf,
                       char *keys,   char *data,
                       char *stdout_buf, size_t stdout_len,
                       char *stderr_buf, size_t stderr_len);
```
The new arguments are:
- `stdout_buf`: pre-allocated buffer where to write data output
- `stdout_len`: maximum length of the data output buffer
- `stderr_buf`: pre-allocated buffer where to write error logs
- `stderr_len`: maximum length of the error logs buffer

More internal functions are made available to C/C++ applications, breaking up the execution in a typical init / exec / teardown sequence:

```c
zenroom_t *zen_init(const char *conf, char *keys, char *data);
int  zen_exec_zencode(zenroom_t *Z, const char *script);
void zen_teardown(zenroom_t *zenroom);
```

In addition to these calls there is also one that allows to execute directly a limited set of Lua instructions using the Zenroom VM, excluding those accessing network and filesystem (`os` etc.)
```c
int zen_exec_script(zenroom_t *Z, const char *script);
```

For more information see the [Zenroom header file](https://github.com/dyne/Zenroom/blob/master/src/zenroom.h) which is the only header you'll need to include in an application linking to the Zenroom static or shared library.

## Advanced API usage

This section lists some of the advanced API calls available, they are
implemented to facilitate some specific use-cases and advanced
applications embedding Zenroom.

### Input Validation

A caller application using Zenroom may want to have more information about the input data accepted by a Zencode script before executing it. Input validation can be operated without executing the whole script by calling `zencode_exec` using a special configuration directive: `scope=given`.

The output of input validation consists of a "`CODEC`" dictionary documenting all expected input by the `Given` section of a script, including data missing from the current input. The `CODEC` is in JSON format and consists of:

- `n`ame = key name of the data
- `r`oot = name of the parent object if present
- `s`chema = scenario specific schema for data import/export
- `e`ncoding = can be `hex`, `base64`, `string`, `base58`, etc.
- `l`uatype = type of value in Lua: `table`, `string`, `number`, etc.
- `z`entype = kind of value: `a`rray, `d`ictionary, `e`lement or `s`chema
- `b`intype = the zenroom binary value type: `octet`, `ecp`, `float`, etc.
- `m`issing = true if the input value was not found and just expected

Each data object will have a corresponding `CODEC` entry describing it
when using input validation: the entry will be part of a dictionary
and its name will be used as key.

### API direct calls (skip VM init)

Zenroom offers direct API calls to certain cryptographic primitives, executing very fast when there is no need to initialize the whole VM. These calls may be just simplier to use for expert developers doing simple things.

All direct API calls return 0 on success, anything else is an error.

All their input arguments and output are encoded string values, their encoding may vary: it is almost everywhere HEX (base 16), but Base64 is used for hashes.

The output is an encoded string printed to stdout, easy to collect from Javascript.

#### Zenroom_hash* API

The encoding of of all arguments is:
- `hash_type` ASCII
- `hash_ctx` HEX
- `buffer` Base64

The `zennrom_hash*` functions:
```c
// hash_type may be one of these two strings: 'sha256' or 'sha512'
int zenroom_hash_init(const char *hash_type);

// hash_ctx is the string returned by init
// buffer is an hex encoded string of the value to be hashed
// buffer_size is the size in bytes of the value to be hashed
int zenroom_hash_update(const char *hash_ctx, const char *buffer, const int buffer_size);

// the final call will print the base64 encoded hash of the input data
int zenroom_hash_final(const char *hash_ctx);
```
# Use Zenroom in JavaScript

<p align="center">
 <a href="https://dev.zenroom.org/">
    <img src="https://raw.githubusercontent.com/DECODEproject/Zenroom/master/docs/_media/images/zenroom_logo.png" height="140" alt="Zenroom">
  </a>
</p>

<h1 align="center">
  Zenroom js bindings 🧰</br>
  <sub>Zenroom js bindings provides a javascript wrapper of <a href="https://github.com/dyne/Zenroom">Zenroom</a>, a secure and small virtual machine for crypto language processing.</sub>
</h1>

<p align="center">
  <a href="https://badge.fury.io/js/zenroom">
    <img alt="npm" src="https://img.shields.io/npm/v/zenroom.svg">
  </a>
  <a href="https://dyne.org">
    <img src="https://img.shields.io/badge/%3C%2F%3E%20with%20%E2%9D%A4%20by-Dyne.org-blue.svg" alt="Dyne.org">
  </a>
</p>

<br><br>


## 💾 Install

Stable releases are published on https://www.npmjs.com/package/zenroom that
have a slow pace release schedule that you can install with

<!-- tabs:start -->

### ** npm **

```bash
npm install zenroom
```

### ** yarn **

```bash
yarn add zenroom
```

### ** pnpm **

```bash
pnpm add zenroom
```

<!-- tabs:end -->

* * *

## 🎮 Usage

The binding consists of two main functions:

- **zencode_exec** to execute [Zencode](https://dev.zenroom.org/#/pages/zencode-intro?id=smart-contracts-in-human-language). To learn more about zencode syntax look [here](https://dev.zenroom.org/#/pages/zencode-cookbook-intro)
- **zenroom_exec** to execute our special flavor of Lua enhanced with Zenroom's [special effects](https://dev.zenroom.org/#/pages/lua)

This function accepts a mandatory **SCRIPT** to be executed and some optional parameters:
  * DATA
  * KEYS
  * [CONF](https://dev.zenroom.org/#/pages/zenroom-config)
All in form of strings.

These functions return a [Promise](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise).

To start using the zenroom vm just do:

```js
import { zenroom_exec, zencode_exec, introspection } from "zenroom";
// or if you don't use >ES6
// const { zenroom_exec, zencode_exec } = require('zenroom')


// Zencode: generate a random array. This script takes no extra input

const zencodeRandom = `
  Given nothing
  When I create the array of '16' random objects of '32' bits
  Then print all data
`;

zencode_exec(zencodeRandom)
  .then((result) => {
    console.log(result);
  })
  .catch((error) => {
    console.error(error);
  });


// Zencode: encrypt a message.
// This script takes the options' object as the second parameter: you can include data and/or keys as input.
// The "config" parameter is also optional.

const zencodeEncrypt = `
  Scenario 'ecdh': Encrypt a message with the password
  Given that I have a 'string' named 'password'
  Given that I have a 'string' named 'message'
  When I encrypt the secret message 'message' with 'password'
  Then print the 'secret message'
`;

const zenKeys = `
  {
    "password": "myVerySecretPassword"
  }
`;

const zenData = `
  {
    "message": "HELLO WORLD"
  }
`;

zencode_exec(zencode, {
  data: zenData,
  keys: zenKeys,
  conf:`debug=1`
})
  .then((result) => {
    console.log(result);
  })
  .catch((error) => {
    console.error(error);
  });

// Lua Hello World!

const lua = `print("Hello World!")`;
zenroom_exec(lua)
  .then((result) => {
    console.log(result);
  })
  .catch((error) => {
    console.error(error);
  });

// to pass the optional parameters you pass an object literal eg.

try {
  const result = await zenroom_exec(`print(DATA)`, {
    data: "Some data",
    keys: "Some other data",
    conf: `debug=0`,
  });
  console.log(result); // => Some data
} catch (e) {
  console.error(e);
}

```

Other APIs are:
* **zenroom_hash** that takes in input the hash type ("sha256" or "sha512") and an ArrayBuffer
containing the data to be hashed
* **introspect** that takes in input a zencode contract and return the data that should be present in input
to that contract
* **zencode_valid_code** that takes in input a zencode contract and throw an error in case invalid statements
are found in the contract.

## 📖 Tutorials

Here we wrote some tutorials on how to use Zenroom in the JS world
  * [Node.js](/pages/zenroom-javascript1b)
  * [Browser](/pages/zenroom-javascript2b)
  * [React](/pages/zenroom-javascript3)

For more information also see the [🌐Javascript NPM package](https://www.npmjs.com/package/zenroom).
<p align="center">
  <br/>
  <a href="https://dev.zenroom.org/">
    <img src="https://dev.zenroom.org/_media/images/zenroom_logo.png" height="140" alt="Zenroom">
  </a>
  <h2 align="center">
    zenroom.py 🐍
    <a href="https://pypi.org/project/zenroom/">
      <img alt="PyPI" src="https://img.shields.io/pypi/v/zenroom.svg" alt="Latest release">
    </a>
    <br>
    <sub>A Python3 wrapper of <a href="https://zenroom.org">Zenroom</a>, a secure and small virtual machine for crypto language processing</sub> </h2>
    <br>
</p>


This library attempts to provide a very simple wrapper around the 
[Zenroom](https://zenroom.dyne.org/) crypto virtual machine developed as part of the
[DECODE project](https://decodeproject.eu/), that aims to make the Zenroom
virtual machine easier to call from normal Python code.

Zenroom itself does have good cross platform functionality, so if you are
interested in finding out more about the functionalities offered by Zenroom,
then please visit the website linked to above to find out more.


***
## 💾 Installation

> [!NOTE]
> The `zenroom` package is just a wrapper around the `zencode-exec` utility.
> You also need to install `zencode-exec`, you can download if from the official [releases on github](https://github.com/dyne/Zenroom/releases/).
> After downloading it, you have to move it somewhere in your path, like `/usr/local/bin/`

<!-- tabs:start -->

### ** Linux **

```bash
# install zenroom wrapper
pip install zenroom

# install zencode-exec and copy it into PATH
wget https://github.com/dyne/zenroom/releases/latest/download/zencode-exec
chmod +x zencode-exec
sudo cp zencode-exec /usr/local/bin/
```

### ** MacOS **

> [!WARNING]
> On Mac OS, the executable is `zencode-exec.command` and you have to symlink it to `zencode-exec`

```bash
# install zenroom wrapper
pip install zenroom

# install zencode-exec and copy it into PATH
wget https://github.com/dyne/zenroom/releases/latest/download/zencode-exec.command
chmod +x zencode-exec.command
sudo cp zencode-exec.command /usr/local/bin/
sudo ln -s /usr/local/bin/zencode-exec.command /usr/local/bin/zencode-exec
```
### ** Windows **

> [!WARNING]
> On Windows, the executable is `zencode-exec.exe`, and you need to place it in a directory listed in your `PATH` environment variable.

Open PowerShell (press **🪟 + r**, type **powershell** and press enter), then: 

```bash
# Install zenroom wrapper
pip install zenroom

# Download zencode-exec and move it to a directory in PATH
Invoke-WebRequest -Uri "https://github.com/dyne/zenroom/releases/latest/download/zencode-exec.exe" -OutFile "zencode-exec.exe"

# Move the executable to a directory in PATH (e.g., C:\Windows or another suitable directory)
Move-Item -Path "zencode-exec.exe" -Destination "C:\Windows\" -Force
```

<!-- tabs:end -->



***
## 🎮 Usage

If you don't know what `zencode` is, you can start with the [official documentation](https://dev.zenroom.org).

The wrapper exposes one simple calls: `zencode_exec`

#### args
- `script` **[string](https://docs.python.org/3/library/stdtypes.html#text-sequence-type-str)**
 the zencode script to be executed
- `conf` **[string](https://docs.python.org/3/library/stdtypes.html#text-sequence-type-str)** the optional conf
 string to pass according to [zenroom config](https://dev.zenroom.org/#/pages/zenroom-config)
- `keys` **[string](https://docs.python.org/3/library/stdtypes.html#text-sequence-type-str)** the optional keys
 string to pass in execution as documented in zenroom docs
- `data` **[string](https://docs.python.org/3/library/stdtypes.html#text-sequence-type-str)** the optional data
 string to pass in execution as documented in zenroom docs

#### return
- `output` **[string](https://docs.python.org/3/library/stdtypes.html#text-sequence-type-str)** holds the stdout of the script execution
- `logs` **[string](https://docs.python.org/3/library/stdtypes.html#text-sequence-type-str)** holds the stderr of the script execution
- `result` (dictionary or None) holds the JSON parsed output if output contains valid JSON, otherwise it is None.

##### Examples

Example usage of `zencode_exec(script, keys=None, data=None, conf=None)`


```python
from zenroom import zenroom

contract = """Scenario ecdh: Create a ecdh key
Given that I am known as 'Alice'
When I create the ecdh key
Then print the 'keyring'
"""

result = zenroom.zencode_exec(contract)
print(result.output)
```

Next, we show a more complex example involving an ethereum signature
```python
from zenroom import zenroom
import json

conf = ""

keys = {
    "participant": {
        "keyring": {
            "ethereum": "6b4f32fc48ff19f0c184f1b7c593fbe26633421798191931c210a3a9bb46ae22"
        }
    }
}

data = {
    "myString": "I love the Beatles, all but 3",
    "participant ethereum address": "0x2B8070975AF995Ef7eb949AE28ee7706B9039504"
}

contract = """Scenario ethereum: sign ethereum message

# Here we are loading the private key and the message to be signed
Given I am 'participant'
Given I have my 'keyring'
Given I have a 'string' named 'myString'
Given I have a 'ethereum address' named 'participant ethereum address'


# Here we are creating the signature according to EIP712
When I create the ethereum signature of 'myString'
When I rename the 'ethereum signature' to 'myString.ethereum-signature'

# Here we copy the signature, which we'll print in a different format
When I copy 'myString.ethereum-signature' to 'myString.ethereum-signature.rsv'

# Here we print the signature in the regular 65 bytes long 'signaure hash' format
When I create ethereum address from ethereum signature 'myString.ethereum-signature' of 'myString'
When I copy 'ethereum address' to 'newEthereumAddress'


If I verify 'newEthereumAddress' is equal to 'participant ethereum address'
Then print string 'all good, the recovered ethereum address matches the original one'
Endif

Then print the 'myString.ethereum-signature'
Then print the 'newEthereumAddress'


# Here we print the copy of the signature in the [r,s,v], simply printing it as 'hex'
Then print the 'myString.ethereum-signature.rsv' as 'hex'
"""

result = zenroom.zencode_exec(contract, conf, json.dumps(keys), json.dumps(data))
print(result.output)
```


***
## 📋 Testing

Tests are made with pytests, just run 

`python setup.py test`

in [`zenroom_test.py`](https://github.com/dyne/Zenroom/blob/master/bindings/python3/tests/test_all.py) file you'll find more usage examples of the wrapper

***
## 🌐 Links

https://decodeproject.eu/

https://zenroom.org/

https://dev.zenroom.org/

## 😍 Acknowledgements

Copyright (C) 2018-2025 by [Dyne.org](https://www.dyne.org) foundation, Amsterdam

Originally designed and written by Sam Mulube.

Designed, written and maintained by Puria Nafisi Azizi 

Rewritten by Danilo Spinella and David Dashyan

<img src="https://upload.wikimedia.org/wikipedia/commons/8/84/European_Commission.svg" width="310" alt="Project funded by the European Commission">

This project is receiving funding from the European Union’s Horizon 2020 research and innovation programme under grant agreement nr. 732546 (DECODE).

***

## 👥 Contributing
Please first take a look at the [Dyne.org - Contributor License Agreement](https://github.com/dyne/Zenroom/blob/master/Agreement.md) then

1.  🔀 [FORK IT](https://github.com/dyne/Zenroom//fork)
2.  Create your feature branch `git checkout -b feature/branch`
3.  Commit your changes `git commit -am 'Add some fooBar'`
4.  Push to the branch `git push origin feature/branch`
5.  Create a new Pull Request `gh pr create -f`
6.  🙏 Thank you

***

## 💼 License

      Zenroom.py - a python wrapper of zenroom
      Copyright (c) 2018-2025 Dyne.org foundation, Amsterdam

      This program is free software: you can redistribute it and/or modify
      it under the terms of the GNU Affero General Public License as
      published by the Free Software Foundation, either version 3 of the
      License, or (at your option) any later version.

      This program is distributed in the hope that it will be useful,
      but WITHOUT ANY WARRANTY; without even the implied warranty of
      MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
      GNU Affero General Public License for more details.

      You should have received a copy of the GNU Affero General Public License
      along with this program.  If not, see <http://www.gnu.org/licenses/>.
# Use Zenroom as library in Java

## The binders

Zenroom binders for Java are written using The Java Native Interface (JNI) with Android applications in mind, and allow a Java application to pass a smart contract to Zenroom (via a buffer), then Zenroom returns the output to a buffer.
Zenroom assumes the code passed to it via buffers is Zencode (and not Lua). *Important*: Zenroom's Zencode parser expects each line to end with a 'newline', therefore each line of a Zencode smart contract should end with *\n* (see example below).

## Example

The following example generates an ECDH private key. 

```javascript
package com.example.zencode;

import androidx.appcompat.app.AppCompatActivity;

import android.os.Bundle;
import android.util.Log;

import decode.zenroom.Zenroom;

public class MainActivity extends AppCompatActivity {

    String script, data, keys, conf;

    static {
        try {
            System.loadLibrary("zenroom");
            Log.d("testZenroom", "Loaded zenroom native library");
        } catch (Throwable exc) {
            Log.d("testZeroom", "Could not load zenroom native library: " + exc.getMessage());
        }
    }
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        Log.d("testZenroom", "Starting the test....");

//  Important:
//  Each Zencode line should end with a "\n" 

        script = "rule check version 3.0.0\n"
        + "Scenario 'ecdh': Create the key\n"
		+ "Given I am 'Alice'\n"
		+ "When I create the ecdh key\n"
		+ "Then print my 'keyring'";
        keys = "";
        data= "";
        conf = "";

        String result = (new Zenroom()).execute(script, conf, keys, data);
    //       Log.d("testseb",(new Zenroom()).execute(script, conf, keys, data));
    //       Log.d("result",result);
        setContentView(R.layout.activity_main);
        findViewById(R.id.result).setText(result);

        setContentView(R.layout.activity_main);

    }
}
```

The result should look like this:


```json
{
   "Alice": {
      "keyring": {
         "ecdh": "OfLaWogJKLN3wsXlopBqVSS1LHxre3jT7uqOy1W6Mr0="
      }
   }
}
```

## Source

The Java binders can are [zenroom_jni.c](https://github.com/DECODEproject/Zenroom/blob/master/src/zenroom_jni.c) and [zenroom_jni.h](https://github.com/DECODEproject/Zenroom/blob/master/src/zenroom_jni.h)
# Use Zenroom as a library for iOS 

- Get the latest build of the lib on the [download page](https://zenroom.org/#downloads)
- Get the latest [zenroom.h](https://github.com/DECODEproject/Zenroom/blob/master/src/zenroom.h)
 - And make sure you add **#include <stddef.h>** to zenroom.h
- For a sample of the implementation, check the [decode app](https://github.com/dyne/decode-proximity-app/blob/master/ios/Zenroom.m#L31)
# Make 💏 with Zencode and Javascript: use Zenroom in node.js

This article is part of a series of tutorials about interacting with Zenroom VM inside the Javascript/Typescript messy world. This is the first entry and at the end of the article you should be able to implement your own encryption library with Elliptic-curve Diffie–Hellman.

The code used in this article is available on [Github](https://github.com/dyne/blog-code-samples).

## 📑 Some RTFM and resources

So first things first, let’s start by where to look for good information about Zenroom (docs that are continuously under enhancement and update).

- [https://dev.zenroom.org](https://dev.zenroom.org) this is the main source of technical documentation
- [https://zenroom.org](https://zenroom.org) here you find more informative documentation and all the products related to the main project
- [https://apiroom.net](https://apiroom.net) a very useful playground to try online your scripts

## 🌐 How a VM could live in a browser?

So basically Zenroom is a virtual machine that is mostly written in C and high-level languages and has no access to I/O and no access to networking, this is the reason that makes it so portable.


In the past years we got a huge effort from nice projects to transpile native code to Javascript, we are talking about projects like [emscripten](https://emscripten.org/), [WebAssembly](https://webassembly.org/) and [asm.js](http://asmjs.org/)


This is exactly what we used to create a WASM (WebAssembly) build by using the Emscripten toolkit, that behaves in a good manner with the JS world.

## 💻 Let’s get our hands dirty

So let’s start by our first hello world example in node.js I’m familiar with yarn so I’ll use that but if you prefer you can use `npm `


```bash
mkdir hello-world-zencode
cd !$
yarn init
yarn add zenroom
```


The previous commands create a folder and a js project and will add zenroom javascript wrapper as a dependency. The wrapper is a very simple utility around the pure emscripten build.


Next create a `index.js` with the following content

```javascript
const { zencode_exec } = require('zenroom')

const smartContract = `Given that I have a 'string' named 'hello'
                       Then print all data as 'string'`
const data = JSON.stringify({ hello: 'world!' })
const conf = 'debug=1'

zencode_exec(smartContract, { data, conf }).then(({ result }) => {
  console.log(result) // {"hello":"world!"}
})
```

run it with:

```bash
node index.js
```

Yay, 🥳 we just run our hello world in node.js

Let's go through lines; In first line we import the zencode_exec function from the zenroom package. Two major functions are exposed:

 - **zencode_exec** to execute Zencode (DSL for smart contracts that reads like English).
 - **zenroom_exec** to execute our special flavor of Lua enhanced with Zenroom’s [special effects](./lua).

Before you 🤬 on me for the underscore casing, this was a though decision but is on purpose to keep the naming consistent across all of our bindings.

**zencode_exec** is an asynchronous function, means return a Promise (more on promises [here](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Using_promises)) and accepts two parameters:

- the smart contract, mandatory, in form of string
- an optional object literal that can contain {data, keys, conf} in brief data and keys is how you pass data to your smart contract, and conf is a configuration string that changes the Zenroom VM behaviour. All of them should be passed in form of string… this means that even if you need to pass a JSON you need to JSON.stringify it before, as we did on line 5 of the previous snippet

**zencode_exec** resolves the promise with an object that contains two attributes:

- result this is the output of the execution of the smart contract in form of string
- logs the logs of the virtual machine… if there are some errors — warning they are printed here

In the previous snippet we just passed the *result* by using [Object destructuring](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/Destructuring_assignment#object_destructuring) on line 8


## 🔏 Let’s complicate it a bit! Let’s encrypt!
Now that we saw how the basics works, let’s proceed with some sophistication: let's encrypt a message with a password/secret with ECDH **(Elliptic-curve Diffie–Hellman)** on the elliptic curve SECP256K1 sounds complicated, isn't it?


```javascript
const { zencode_exec } = require('zenroom')

const smartContract = `Scenario 'ecdh': Encrypt a message with a password/secret
                        Given that I have a 'string' named 'password'
                        and that I have a 'string' named 'message'
                        When I encrypt the secret message 'message' with 'password'
                        Then print the 'secret message'`
const data = JSON.stringify({
  message: 'Dear Bob, your name is too short, goodbye - Alice.',
})
const keys = JSON.stringify({ password: 'myVerySecretPassword' })
const conf = 'debug=1'

zencode_exec(smartContract, { data, keys, conf }).then(({ result }) => {
  console.log(result)
})
```

Et voila 🤯 as easy as the hello the world… if you run it you'll get something like:

```json
{
  "secret_message": {
    "checksum": "507cpFVzIjwFXhvieeXq/A==",
    "header": "QSB2ZXJ5IGltcG9ydGFudCBzZWNyZXQ=",
    "iv": "vd7/4KIb3ubXElbGRRTyM4qTVtROkcacnaOeN5Pa0Vo=",
    "text": "HGsZTlnigSv6zlDpc1bZs40QMWbJxYf9CgjYLEpYI+t62WA6j+bPhfoUxxbnWkYVjX4="
  }
}
```

## 🔏 Next step: decryption

But being able to encrypt without having a decrypt function is useless, so  let's tidy up a bit and create our own encryption/decryption library with some javascript fun:

```javascript
const { zencode_exec } = require("zenroom");

const conf = "debug=1";

const encrypt = async (message, password) => {
  const keys = JSON.stringify({ password });
  const data = JSON.stringify({ message });
  const contract = `Scenario 'ecdh': Encrypt a message with a password/secret
    Given that I have a 'string' named 'password'
    and that I have a 'string' named 'message'
    When I encrypt the secret message 'message' with 'password'
    Then print the 'secret message'`;
  const { result } = await zencode_exec(contract, { data, keys, conf });
  return result;
};

const decrypt = async (encryptedMessage, password) => {
  const keys = JSON.stringify({ password });
  const data = encryptedMessage;
  const contract = `Scenario 'ecdh': Decrypt the message with the password
    Given that I have a valid 'secret message'
    Given that I have a 'string' named 'password'
    When I decrypt the text of 'secret message' with 'password'
    Then print the 'text' as 'string'`;
  const { result } = await zencode_exec(contract, { data, keys, conf });
  const decrypted = JSON.parse(result).text;
  return decrypted;
};

const message = "Dear Bob, your name is too short, goodbye - Alice.";
const password = 0xBADA55;
(async () => {
  // encrypt the message
  const encrypted = await encrypt(message, password);
  console.log(encrypted); // some crypto magic material
  const decrypted = await decrypt(encrypted, password);
  // let's verify that the original message is the same as the decrypted one
  if (message === decrypted) {
    console.log("🎉 🎉 🎉 ");
    console.log("Yeah! It works");
    console.log("🎉 🎉 🎉 ");
  }
})();
```

There you go encryption — decryption with password — secret over Elliptic-curve Diffie–Hellman on curve SECP256K1 in 30 super easy lines of code.

The code used in this article is available on [Github](https://github.com/dyne/blog-code-samples).
# Make 💏 with Zencode and Javascript: use Zenroom in the browser

This article is part of a series of tutorials about interacting with Zenroom VM inside the messy world of JavaScript/Typescript.
By the end of the article you should be able to launch a new encryption service with Elliptic-curve Diffie–Hellman within your browser (Plain JS and HTML).

The code used in this article is available on [Github](https://github.com/dyne/blog-code-samples).


## 🏹 Let's create a encrypt/decrypt service
So you have just experimented how to encrypt and decrypt a message with a password/secret with ECDH (Elliptic-curve Diffie–Hellman) on the elliptic curve SECP256K1 (Did you? No? Then, jump back to [Zenroom in node.js](/pages/zenroom-javascript1b)).
Now say you love simple things and you just need some basic functions inside your HTML page (no npm, no nodejs, no fancy hipster new shiny stuff) with the good ol' Plain JavaScript.
NO PROBLEM. You bet we love it.

## 💻 Let’s get our hands dirty: 🔏 encryption

Let's create an **index.html** file, the first thing that we want is to import our **zencode_exec** function

```html
<script type="module">
  import { zencode_exec } from "https://jspm.dev/zenroom";
</script>
```

This is a no brainer with CDNs like jspm that allows you to [import JavaScript modules](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Modules). The jspm site says:

*jspm provides a module CDN allowing any package from npm to be directly loaded in the browser and other JS environments as a fully optimized native JavaScript module.*

So this is handy and neat, let's move on. Remember the encryption function? Let's copy paste it, and in place of getting password and message as function parameters we retrieve them from two HTMLElements and print the output to a third element

```html
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>ECDH Encrypt/Decrypt online</title>
    <script type="module">
      import { zencode_exec } from "https://jspm.dev/zenroom";

      const conf = "debug=1";

      window.encrypt = () => {
        const password = document.getElementById('encryptPassword').value
        const message = document.getElementById('plainMessage').value
        const keys = JSON.stringify({ password });
        const data = JSON.stringify({ message });
        const contract = `Scenario 'ecdh': Encrypt a message with a password/secret
          Given that I have a 'string' named 'password'
          and that I have a 'string' named 'message'
          When I encrypt the secret message 'message' with 'password'
          Then print the 'secret message'`;
        zencode_exec(contract, { data, keys, conf }).then(({result}) => {
          const rel = document.getElementById('encrypted')
          rel.value = result
        })
      }
    </script>
  </head>
  <body>
     <textarea id="plainMessage"></textarea>
     <br/>
     <input id="encryptPassword" class="input" type="password" />
     <button onClick="encrypt()">🔐 Encrypt</button>
     <br/>
     <textarea id="encrypted" readonly></textarea>
  </body>
</html>
```

The expected result is something like:

![javascript-2a](../_media/images/javascript-2a.png)

It's ugly, almost unusable, but It works! 🥳
A couple of hints to pay attention, as I said before. We'll use JavaScript module so *type="module"* on the *script* tag is important. Since we are inside the module scope to make the encrypt() function available to our page we should add it to the window object, so take an eye to line 12 of the previous snippet.
Let's add a couple lines of styling (not so much) and some visual feedback on successful encryption. I'll use [bulma](https://bulma.io/) here, a super easy CSS framework.


```html
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Encrypt/Decrypt online</title>
    <link
      rel="stylesheet"
      href="https://cdn.jsdelivr.net/npm/bulma@0.9.1/css/bulma.min.css"
    />
    <script type="module">
      import { zencode_exec } from "https://jspm.dev/zenroom";

      const conf = "debug=1";

      window.encrypt = () => {
        const password = document.getElementById('encryptPassword').value
        const message = document.getElementById('plainMessage').value
        const keys = JSON.stringify({ password });
        const data = JSON.stringify({ message });
        const contract = `Scenario 'ecdh': Encrypt a message with a password/secret
          Given that I have a 'string' named 'password'
          and that I have a 'string' named 'message'
          When I encrypt the secret message 'message' with 'password'
          Then print the 'secret message'`;
        zencode_exec(contract, { data, keys, conf }).then(({result}) => {
          const rel = document.getElementById('encrypted')
          rel.value = result
          rel.classList.add("is-success");
        })
      };
    </script>
  </head>
  <body>
    <section class="section">
      <div class="container">
        <h1 class="title">ECDH encrypt</h1>
        <div class="columns">
          <div class="column is-one-third">
            <div class="field">
              <label class="label">Message</label>
              <div class="control">
                <textarea
                  id="plainMessage"
                  class="textarea"
                  placeholder="Message to encrypt"
                ></textarea>
              </div>
            </div>
            <div class="field is-grouped">
              <div class="control">
                  <input class="input"
                    type="password" placeholder="password" id="encryptPassword">
              </div>
              <div class="control">
                <button
                  class="button is-primary"
                  onClick="encrypt()">🔐 Encrypt</button>
              </div>
            </div>
          </div>
          <div class="column">
            <label class="label">Result</label>
            <div class="control">
              <textarea
                id="encrypted"
                class="textarea is-family-monospace"
                readonly
              ></textarea>
            </div>
          </div>
        </div>
      </div>
    </section>
  </body>
</html>
```
That will show something like:

![javascript-2b](../_media/images/javascript-2b.png)

Yeah this is much better 💅🏼

## 🔏 Next step: decryption


Let's add also the decrypt function and we are ready to deploy our static and super fast ECDH encrypt/decrypt service over the WWW.



```html
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Encrypt/Decrypt online</title>
    <link
      rel="stylesheet"
      href="https://cdn.jsdelivr.net/npm/bulma@0.9.1/css/bulma.min.css"
    />
    <script type="module">
      import { zencode_exec } from "https://jspm.dev/zenroom";

      const conf = "debug=1";

      window.encrypt = () => {
        const password = document.getElementById('encryptPassword').value
        const message = document.getElementById('plainMessage').value
        const keys = JSON.stringify({ password });
        const data = JSON.stringify({ message });
        const contract = `Scenario 'ecdh': Encrypt a message with a password/secret
          Given that I have a 'string' named 'password'
          and that I have a 'string' named 'message'
          When I encrypt the secret message 'message' with 'password'
          Then print the 'secret message'`;
        zencode_exec(contract, { data, keys, conf }).then(({result}) => {
          const rel = document.getElementById('encrypted')
          rel.value = result
          rel.classList.add("is-success");
        }).catch(({logs}) => {
          const rel = document.getElementById('encrypted')
          rel.value = logs
          rel.classList.add("is-danger");
        })
      };

      window.decrypt = () => {
        const password = document.getElementById('decryptPassword').value;
        const keys = JSON.stringify({ password });
        const data = document.getElementById('encryptedMessage').value;
        const contract = `Scenario 'ecdh': Decrypt the message with the password
          Given that I have a valid 'secret message'
          Given that I have a 'string' named 'password'
          When I decrypt the text of 'secret message' with 'password'
          Then print the 'text' as 'string'`;
        zencode_exec(contract, { data, keys, conf }).then(({result}) => {
          const decrypted = JSON.parse(result).text;
          const rel = document.getElementById('decrypted')
          rel.value = decrypted
          rel.classList.add("is-success");
        }).catch(({logs}) => {
          const rel = document.getElementById('decrypted')
          // extract the error part of the logs
          const err = JSON.parse(logs).reduce((x, l) => {
            if (l.startsWith('J64 TRACE:')) {
              const b64Trace = l.slice('J64 TRACE: '.length);
              const arrayTrace = JSON.parse(atob(b64Trace));
              for (const t of arrayTrace) {
                if (t.startsWith('[!]')) {
                  x.push(t);
                }
              }
            } else if (l.startsWith('[!]')) {
              x.push(l);
              return x;
            }
            return x;
          }, []);
          rel.value = err.join("\n");
          rel.classList.add("is-danger");
        });
      };
    </script>
  </head>
  <body>
    <section class="section">
      <div class="container">
        <h1 class="title">ECDH encrypt</h1>
        <div class="columns">
          <div class="column is-one-third">
            <div class="field">
              <label class="label">Message</label>
              <div class="control">
                <textarea
                  id="plainMessage"
                  class="textarea"
                  placeholder="Message to encrypt"
                ></textarea>
              </div>
            </div>

            <div class="field is-grouped">
              <div class="control">
                  <input class="input" type="password" placeholder="password" id="encryptPassword">
              </div>
              <div class="control">
                <button class="button is-primary" onClick="encrypt()">🔐 Encrypt</button>
              </div>
            </div>
          </div>
          <div class="column">
            <label class="label">Result</label>
            <div class="control">
              <textarea
                id="encrypted"
                class="textarea is-family-monospace"
                readonly
              ></textarea>
            </div>
          </div>
        </div>
      </div>
    </section>
    <section class="section">
      <div class="container">
        <h1 class="title">ECDH decrypt</h1>
        <div class="columns">
          <div class="column">
            <div class="field">
              <label class="label">Encrypted message</label>
              <div class="control">
                <textarea
                  id="encryptedMessage"
                  class="textarea"
                  placeholder="Message to decrypt"
                ></textarea>
              </div>
            </div>

            <div class="field is-grouped">
              <div class="control">
                  <input class="input" type="password" placeholder="password" id="decryptPassword">
              </div>
              <div class="control">
                <button class="button is-primary" onClick="decrypt()">🔓 Decrypt</button>
              </div>
            </div>
          </div>
          <div class="column is-one-third">
            <label class="label">Result</label>
            <div class="control">
              <textarea
                id="decrypted"
                class="textarea is-family-monospace"
                readonly
              ></textarea>
            </div>
          </div>
        </div>
      </div>
    </section>
  </body>
</html>
```

The final result is something like

![javascript-2c](../_media/images/javascript-2c.png)

You can try it by yourself, encrypt a message with a password, then copy/paste the result into the **Encrypted message** field and if you put the same password the message is decrypted and the result is correctly shown.

What if the password is wrong? Validation is demanded just in the ZenroomVM so I've just added a *catch* to the *zencode_exec* promise (see line 51–71) that will show the logs in the result element if something goes wrong!

The code used in this article is available on [Github](https://github.com/dyne/blog-code-samples).
# Make 💏 with Zencode and Javascript: use Zenroom in React



## 🏹 Let’s create a encrypt/decrypt service
So you have just experimented how to encrypt and decrypt a message with a password/secret with ECDH (Elliptic-curve Diffie–Hellman) on the elliptic curve SECP256K1 in Plain Javascript (Did you? No? Then, jump back to [Zenroom in the browser](zenroom-javascript2b)).

Now let's add some interactivity and see how we can play and interact with Zencode smart contracts within React.


## 💻 Let’s get our hands dirty

Let’s start by creating a standard React project with the [CRA](https://reactjs.org/docs/create-a-new-react-app.html) tool, and add Zenroom as a dependency

```bash
npx create-react-app zenroom-react-test
```

Using npm you should now have into `zenroom-react-test` a file structure like this

```bash
.
├── package.json
├── package-lock.json
├── public
│   ├── favicon.ico
│   ├── index.html
│   ├── logo192.png
│   ├── logo512.png
│   ├── manifest.json
│   └── robots.txt
├── README.md
└── src
│   ├── App.css
│   ├── App.js
│   ├── App.test.js
│   ├── index.css
│   ├── index.js
│   ├── logo.svg
│   ├── reportWebVitals.js
│   └── setupTests.js
└── node_modules
│   ├── ...
```

Before proceeding the following steps are necessary since `react-scripts`v5 excluded the support
for some node features and polyfills:
* Install `react-app-rewired` as a dev dependency

<!--- tabs:start -->

### **npm**

```bash
npm install --save-dev react-app-rewired
```

### **yarn**

```bash
yarn add --dev react-app-rewired
```

### **pnpm**

```bash
pnpm add --save-dev react-app-rewired
```

### **bun**

```bash
bun add --dev react-app-rewired
```
<!--- tabs:end -->
* open the `package.json` and change the `scirpts` section with:
```json
{
  "start": "react-app-rewired start",
  "build": "react-app-rewired build",
  "test": "react-app-rewired test",
  "eject": "react-app-rewired eject"
}
```
* create the `config-overrides.js` file and write in it:
```js
module.exports = function override(config) {
    config.resolve.fallback = {
        fs: false,
        path: false,
        crypto: false,
        process: false,
    };
    return config;
};
```


We are almost there! Now let's add **zenroom** as a dependency

<!--- tabs:start -->

### **npm**

```bash
npm install zenroom
```

### **yarn**

```bash
yarn add zenroom
```

### **pnpm**

```bash
pnpm add zenroom
```

### **bun**

```bash
bun add zenroom
```

<!--- tabs:end -->

We are now ready to start with our `hello world` smart contract!
Edit the `src/App.js` as such:

```javascript
import {useEffect, useState} from 'react'
import {zencode_exec} from 'zenroom'

function App() {
  const [result, setResult] = useState("");

  useEffect(() => {
    const exec = async () => {
      const smartContract = `Given that I have a 'string' named 'hello'
                             Then print all data as 'string'`
      const data = JSON.stringify({ hello: 'world!' })
      const conf = 'memmanager=lw'
      const {result} = await zencode_exec(smartContract, {data, conf});
      setResult(result)
    }

    exec()
  })


  return (
    <h1>{result}</h1>
  );
}

export default App;
```

and start the app:

<!--- tabs:start -->

### **npm**

```bash
npm start
```

### **yarn**

```bash
yarn start
```

### **pnpm**

```bash
pnpm start
```

### **bun**

```bash
bun start
```

<!--- tabs:end -->

You are good to go, open `http://localhost:3000/` and you should see something like:


![Result of zenCode on React](../_media/images/zenroom-react1.png)

Hoorayyy!!!  You just run a Zencode smart contract in React with no fuss. 🥳🥳🥳 And with this now you are able to maybe create your `<Zencode>` or `<Zenroom>` components and endless creative and secure possibilities.


## 🔏 Let’s complicate it a bit! Let’s encrypt!

Now that we saw how the basics works, let’s proceed with some sophistication: let’s encrypt a message with a password/secret with **ECDH (Elliptic-curve Diffie–Hellman)** on the elliptic curve SECP256K1 sounds complicated, isn’t it?

Firstl install some other packages:

<!--- tabs:start -->

### **npm**

```bash
npm install reactstrap @microlink/react-json-view
```

### **yarn**

```bash
yarn add reactstrap @microlink/react-json-view
```

### **pnpm**

```bash
pnpm add reactstrap @microlink/react-json-view
```

### **bun**

```bash
bun add reactstrap @microlink/react-json-view
```

<!--- tabs:end -->

now edit again the `src/App.js` file:

```javascript
import { useEffect, useState } from "react";
import { zencode_exec } from "zenroom";
import { Form, FormGroup, Label, Input, Container } from "reactstrap";
import ReactJson from "@microlink/react-json-view";

function App() {
  const [result, setResult] = useState({});
  const [message, setMessage] = useState("");
  const [password, setPassword] = useState("");

  useEffect(() => {
    const conf = "debug=1";
    const encrypt = async (message, password) => {
      if (!message || !password) return;
      const keys = JSON.stringify({ password });
      const data = JSON.stringify({ message });
      const contract = `Scenario 'ecdh': Encrypt a message with a password/secret
        Given that I have a 'string' named 'password'
        and that I have a 'string' named 'message'
        When I encrypt the secret message 'message' with 'password'
        Then print the 'secret message'`;
      const { result } = await zencode_exec(contract, { data, keys, conf });
      setResult(JSON.parse(result));
    };

    encrypt(message, password);
  }, [message, password]);

  return (
    <Container>
      <Form>
        <FormGroup>
          <Label for="password">Password</Label>
          <Input
            type="text"
            name="password"
            id="password"
            onChange={(e) => {
              setPassword(e.target.value);
            }}
          />
        </FormGroup>
        <FormGroup>
          <Label for="message">Message</Label>
          <Input
            type="textarea"
            id="message"
            onChange={(e) => {
              setMessage(e.target.value);
            }}
          />
        </FormGroup>
      </Form>
      <ReactJson src={result} />
    </Container>
  );
}
export default App;
```

Et voila 🤯 as easy as the hello the world! We added an encryption function, and some component to give some styling. If you run it you’ll get something like:


<img src="../_media/images/zenroom-react2.gif" alt="drawing" width="1200"/>




It's embarrassing fast, encryption with password over Elliptic-curve Diffie–Hellman on curve SECP256K1 in react! Now hold tight until next week for the part 4… in the meantime clap this post and spread it all over the socials.

One last thing, you’ll find the working code project on [Github](https://github.com/dyne/blog-code-samples/tree/master/zencode-javascript-series/part3-react)
# Intro

While Zenroom can be used in JS as a library, both natively as well as WASM, we've incidentally gathered more experience with React Native integration. The first experiment was the [DECODE App](https://github.com/DECODEproject/decode-app) which we have mantained and updated into the [DECODE Proximity App](https://github.com/dyne/decode-proximity-app) and part of this integration has been used in the [Global Passport Project App](https://github.com/LedgerProject/GPP_app), here we are reporting some of their internal documentation used to setup Zenroom. 

We have been using Zenroom built as native libraries, for mobile applications, because at the moment of writing, React Native does not yet support WASM, although currently experiments are being performed in that direction, so we hope that the situation will change at some point. 

### The libraries 

You can download the latest nightly builds as well as the point releases on [https://zenroom.org/#downloads](https://zenroom.org/#downloads). We will add more builds as soon as we implement them.


### ***Important***: how to manage empty strings

One of the major headaches, for reasons that go beyond human comprehension, was the management of empty strings. Zenroom accepts parameters only as strings, meaning that you'll need to use *JSON.stringify* when passing a JSON object to it. Passing an empty JSON to *JSON.stringify* will return an object looking like this:

```json
{}
```

which on some (!) Zenroom builds will produce a crash. Therefore, whenever you're passing an empty parameter, you'll need ***pass an empty string*** ( [Android](https://github.com/LedgerProject/GPP_app/blob/409e626956a9c9e0950fb45c1ab06343485a8acf/android/app/src/main/java/decode/zenroom/ZenroomModule.java#L51-L58) ). 


## Android Setup

How to configure Zenroom in React Native on Android. Based on the DECODE APP's [commit](https://github.com/DECODEproject/decode-app/commit/9b6c9322f941bf91319556f2838409551e0aa2c7): 

### Step 1: build.gradle
In the file *android/app/build.gradle* in the *dependencies*, insert the string:
```javascript
implementation fileTree(dir: "jniLibs", include: ["*.so"])
```

The result should look like: 

```javascript
implementation project(':react-native-gesture-handler')
implementation project(':react-native-device-info')
implementation fileTree(dir: "libs", include: ["*.jar"])
implementation fileTree(dir: "jniLibs", include: ["*.so"])

implementation "com.android.support:appcompat-v7:${rootProject.ext.supportLibVersion}"
implementation "com.facebook.react:react-native:+"
```

Also make sure you tell gradle what ABIs it has use, which you do by adding to *build.gradle* the following lines (as you can see [here](https://github.com/LedgerProject/GPP_app/blob/409e626956a9c9e0950fb45c1ab06343485a8acf/android/app/build.gradle#L137-L139)):

```javascript
android {

   \\  ... stuff here

        ndk {
            abiFilters "armeabi-v7a", "arm64-v8a", "mips" //  "x86" are "x86_64" are coming soon
        }
    }
```




### Step 2: java setup
In the file *android/app/src/main/java/com/company-name/app-name/MainApplication.java* insert the string:

```java
import decode.zenroom.ZenroomPackage;
```

The result should look like: 

```java
import java.util.Arrays;
import java.util.List;
import decode.zenroom.ZenroomPackage;
```


As well as the string:
```java
packages.add(new ZenroomPackage());
```

The result should look like:

```java
protected List<ReactPackage> getPackages() {
  @SuppressWarnings("UnnecessaryLocalVariable")
  List<ReactPackage> packages = new PackageList(this).getPackages();
  packages.add(new SplashScreenPackage());
  packages.add(new ZenroomPackage());
  return packages;
}
```

### Step 3: more java setup
Copy the folder *decode* in *android/app/src/main/java*. The structure of the folder should be as following:

 - android\app\src\main\java\decode\zenroom\Zenroom.java
 - android\app\src\main\java\decode\zenroom\ZenroomModule.java
 - android\app\src\main\java\decode\zenroom\ZenroomPackage.java


### Step 4: the libraries

Copy the folder *jniLibs* and its content into *android/app/src/main*. The structure of the folder should be as following:
 - android\app\src\main\jniLibs\arm64-v8a\libzenroom.so
 - android\app\src\main\jniLibs\armeabi-v7a\libzenroom.so
 - android\app\src\main\jniLibs\x86\libzenroom.so

The files named *libzenroom.so* need to have the same name, although they will have different sizes, as there is one per architecture.

### Execute a Zenroom smart contract:

 - Create a file named zenroom-client.js containing the code:
```javascript
import { NativeModules } from 'react-native';
export default NativeModules.Zenroom;
```

 - In order to execute a smart contract, create a file containing the code:

```javascript
       import zenroom from 'percorso/file/zenroom-client';

		//   ...  your code here

       const keys = {“key”: “value”}; //Insert here "keys" parameter to pass
       const data = {“key”: “value”}; //Insert here "data" parameter to pass

		// Important: you can execute JSON.stringify only if the object is NOT EMPTY
		// else you need to pass Zenroom an empty string 

		const keysStr = JSON.stringify(keys);
		const dataStr = JSON.stringify(data);

		const zenroomContract = `
         Scenario coconut: issuer keygen
         Given that I am known as 'Alice'
         When I create the issuer keypair
         Then print my 'issuer keypair'
		`; // <-- Insert the Zenroom smart contract here

		// Important: if the parameters “keys” or “data” are empty, 
		// you need to pass an empty string to zenroom.execute instead of using 
		// JSON.stringify, else Zenroom will return an exception 

		try {
         const response = await zenroom.execute(
           zenroomContract,
           dataStr,
           keysStr
         );

         return JSON.parse(response); //Result of the Zenroom script
       } catch (e) {
         console.log(e);
       }
```


--------

## iOS setup


Configuration of the Zenroom library on React Native (iOS). You'll want to use the function **zencode_exec_tobuf** whose signature you can find in [zenroom.h](https://github.com/dyne/Zenroom/blob/master/src/zenroom.h#L37-L40). 

### Step 1: copy libs and headers
Copy in the folder *ios* the files:
 - Zenroom.h
 - Zenroom.m
 - zenroomInternal.h
 - zenroom-ios-arm64.a
 - zenroom-ios-armv7.a
 - zenroom-ios-x86_64.a

### Step 2: install
If you haven't done it yet, from your console, open the *ios* folder and run:

```bash
pod install –-repo-update
```

### Step 3: include files
Open in Xcode the workspace *yourAppName.xcworkspace* and include the files you have just copied.

### Step 4: Build settings
Select the project and in the tab *Build Settings* set the parameter *Validate Workspace* to *Yes*.

### Execute a Zenroom smart contract

 - Create a file name *zenroom-client.js* containing the code:
 
```javascript
import { NativeModules } from 'react-native';
export default NativeModules.Zenroom;
```

 - Create one more a file named like *mySmartContract.js* containing the code (and the smart contract):

```javascript
 import zenroom from 'path/file/zenroom-client';
	   
       // ... your code here
    
	const keys = {}; //insert here keys you want to pass, usually this contains keys, credentials etc
       	const data = {}; //insert here data you want to pass, this usually contains generic data 
       	const zenroomContract = `
         Scenario coconut: issuer keygen
         Given that I am known as 'Alice'
         When I create the issuer keypair
         Then print my 'issuer keypair'
       `; // <-- write here your Zenroom smart contract

       try {
         const response = await zenroom.execute(
           zenroomContract,
           JSON.stringify(keys),
           JSON.stringify(data)
         );

         return JSON.parse(response); //Zenroom result
       } catch (e) {
         console.log(e);
       }
```

      



<!-- commented
 



-->
# Make ❤ with Zenroom in ClojureScript

This article shows how to use Zenroom from ClojureScript using shadow-cljs, by [transducer](https://github.com/transducer/zenroom-cljs-demo/blob/master/blogpost.md).



### 💻 npm

Install [shadow-cljs](https://github.com/thheller/shadow-cljs) and the zenroom bindings using `npm` or `yarn`:

```sh
# npm
npm install -g shadow-cljs --save-dev
npm install zenroom

# yarn
yarn global add shadow-cljs --dev
yarn add zenroom
```

### 💻 shadow-cljs

Create a `shadow-cljs.edn` with a build hook:

```clojure
{:nrepl {:port 8777}
 :source-paths ["src"]
 :dependencies [[binaryage/devtools "1.0.0"]
                [reagent "1.0.0-alpha2"]] ;; assuming we use Reagent
 :builds {:app {:target :browser
                :build-hooks [(build/setup-zenroom-wasm-hook)]
                :output-dir "resources/public/js/compiled"
                :asset-path "/js/compiled"
                :modules {:app {:init-fn view/init
                                :preloads [devtools.preload]}}
                :devtools {:http-root "resources/public"
                           :http-port 8280}}}}
```

### ✍ Build hook to be browser ready

In ClojureScript in the browser we also need to move the WebAssembly as described in [Part three Zenroom in React](https://www.dyne.org/using-zenroom-with-javascript-react-part3/):

1. We need to make `zenroom.wasm` from the npm package available on the server (in our case by copying it into `resources/public`).
1. We need to remove the line from `zenroom.js` that tries to locate `zenroom.wasm` locally.

With a [shadow-cljs build hook](https://shadow-cljs.github.io/docs/UsersGuide.html#build-hooks) we can automate this process:

```clojure
(ns build
  (:require
   [clojure.java.shell :refer [sh]]))

(defn- copy-wasm-to-public []
  (sh "cp" "node_modules/zenroom/dist/lib/zenroom.wasm" "resources/public/"))

(defn- remove-locate-wasm-locally-line []
  (sh "sed" "-i.bak" "/wasmBinaryFile = locateFile/d" "node_modules/zenroom/dist/lib/zenroom.js"))

(defn setup-zenroom-wasm-hook
  {:shadow.build/stage :configure}
  [build-state]
  (copy-wasm-to-public)
  (remove-locate-wasm-locally-line)
  build-state)
```

The build hook will run when we `shadow-cljs watch app dev` or `shadow-cljs release app`.

We do not need this build hook when targeting Node.

### ☯  ClojureScript interop

We can use JavaScript interop to interact with the Zenroom npm package.

```clojure
(require '[zenroom])

;; Assuming we have a Reagent @app-state

(defn evaluate! []
  (doto zenroom
    (.script (:input @app-state))
    (.keys (-> @app-state :keys read-string clj->js))
    (.data (-> @app-state :data read-string clj->js))
    (.print (fn [s] (swap! app-state update :results conj s)))
    (.success (fn [] (swap! app-state assoc :success? true)))
    (.error (fn [] (swap! app-state assoc :success? false)))
    .zencode-exec))
```

`evaluate!` now obtains input from the `@app-state` and has callback functions that set results of Zencode evaluation.

### ☕ More code

Source code of a full example is available at [https://www.github.com/transducer/zenroom-cljs-demo](https://www.github.com/transducer/zenroom-cljs-demo).
Error: File './pages/restroom-mw' not found.
Error: File './ext/redroom' not found.
Error: File './ext/lotionroom' not found.
Error: File './ext/sawroom' not found.
Error: File './pages/apiroom' not found.
# Build instructions

This section is optional for those who want to build this software from source. The following build instructions contain generic information meant for an expert audience.

!> After cloning this source code from git, one should do:
```bash
git submodule update --init --recursive
```

The Zenroom compiles the same sourcecode to run on Linux in the form of 2 different POSIX compatible ELF binary formats using GCC (linking shared libraries) or musl-libc (fully static) targeting both X86 and ARM architectures.
It also compiles to a Windows 64-bit native and fully static executable. At last, it compiles to Javascript/Webassembly using the LLVM based emscripten SDK. To recapitulate some Makefile targets:

## Prerequisites

<!-- tabs:start -->
#### **Devuan / Debian / Ubuntu**
```bash
apt-get install -y git build-essential cmake xxd libreadline-dev
```
<!-- tabs:end -->

## Shared builds
The simpliest, builds a shared executable linked to a system-wide libc, libm and libpthread (mostly for debugging)
Then first build the shared executable for your platform:

<!-- tabs:start -->

#### ** Linux **

```bash
make linux-exe
```

#### ** macOS **

```bash
make osx-exe
```

#### ** Windows **

Builds a Windows 64bit executable with no DLL dependancy, containing
the LUA interpreter and all crypto functions, for client side
operations on windows desktops.

```bash
make win-exe
```

<!-- tabs:end -->


To run tests:

<!-- tabs:start -->

#### ** Functional **

```bash
make check
make check-osx
```

#### ** Integration **

```bash
make check-js
make check-rp
```

<!-- tabs:end -->

## Static builds
Builds a fully static executable linked to musl-libc (to be operated on embedded platforms).

As a prerequisite you need the `musl-gcc` binary installed on your machine.

**eg.** on [Devuan](https://devuan.org) you can just
```bash
  apt install musl-tools
```

To build the static environment with musl installed system wide run:

```bash
make musl
```

<!---
There are also two other targets that looks for the `libc` in other places.

For `/usr/local/musl/lib/libc.a` run
```bash
make musl-local
```

For `/usr/lib/${ARCH}-linux-musl/libc.a`
```bash
make musl
```
-->

## Javascript builds

For the Javascript and WebAssembly modules the Zenroom provides various targets using [Emscripten](https://emscripten.org/) which must be installed and loaded in the environment according to the emsdk's instructions, then linked inside the `build` directory of zenroom sources.

!> (needs NodeJS) To build you need to have [NodeJS](https://nodejs.org) and [Yarn](https://yarnpkg.com/) installed, as well Lua5.3

1. Download the latest EMSDK from https://github.com/emscripten-core/emsdk/tags inside the root of Zenroom source folder, extract it, rename the resulting subfolder to `emsdk`
2. enter the folder and run `./emsdk install latest`, wait until the installation is complete, then run `./emsdk activate latest`
3. go back in the zenroom root and activate emsdk with `. emsdk/emsdk_env.sh` (please note the dot followed by space at beginning)
5. Make sure the Zenroom source is clean with `make clean`
5. Launch `make node-wasm` to install nodejs dependencies and build Zenroom WASM
6. Launch `make check-js` to run all javascript tests

The resulting `zenroom.js` module will be found in `bindings/javascript/dist/` and should have zero dependencies from other NodeJS packages.

Keep in mind there is some boilerplate needed to include it inside your application, which is provided automatically if you simply use our [npm zenroom package](https://www.npmjs.com/package/zenroom).

## Build instructions for Mobile libraries

### iOS

You need to have install `Xcode` with the `commandline-tools`

There are 3 different targets `ios-sim` `ios-armv7` `ios-arm64` these targets creates an static library with the correct architecture (x86_64, ARMV7, ARM64).

Finally once done all the libraries there is a final target `ios-fat` that put them together creating a fat-binary that you can include into your app.

Or you can just use the `build-ios.sh` that does all the steps for you!

For using the library just copy `zenroom.a` somewhere in your project and include the zenroom.h file.

### Android

You need to have installed `android-sdk` (if you have Android Studio installed, it is already there) and set the `ANDROID_HOME` variable.

Also you need to install NDK inside the android-sdk using the Android Studio -> Tools -> Android -> SDK Manager. If you have installed the NDK somewhere else, just set the environment variable NDK_HOME to reflect this.

Finally use the `build/build-android.sh` script (if neither `ANDROID_HOME` nor `NDK_HOME` is set, the script will try default install paths of `ANDROID_HOME=~/Android/Sdk` and `NDK_HOME=${ANDROID_HOME}/ndk-bundle`). This will place the Android target libraries in `build/target`

```
build/target/
└── android
    └── jniLibs
        ├── arm64-v8a
        │   └── libzenroom.so
        ├── armeabi-v7a
        │   └── libzenroom.so
        └── x86
            └── libzenroom.so
```

To use it in your project just drop `src/Zenroom.java` inside your codebase and the put `jniLibs` and its contents directly into your Android project under `src/main`

```
src/main/jniLibs/
├── arm64-v8a
│   └── libzenroom.so
├── armeabi-v7a
│   └── libzenroom.so
└── x86
    └── libzenroom.so
```
# To build

make cortex-arm

# To launch in qemu
```
qemu-system-arm -M mps2-an385 --kernel src/zenroom.bin -nographic -semihosting -S -gdb tcp::3333 
```
# To connect from gdb-multiarch
```
gdb-multiarch
tar rem:3333
file src/zenroom.elf
b main
c
lay src
mon system_reset
foc c
foc s
lay reg
```
# Random quality measurements

Obviously, randomness is very important when doing cryptography.

Zenroom accepts a random seed when called or retrieves one
automatically from the host system.

**Zenroom is fully deterministic**: if the same random seed is
provided then all results of transformations will be exactly the same,
except for the sorting order of elements in its output, which must be
sorted by the caller with a constant algorithm.

If the random seed is not provided at call time, then Zenroom does its
best to gather a good quality random seed from the host system. This
works well on Windows, OSX, GNU/Linux as well Android and iOS; but
beware that **when running in Javascript random is very weak**.

## Measure your system

To have a value estimation on the system you are currently running
Zenroom, run the LUA command `BENCH.entropy()` and compare these
results:

```
 .  Benchmark: entropy of random generators (Shannon ratios)
SEED: 	 0.9772232
PRNG: 	 0.9737687
OCTET: 	 0.9880916
BIG:   	 0.9885069
ECP:   	 0.9880916
ECP2:  	 0.9810042
```

The `SEED` value is the one gathered from the underlying system or
passed by the host application calling Zenroom.

The `PRNG` is the value yield by the "pseudo" random generator which
is processing the SEED to produce a deterministic series of random
values based on it.

Given 1.0 is the ideal maximum for entropy, all values yield on your
system should be close to the ones above, indicating a sane amount of
entropy for cryptographic operations and in particular key generation.

### FIPS140-2 compliancy

Zenroom can be proven to comply with the [Federal Information
Processing Standard (FIPS) Publication
140-2](https://en.wikipedia.org/wiki/FIPS_140-2) launching the
`./test/random_rngtest_fips140-2.sh` test on a system where
`rng-tools` are installed.

This script will feed 1000 blocks, each consisting of 2500 bytes long
random sequences and print the results given by the test program
`rngtest`.

## Pseudo-random generator

In order to generate key material, it is often needed to have a random
number generator (RNG). But generating good randomness (one which is
unpredictable to attackers) is very challenging for a variety of reasons.
An alternative to use RNG is to use Pseudo Random Generators (PRNG), which
pseudo random data is generated from a seed by a deterministic algorithm.
It is often the case as well that the seed for this PRNG is actual real
random data.

In the context of a cryptographic system, this pseudo random data should not
give information of any past nor future outputs from the PRNG. This is
difficult to prevent as an attacker at some point might be able to acquire
the internal state of a PRNG, which can lead to they being able to
follow all of the outputs of the internal state of the generator. Once
the PRNG internal state is compromised is difficult to recover it a
secure state again.

Cryptographic strength is added to any random seed by Zenroom's
pseudo-random generator (PRNG) which is an [old RSA
standard](ftp://ftp.rsasecurity.com/pub/pdfs/bull-1.pdf) basically
consisting of:

```txt
Unguessable seed -> SHA -> PRNG internal state -> SHA -> random numbers
```
-----

## Hamming distance frequency

As a reference indicator of results here we provide a graph that shows
the [Hamming distance](https://en.wikipedia.org/wiki/Hamming_distance)
measuring how many different bits are there between each new random
776 bit long octets. This benchmark was run on a PC gathering entropy
from system events:

![Hamming distance random benchmark](../_media/images/random_hamming_gnuplot.png)

Here are represented four different random generation methods which
are commonly used in cryptographic transformations. It is noticeable
that the most common average distance is **between 380 and 400 bits**
for all of them.
# Web Encryption Demo

Demo of in-browser asymmetric AES-GCM encryption.

Zencode Smart Contract in human language (WASM-web build)

For more information see [Zenroom.org](https://zenroom.org).

<span class="big"> <span class="mdi mdi-code-braces"></span> [Code for this example](code)</span>

# Zencode contract

<pre id="encrypt_contract"></pre>


## Alice keypair

<code id="alice"></code>

## Bob public key

<code id="bob"></code>

------------------------

# Upload file

Select a file on the local hard disk of maximum size 400KiB.

Nothing will be uploaded to any server.

Files are encrypted on the fly inside the browser.

  <form method="post" enctype="multipart/form-data">
    <input type="file" name="rawfile" />
    <input type="submit" value="Upload File" name="submit" />
  </form>
  <hr/>
  <div>Speed: <span id="speed"></span> ms</div>
  <hr/>
  <small><code id="result"></code></small>

<script async type="text/javascript" src="../_media/js/zenroom.js"></script>
<script type="text/javascript" src="../_media/js/encrypt.js"></script>


Mostly for fun, we put together a tiny bot for [Telegram](https://web.telegram.org/) that allows you to encrypt and decrypt messages using a password. The encryption uses an AES-GCM algorythm and it's performed by APIs on [Apiroom](http://apiroom.net/). 

# How it works

 - Access the bot [here](https://web.telegram.org/#/im?p=@zenroom_bot) or by typing ***@zenroom_bot*** inside telegram
 - Encrypt your messages using the command ***/encrypt***
 - Decrypt using the command ***/decrypt***

# Dependency and preparation


 - In the script, Replace **TOKEN** with your telegram token 
 - **sudo pip3 install python-telegram-bot**
 - **sudo pip3 install requests**
 - Run it by launching **python3 zenroombot.py**
 
# The script

The source code here: 
  
```
#!/usr/bin/env python
# -*- coding: utf-8 -*-

import base64
import json
import requests
import logging

from telegram.ext import (Updater, CommandHandler, Filters, MessageHandler,
                          ConversationHandler)

# The two API endpoints that perform encryption and decryption
# using https://apiroom.net 
TOKENENCRYPT_ENDPOINT = "https://apiroom.net/api/danyspin97/Encrypt-message"
DECRYPT_ENDPOINT = "https://apiroom.net/api/danyspin97/Decrypt-Message"

(
    ENCRYPT_WAIT_PASSWORD,
    ENCRYPT_WAIT_MESSAGE,
    DECRYPT_WAIT_PASSWORD,
    DECRYPT_WAIT_MESSAGE
) = range(4)

# Store user password while waiting for cleartext message/ciphertext
passwords = {}


def encrypt_start(update, context):
    update.message.reply_text('Send me the password')

    return ENCRYPT_WAIT_PASSWORD


def encrypt_wait_password(update, context):
    user = update.message.from_user
    passwords[user] = update.message.text
    update.message.reply_text('Send me the message to encrypt:')

    return ENCRYPT_WAIT_MESSAGE


# The structure of the secret message depends on the AES protocol
# it must include a "message" and a "header"
def encrypt_wait_message(update, context):
    user = update.message.from_user
    payload = {
        "data": {
            "header": "my secret header",
            "message": update.message.text,
            "password": passwords[user]
        },
        "keys": {}
    }
    # Delete the password stored
    del passwords[user]

    r = requests.post(ENCRYPT_ENDPOINT, json=payload)
    if not r or r.status_code != 200:
        update.message.reply_text("There has been an error while encrypting"
                                  " the message. Please retry")

    ciphertext = base64.b64encode(r.text.encode())
    update.message.reply_text(ciphertext.decode())

    return ConversationHandler.END


def decrypt_start(update, context):
    update.message.reply_text('Send me the password')

    return DECRYPT_WAIT_PASSWORD


def decrypt_wait_password(update, context):
    user = update.message.from_user
    passwords[user] = update.message.text
    update.message.reply_text('Send me the message to decrypt:')

    return DECRYPT_WAIT_MESSAGE


def decrypt_wait_message(update, context):
    user = update.message.from_user
    secret_message = json.loads(base64.b64decode(update.message.text.encode()).decode())
    payload = {
        "data": secret_message,
        "keys": {
            "password": passwords[user]
        }
    }
    # Delete the password stored
    del passwords[user]

    r = requests.post(DECRYPT_ENDPOINT, json=payload)
    if not r or r.status_code != 200:
        update.message.reply_text("There has been an error while decrypting"
                                  " the message. Please retry")

    message = json.loads(r.text)
    update.message.reply_text(message["textDecrypted"])

    return ConversationHandler.END


def main():
    # Create the Updater and pass it your bot's token.
    updater = Updater("TOKEN", use_context=True)

    # Get the dispatcher to register handlers
    dp = updater.dispatcher

    encrypt_handler = ConversationHandler(
        entry_points=[CommandHandler('encrypt', encrypt_start)],
        states={
            ENCRYPT_WAIT_PASSWORD: [
                    MessageHandler(Filters.text, encrypt_wait_password)],
            ENCRYPT_WAIT_MESSAGE: [
                    MessageHandler(Filters.text, encrypt_wait_message)],
        },
        fallbacks=[MessageHandler(Filters.text, None)]
    )
    dp.add_handler(encrypt_handler)

    decrypt_handler = ConversationHandler(
        entry_points=[CommandHandler('decrypt', decrypt_start)],
        states={
            DECRYPT_WAIT_PASSWORD: [
                    MessageHandler(Filters.text, decrypt_wait_password)],
            DECRYPT_WAIT_MESSAGE: [
                    MessageHandler(Filters.text, decrypt_wait_message)],
        },
        fallbacks=[MessageHandler(Filters.text, None)]
    )
    dp.add_handler(decrypt_handler)

    # Start the Bot
    updater.start_polling()

    # Run the bot until you press Ctrl-C
    updater.idle()


if __name__ == '__main__':
    main()
```
