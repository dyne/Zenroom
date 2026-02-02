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
  "dictionary_dilithium_signature": "uE9vaqctC1AxiGNjyKv18D8+5kRJaNuElcAp4vNQNeqAytygCcL95x2u1/WtZKbBJDwD1yOvpjOnL2020X/YHarhnWhnOWmklRmaUSjCntzv0Yho1Mc9lgookCmBnBgnhjcXdbKSrSehJ7TmbJ18sJaw2k9dgRGCEuMXln24sLYlSg11Auqoybu0UFrDCwsAve/xl7h7W+Ns7HdXXlPTC+Lbd3qHEsIAGT0kydxXyPOY3lBLRww1h9Y7/rjGdzYVdiHhq1Q+/X8h0pe82Rs992MZZ6vOlsHHG77BtMmwWi+hU65wpfBVdcVDgKBoRJuyWqg/FWIUYMDf3kY9CzhN+gCMEqxGGvwjPUegq3YrPX7IxLElVBnkkcyEVV8y0nOwGx3L4Q/FY2MRXKJUmPODLUdVC/Ws3DzgQEV8zvlqn3u0J/lbFFo5JqI13rBtAnL4VUxsS8e5RWSqyYVGI3b3IV8KSIkle+hrnKw2YLGVZxe7AckYUJcE5aJoMcjxNLcqWTXaGkXnR3lSjz94sKC/hGKMj4847AgyF8ciW/ml4JM7dvEvlj+ReLBsa/fl6B0R0zIFmfqHZ4YLMFOlI2poweUIOTQuX/FGdZKt2Zo7CjtRIOZadHqbmkOvuFQ3a/vI3axNra2Nl56BqcYXNKTY7DFV+6Q6LLThZZUUXh9etE/WQDwRfHnaFKaFRMrW0bIv9MoqXm7naq1ZAIFE6AygPkfgODS513XhaatFM01w6vfjURW6TiRLMZAddUrTkBGEsn57yzHACAVlPaXllYDp+UCwnWVSyd+KKO/GEBgMGjGdGrOVfoxGAED2aN1B8Wf9LXpJjQzRWOqkPVV5lE9QGANRC3He1IMEgf5b/5bm9T6mVECfO/ff1b0f72tOfrk+b3+mpqpK4wgeKI5nE7d9uGg9oVJL9w62+qjxZ/EBw/HZE5hkvdVLN590HpUAt6yjICzI1ObGX0tlY/UEH+MuvGMyk0t0qaFEmvIJo+WcBAljUzzQDrlbLXdJbVJPZP5XRVDHUKGK2bHd45huEOwfQYcK0URzFFc0wnJUN/hjmvYBHHkJ4lvGaS0pi5uOzRYR896kAz+iLbRSZ0Mo5GWoHagCw+AshFcBycKSPESuWnSWMVwcbBJejK3CwzlA1M23UfJQwaf7FU4t1XEvbGFJ7fRXSQJ717UxAmNYQfnVuRgEKzILWpE0v1uswH9HjeUhW5GPntxIoHd0X/pZWLwQkmQW1xg8Q6n7lPxuAJf8TQdScqsLa5bqq5LluCpXORfc1XSErP7934crtIHDrxcnOwPQtwpGSNzMedgc+r4Wfsq5XDmpyI50cjPcYedcImXim/cHWYcPlZvKQtwKTd/gM0fMOCsNOsCQi36L6mTLwnDC3MNVWg8EQLSzTuDSPbhIRlfCdUWoPXFa8o0mWI/uFBUn8pZUwTs61mkqmOSGVEvU82HJw9LrNjbwjrzZ/iLohqD0MbLrnnmJe8+EUpdgV0H8IPm0K1CVNr7urJXtuZvl5VlHwyTlkIEfsv5GHqQxkNhO7wFWcY2U7KS4ElE5XmmMSFN3WJdbkZNC1SL+TzZllLbjRG154z6z3SPcsJsiEIoNzi2k5DHliJOg9wI9b5vkNdVhtzQUHExlXUYvyZsJuIrDef0w7botK7e/di7AeAkUC8ZlHISFyeyk5fV7TyzrYr2vr2qUo7PaP35Em1tufKzf42pe1ye46KFYoe7BFzHoDcDuIAzkkJPXuGR2e4+8oyJH1JpRtn7pbvwqp1rYM7B8yV40fYBUHv73F4e4zOdEz7r5BFqMHNBDXWH3D87lT92tFNVmeblFYUKxgbatS1SBVZQRYImEZa/q7POM7asAPHE8NwEUcoxbHdBy6Tq9SBdFNbv7mXIfnViP1JtER+4nwzlLc+CWMGgDTfmuUltNIXYYum0Sw9rTghijJIV+orADc/cqrAolnjhoG/20Q9LpAB5VDJFZ7N3U+OwGzp37QD/MxZ9Zxqy5V8PBvvxZ6F6ZatE25e24sPfSqvQZK5Jg45X4CVlYNJ/UilPYWNZUx/0WXc3vMcgy1MPNObVa2kDsG2AXBUnUSljIrpjQDHKamjDar3MODTO7Q/R4Jh7APOEOQ9X+E3AS3y0Y2hWNWE+xMRqPeGhMBiqRTO1ccLo22WzgGsla1os/1I+p5em/81wj16+O2mHUNUNl/nPLmh6BAgFhYrKMGbf7P/AsTl41869+f+QEFWMog5t4e6XjX+HL22tvtDIO20srHeP9E/3zZYoR1Dn3ZmVx4fotrcvLXnRJ8wo3Syq7FtVZ5lKlRUG68uBhY1dRV0SRtmuhf/+ZE736DfgtHfsu+KvDFY793hVi6xaIBObodhBCBG8vFpI332Gl0UIGL4dcgPAerib4ULzrDxH54SV6nXm6K/FiamZ7s1Kiul8D6ES/OKgSj0TgEnsx7kFOuKRtSdceKAoI8TTfHN2bb4hfCsAV+PnD4QNt2NduPf1+r1lKD6RyGjToWtr1kaivno1wORiqZ7BWaEH4HDZ9EHnHjcKsxBaB6Fc70n0sLcBgtgdNJ5QAHM/ojud4tU2XZQfRXV0/OewtJPERUzWnd+Ffwttr0CZZm1RwP2YfxCgrGI6X9bp8uHo1lYoXMCFKrM+DZuGBYIRj34vWIbO2j8soORZmFlpiPVbpqpYP20Tgf6x58LonAJUfKlt+ERlpwj4nC3lMT7WWSwlYLzg02GmA8/p9pMg3kjrjKIqSD5t4FlwFGiuO/dl7rxuZyQcy4Sy7OGXqwJOm0tXVP9JEcXi4ElJk50HqVhLSQrMZZrhOYMQd3IIu04un5qbqIDwLU6m60OzaM6e4t7dZQWRclBAry3sAanuWuxD9/7o9ve2sYhXIZHMrnqsbXYTHx5ul85mA4eJ2qUskSXgjBWqUiI4UW/vRdE17B4nebjbIZFYgaguGHDvebwnlDrYtdV1/kEzrY6v8adzlnNSDNIRUcHNjSwGD6VBSp3rpcmSKdv7GKMJu4PnvLHwCl+QL5V1CCEDW3UvBM24Gt7xf2+FaW7EYhwuxQfSAXJyUMQpLjL/YVf95mXI1ArPve93II42lYw47EKqvu9DQ3ICu3DbYaJOYDDYGEB4pMm54k6e5wdDX2+vtAiktRU1ja212jbLQ5QIDDQ8aHiUuM01OXm9zgImdn6uzzNTa3OIHDR0hOT51fIGgrK6vv87i+gAAAAAAAAAAABAdNkc=",
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
{"Alice":{"keyring":{"mldsa44":"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"}}}
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
{"keyring":{"mlkem512":"TPJJ2nWjq1TPYkxCXYq1UIJxNFNNENyfnnN9/cLB+YwL6BOo/PgU1FknUKaAjjxwCeolCOWqIZMvN1tsNYC4vpqov0YQzZQijlIB1XIvZtEREll2YMNGGxQlhNAdTfYV2aKn/JiLq6HOiVWBIqPM9MWVaFBI4skDCYmM2tYjEaRfzzhRg5vEalaElxKUCRRSD6nIchcjymquSnZ4PgQr84c/+om8IcGS3vMnCRjBuawF+tR2FludVWFFpCQ0fAVotnsoSUIYugly8SzJR4UA+DN7f9S+CDjCzhd2xTh/twRhCfdS8ZwBntkTRxQZD5Y0XolooSQ1xGQXX4sPDnS67Mh9tjxwUPx4Awg632qd2NF+aDjDDnEl39TOi+qIv3g0bFw+/gEyfQBkCMskpboISMlvJFa6oIFBVuW2LWOK/BNRmubNKdBQ+5QdbUKxu5IGWslIKRxGUatqMZk1uENEPZFP1RU6vXgQNAaB0IYo33hNNIZHZQuwtgR7pqoqGVjD3nJWMSAEqvMpkTEhBtMn8OCY0HtpvcAWsKEFo0oeO7NjGys9p3mGg8tocKEjLyyejBafrHaH2mau2hB6wHOu//qANywNCuI3bbpMAuPKahu8R2LBnPgDgRQO3lFtp3s1OuyM3uoxW8djMlt+3zIf5adAPKQrOLOIJZcV5wRni3FbLMkVGHFxOfIOtGG+j0Vm0hWCFRXH8JqZs6F7pxcYveNOcmB8qQgvVWtITLBIDfukGtFmKvViRju1R6FgMZG+xFhjAJ3JEXh6bYkh7LZ0eIqhraAxCywNslVuq8K3ugSmAxANp+KYnFi5+icg3KGOPRO23lfNrntvfQGcUMBi6/h/uLmOwDSwSgQjFFJiVsWY5kxPf0FE14s5M9w5nSVSKlYZNkDP/oVQLpo/XunDnQWR+QZODTgm+3VZvcJ6FUWGNtEmDRoTAQaFhDWZB8xMcnszClGoHDaCB/FthfNUFIF7eytxiVaETnCEYrxPQ6RKrxC3uKGZq9p+izbOIglgqLKnPIEJT3RnJUwc+IF87VJSixGBLgkg1bRP1mOloauRqKNRPksK2tkjJKhzSCqM/1zMinZgVVNR3KmrtxWs2UkNFXtUdPwp7mO5yBYSDIRdNjRojmOPSUu78xzGm1a6TLBcWjtjCEcjw/sZ5Vcv4sUNIntAFNnMintEzyPHNfWZeFd8fuAXQHpfxLOG8FVlyxFyZSvG55wXhFS+i/cqeuJAzvYEoZgctAMHzmp1pFsWEeG+h0ejYtVQ06OT/DGcyxMJ64S70FIgzwEWWvAHoiJ7FrNor+SpumHCLIZZ8uZCpULIeII8O9ElxOQ1PFeMrnuRbWIdRjYkpIiKJ6Fe2Sq13aXDWJA2eEAYb3lILHmulQGUcRN+oYhjqAKcLIwsdaSP7sOkHVoqeAEnJzC9IMm95VyN9zpn5xyPQ2tL03DBrMBghStE3xMtAHhyZOKbg+LJ91R52tkOL+yzBYo2W/Sfg+B+e8eEstwE0bET6qwgXReJIAg19XIMmeW5U5Vq3LLMDvE6kuaH5nRU8IaHQqM0FYBGyVPGlSV45kxz4lsjfxKPDdCwFqRgyOZOTuKNvGxB7/EBuzMINOESUegliguLvNw12KWuJTGa8Xk1nOI5TYAe5UCUJ4XFK6AhzDSV0rVKF4FqImgaFTgy/ChF0MvH/6aUw3bCEAeL/WKp2nJIVnDL17o0q+fG/RReKnU/ZXZkPFzFXxdbUxBrrUueB4l+JlNHH0CoM7Y07tMzUBQISQY33Sq7KEPDmuNnVUB9u/gRhaGoEuK7ObmAqta7wvSC/8i6yuwpzUW/z7YjtVcSaIqTRhAAIlHDjmls8zFZ43AxQGJgY9vCeyVv3LvMn6SF5PCHFXOQcVjIqcorkrKc4CtZZ/ZLhgYu6Jl0qLM3E+GIJMikwpdTxHrHf5q51HvDIzG3JiRpzJNmQzQdflHBx2OnB8QwDpctVxZD3vwwCcVQy8kxKfltdkqfwUVjZCQq00mcYlIs/ft6qcQvsmOz7rBzkHeOfCa2doPOhYBrVUD0hz9Yq/tysjwHDU7PuIlAu6kSN3YvDOm7szuZ8G5C9UCiCku08ArLo+Q30zlkhbpvZvJwXtPgLkq8OWPa0FcieO2h+vocrBbrYQGST/i8hcZmbOi+ekbtD/iZQmw7"}}
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

![SignatureBenchmark](../_media/images/qp_benchmark_signature.png)

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
![VerificationBenchmark](../_media/images/qp_benchmark_verification.png)

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
'' from ''
'' in ''
'' in path ''
'' is valid
'' named ''
'' named '' in ''
'' named by ''
'' named by '' in ''
'' part of '' after string prefix ''
'' part of '' before string suffix ''
'' public key from ''
am ''
my ''
my '' is valid
my '' named ''
my '' named by ''
my name is in '' named ''
my name is in '' named '' in ''
nothing
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
append '' to ''
append string '' to ''
compact ascii strings in ''
copy '' as '' to ''
copy '' from '' to ''
copy '' to ''
copy contents of '' in ''
copy contents of '' named '' in ''
create ''
create '' cast of strings in ''
create '' named ''
create '' string of ''
create count of char '' found in ''
create float '' cast of integer in ''
create json escaped string of ''
create json unescaped object of ''
create number from ''
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
rename '' to ''
rename '' to named by ''
rename object named by '' to ''
rename object named by '' to named by ''
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
create HMAC of '' with key ''
create hash of ''
create hash of '' using ''
create hash to point '' of ''
create hashes of each object in ''
create key derivation of ''
create key derivation of '' with '' rounds
create key derivation of '' with '' rounds with password ''
create key derivation of '' with password ''
create key derivations of each object in ''
create multihash of ''
create multihash of '' using ''
```
- math functions

```
create result of ''
create result of '' % ''
create result of '' * ''
create result of '' * '' in ''
create result of '' + ''
create result of '' - ''
create result of '' / ''
create result of '' / '' in ''
create result of '' in '' % ''
create result of '' in '' % '' in ''
create result of '' in '' * ''
create result of '' in '' * '' in ''
create result of '' in '' + ''
create result of '' in '' + '' in ''
create result of '' in '' - ''
create result of '' in '' - '' in ''
create result of '' in '' / ''
create result of '' in '' / '' in ''
create result of '' inverted sign
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
create random array with '' elements
create random array with '' elements each of '' bits
create random array with '' elements each of '' bytes
create random array with '' elements from ''
create random array with '' integers
create random array with '' integers modulo ''
create random array with '' numbers
create random array with '' numbers modulo ''
create random dictionary with '' elements from ''
create random dictionary with '' random objects from ''
create random object of '' bits
create random object of '' bytes
create random of '' bits
create random of '' bytes
create random pick from ''
pick random object in ''
randomize '' array
seed random with ''
```
- table functions

```
copy '' as '' in ''
copy '' from '' in ''
copy '' in ''
copy '' to '' in ''
copy named by '' in ''
create copy of last element from ''
create size of ''
enter '' with pointer
move '' as '' in ''
move '' from '' in ''
move '' in ''
move '' to '' in ''
move named by '' in ''
pickup a '' from path ''
pickup from path ''
remove '' from ''
set pointer to ''
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
verify '' ends with ''
verify '' has prefix ''
verify '' has suffix ''
verify '' is a email
verify '' is equal to ''
verify '' is equal to '' in ''
verify '' is not equal to ''
verify '' is not equal to '' in ''
verify '' starts with ''
verify elements in '' are equal
verify elements in '' are not equal
verify number '' is less or equal than ''
verify number '' is less than ''
verify number '' is more or equal than ''
verify number '' is more than ''
verify size of '' is less or equal than ''
verify size of '' is less than ''
verify size of '' is more or equal than ''
verify size of '' is more than ''
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
verify '' has a bbs shake signature in '' by ''
verify '' has a bbs signature in '' by ''
verify bbs proof
verify bbs proof with public key '' presentation header '' disclosed messages '' and disclosed indexes ''
verify bbs shake proof
verify bbs shake proof with public key '' presentation header '' disclosed messages '' and disclosed indexes ''
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
create credential signature
create credentials
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
encrypt secret message '' with ''
encrypt secret message of '' for ''
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
verify '' has a ethereum signature in '' by ''
verify ethereum address signature pair array '' of ''
verify ethereum address string '' is valid
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
create credential signature
create credentials
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
create '' public key from did document ''
create json web token of '' using ''
create jwk of ecdh public key
create jwk of ecdh public key ''
create jwk of ecdh public key with private key
create jwk of es256 public key
create jwk of es256 public key ''
create jwk of es256 public key with private key
create jwk of es256k public key
create jwk of es256k public key ''
create jwk of es256k public key with private key
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
create jws header for es256 signature
create jws header for es256 signature with public key
create jws header for es256k signature
create jws header for es256k signature with public key
create jws header for p256 signature
create jws header for p256 signature with public key
create jws header for secp256k1 signature
create jws header for secp256k1 signature with public key
create jws header for secp256r1 signature
create jws header for secp256r1 signature with public key
create jws signature of ''
create jws signature of header '' and payload ''
create jws signature using ecdh signature in ''
create serviceEndpoint of ''
create verificationMethod of ''
get verification method in ''
set verification method in '' to ''
sign verifiable credential named ''
verify '' has a jws signature in ''
verify did document named ''
verify did document named '' is signed by ''
verify json web token in '' using ''
verify jws signature in ''
verify jws signature of ''
verify verifiable credential named ''
```

# *Foreach*

The foreach statements can be used directly without adding any scenario.

```
'' in ''
'' in sequence from '' to '' with step ''
break foreach
exit foreach
value prefix '' across arrays ''
value prefix '' across arrays '' and ''
value prefix '' at same position in arrays ''
value prefix '' at same position in arrays '' and ''
```

# *If*

The subset of the *When* statements that can be used with the *If* to create a conditional branch are:

```
verify '' contains a list of emails
verify '' ends with ''
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
verify '' starts with ''
verify bbs proof
verify bbs proof with public key '' presentation header '' disclosed messages '' and disclosed indexes ''
verify bbs shake proof
verify bbs shake proof with public key '' presentation header '' disclosed messages '' and disclosed indexes ''
verify credential proof
verify credential proof
verify did document named ''
verify did document named ''
verify did document named '' is signed by ''
verify did document named '' is signed by ''
verify disclosures '' are found in signed selective disclosure ''
verify elements in '' are equal
verify elements in '' are not equal
verify ethereum address signature pair array '' of ''
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
print '' from ''
print '' from '' as ''
print '' from '' as '' in ''
print data
print data as ''
print data from ''
print data from '' as ''
print keyring
print my ''
print my '' as ''
print my '' from ''
print my '' from '' as ''
print my data
print my data as ''
print my data from ''
print my data from '' as ''
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

Copyright (C) 2018-2026 by [Dyne.org](https://www.dyne.org) foundation, Amsterdam

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
      Copyright (c) 2018-2026 Dyne.org foundation, Amsterdam

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
