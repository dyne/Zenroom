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



Then press the *PLAY‚ñ∂Ô∏è* button to execute the script, the result should look like this:

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

If you are a mobile app developer or a tech-savvy person in general, someone that can read and experiment with a shell script or javascript or someone curious enough to know more how applied cryptography works, then read on and you‚Äôll be surprised how easy this is.

![Processing and storing of observed ‚ÄãEphemeral IDs (artwork by Wouter Lueks)](https://github.com/DP-3T/documents/raw/master/graphics/decentralized_contact_tracing/whitepaper_figureAA_processing_storing_ephIDs.png)

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
{"array_dilithium_signature":"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","dictionary_dilithium_signature":"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","message":"Dear Bob, this message was written by Alice and signed with Dilithium!","message_array":["Hello World! This is my string array, element [0]","Hello World! This is my string array, element [1]","Hello World! This is my string array, element [2]"],"message_dict":{"message":"Hello Bob!","receiver":"Bob","sender":"Alice"},"string_dilithium_signature":"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"}
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
{"message":"This_is_my_authenticated_message.","mldsa44_public_key":"xLYglIaoYd7jwWeg6kd2v2gsOA7YjVJbFI/3PoeXDTKPUAoG5ZEBv39QR7S7TMUDdO/bdk/WeUCp1fwC6gGarzCZYRf8o94gSNJqmpZMkBhSaN/9OajKuFx5o2Rj+MwPzm/zJr/Qzlseb2B6UkSavaQ+xjKUkedzsEWBw1qKGj5BXJd967jUOR2/Dd9h5qqeib5ds1BHUXKSJ6XLBGQe0Ool8rt2fur1+KaZJ/QwaTjX3kIxmUq79QJKqKAoZkfQI41Hiz3MqKjROhEUEuQ1rAVegnWePz8+zJCJ+XIVbknKAiBcHQHqv0arNfAqVfCwbKcBZCj35rBeIacR3zunitxqG317kI4j2ds3u9SolIWY/s6PbMpbG/le3zxRe8IpwNwiPcH4eDjGaeOtcO2q+zEQ9IjR3+Y/LjpPgz273g5eEh/mpS8lNG4XPPkicBcgwL/CivTnvnzGPwr01UHwBvyNi6Nae9B5kaVpSjBVV3VYaz0PhxOkLqFrClsCMqKu4ctudBsQpC/NWpP0sc3FPK63bT6WEXTqLgoK4UknM7oeB6LUjcK34f0bQZpzkY4nhoRFcb3emASotgO3zh6MLs3dmMgV3tL9WRioO7IQaYjdaMVVAsQKSYqF2kxqAzhvLdfU7N62ZMBwACImwN+il3fheO2V3GhxDAwAdhJodHpwr4MmbBWrLKa0aN3oyu+UZaQWLOb+IxCeY8BhYuxXe3Z3DkR12z+j0G+DI68scmugONM4VVhXsy9XYrgSsPNbGpGQ8kjmeu+U1oP3DhbW3rq9Gbhh7q6bN/8QOwWd8fydILzkfnziM+2am2Qstoy5Ar9Ope71YZXRZAISuBZMvSfIknA7K1W3VW5lqgalUBnu+eJxkmWGVrGBdqlG9sA2AdLJq43chsoJyo5sc6U34oS1qHqdgonQniDoltoePpSG8XjULw/SvWC4yVmxPgc2nFOBiKVDz7NqFPTumZqCf8BflAPHiHcWOiqaJNEPmNOf4g6znTZTW0Ynra/kFfh3ZKDKhogTdz1sHFt/fa+SIwesP0kZNFbcSaGW29TIAXG8sqNc1GAq6/IaOOgoAeqK+mDSZtsNEizjhOUBBdhr5Sm+/kC3ugi2JXWjSYKsSJ9QdDzP+kKrslXOMbxGelgHkfOuWiynpxdpfdjQZJE1+09v63PqcEbTNMAqSbtCE8QybUY9YY7IZzY/iev04Fo0pq1HkrnWFQxw7QuHvBdl2q1ojNDoWU3L6P6v0gLn63BHkpWgs1OvEGurHqRXIZIumUo8VFRqPu9Pt4aLtJgUBW80/2tKd4nrHMvwE3nWjhpjsCzYb+N7LBzxVgdqMo9nt1fk4xzhM0WL0T4fxbTTMnSfHpWLdgkgNT0uBK9bOKmkemU/37SJph1qqyj1m+PUNn2tnsF95lhez6583Ldz4QN9BVAYk0zei7ibEbZ7dt1qJTNZ3RH4qOzkB93V/oqv5hjg+y4sUKj9jM8c7iyGwARU2dyfoFS+7HloCQlXF9czBmTzN0wgEnHVotMcDJvPMpXislTz37fQ96ZFUBgJ0uGNtIEE4SCls/n+7caTAlY3Y5er4w77Ddy6ANCGCeSO5pFVWkZQpDaORG+JRbs++H3CbH+r1uAeVmTIo7qWwIpgHuOtzvWK20hQKuzSYw9WwRHv2djhUpcbjUBaaNKncZZ/MH1vABhlRvdeHqWkqFIqOr8ixcRRtPg9XhiMbY3AdxiIR7McugkVbslzGogoFA==","mldsa44_signature":"Jq2RfTVchl5Tt1ETJvQiio8vyF1o2oR4ddbRM3sPIKVamZVDnRh5yW50qZGrIb8/cWA3w58mwrMA/HN2195fIzuAXw3kDq+BPu0wGoQ6vH4h10bgZW0a7WCEEF8pPzQP6Ejxw2Y9L+KsuFougtoSIZdKviEMpMbY67DD7M56kxDM+jzi2KomLUt/YVPoJtC8K+QthcctRjOGyn2DvVEJwvLiQpRLCSC2miuFcefOCM3v+K+GHuFN8BWYQa45ddMzhfSxPMminoqb7fFkf1Fd2gGF0ooODSiyuybwJNv+5iJeVJJxh5Dv4tP2hCvkpFIs35kHsbF1XAvUXwHLbKvWUFR2/PI5xxQOpcqIJZ2GIgQbgoL5NIs2exuMlsuhnAjLKFDL2VLutd3Oe49edK5S/ik6vfDLeylf1ZHmOCvp1I1x9UXnLcOfohHy0F4khDTnk5qDdsCLLjFboHIaR7q+S9/NmPnkKEx0haE3KdM+15AgHEem7ne2krvt0ze/zpt0v49o6Iq8xUa6usALUb6hARJqGivxA7cHitXqGALts3oWJMD05Q+G7MlhohCjzOYrHTA0NLNB3rvdY3Va95AIdVw2t1Dyn5s5sYCUUfmGJKsQ1EY1AkEq4y68nrp8qxyY4E+SZKNRPnZ4p3CoWo8lMIAsvmb5MwCSS6t2IZdmTgalwC1/u8WDS1odly4Y9HXoS+Shj6sTICc9Xr10GnqTdq5DcN9cPssEkoLwC7UePGQ05tcLyhkd4PetA2HUGR9x6kLjb5qpa6xsARXlFKCkDCHtBXnWzcSzbvVgdxFVFgc3t7TeP0H2eUZq0CE/NKhm+tAFfC/rWMnf7L7w4bj3FLzpRpz/yY6nGiGnuNg+9dFbAy4RCuhy8kcoWYH06wKwB79UkL02GYgXD6Jox94RbK9rZeLvsLbzg6By1wGSS5uCXxySKYeMZ7bmLI89ii5YN3tnINrQah47vWuqaqEckpGcPy3mmWXotvOrOYBkFEb5SgVd3Yy4n2/tqwNzy8Mme9YA0uVdUziglQCF7oksEvPoud9ffqpN1CNjsXa4cC1Tmd2OlXDoHSKXLrrGUXGERXlJutaO+C4GR1+Ijw4EZUR0oeYnPF7Iura59A34vm9jmFnfdo8JhnKGlejG4DBb4c90GfUTopYO2vf+o5qaSTGiSRyVRNpIH3L0cu7Z1/7bm8s/TFoGjCuL/L5S8W7cFU5xBjfxM3OwRiWXRh/0oUjrbfBrzbbv3ogLFTW7/AisBWOyCOPDIn8pEogAVKEO3SaLYd1n+BGs6IpE9WQlIKwLhPRPD6mzUfHOyRzKuzo0vvi7qNqZBdd53EkaWU4YP+3KJg6KcaytgJDwBD1PiJ9hD9D5f4zuiM9mXGNI3GigImWvGJG4t8NN0WfhytXGSvcxyuxWDWuC+adP3DwGwpWFkpfshcqM2lhc/OeOipE6mWlTZZEfuyTaPLEfHGbMTumAA1/gbGFXzKLtOKYPqlp3PFpiWNJAbJiWj4qfkbfOJYJC/pZCYIOZlCmthxA/POlWjxi8IKmtIPiVgTldRVYjO/U5SCyb5x/I8Cb+zDamjgKV8/g12V7c1cpTm0GGLa7M9UQvm+DtImoVDJOgnWWbX0Xh1YXKs6y556Hjza/FHp8mTctqketow0B2pN9Om9Aq7Im6GaLlpu6uO3NX3pjSb+Th6p8w7Hig+/L3jZX0k9t/ktwM3Tz7PwjgT/lH4onnyDtiy51xERNjTwLBeYhDx3zyR7mosGGmQFkCEkxGAuTq3R3cD/UmcWgJrXxGqNBCrYf0ID3ymf6wR54bteLIdl/fWaqmZ2ZRN/rB9mlm6SjElbHIYObGtvnEvc715Z3UYONU/D4Ao9HjDGDA18yWCNhWwFt8km6N6Ug+CfhF6IFXF006Fe2tWlSahT7KbrQt5KGztqMEadRal+xPMq2c6ysWUQa6GqzQNjuoW5ueV1YclrPgSztXgsxdtlm3ZElf2r/9wbAdCRREgr4DfuJE2sGWHCELYLLAhOr5hpQe7EeLLrPkY2k6+AYgE6/ePMyzWmH4yycWtEpl2MaHDPvt7r4p6YoT9DW1upSAJF2aH22vxpzU8/HR1fjlXzZw2py+oEymFo0rLAhmQ8vGyQevasVHmRaj5FS8wuMo0lzWSEnHg+vIAzXj5+GRyiVozNJExPBcxhL23c/Sp9SB1InW45dnoRNKiP5xJtFoIbbAeFxO498xCzrDsiU4Rh64WTZ1xvN+/JqkPhnj/s6eYDsV8SszjZ49ADPnse5A0mBZJB8oZUaPowdkulBHQbaXoaPPdUKmVZ02VzfYKD/TfSR/9PHF0DIato653gOfXKVHISprc5586erG/B1f4N+ki768GGuXOB4LTl/qGyJWUe/NCpebMjunWMZgPNfFYsllqMwTzk9/21E/Wg7Il2Yek3ymQHO7Mrv1rLvN07OiZg0UwqYjZ/rhZ3saP/E6NzQ/eptHC0SZZG/xIkRgc0UJ8/Uhw/gt2GkrsBaEGc1RXKoSTOIVxg5XvKhleDq+1TniLK3SMWXemR92TAdW+1b1xfumGXptljqumHH2PwkIMe9XFVw5EAI9sbEUrPtdkaOv34IoTNOKAfZ1wYlD7iJEbIQFdtc8yrsjhalrafXIQ28zup0wElpflHBbJ6We8CWvRhZI7Nb3uiNsRmT1Djcwtl4h5uPRuRnJVFOfIK/eImWgdKuHcE7Na5iKWjRSi3c/PTmCd01354joddp4dPFCucj8XTR9UVZ2veMaml3k4ZTK5g1bYfhU44aMJJXgfqdiqZxfP+cHwacmuQcco1dTJHmooJvGvKjXaDOQIAqAviHe+M8NoLZ8f4DiQqXWNyKJPBqHm/YtnvzwfwAEdGW1CXKkpFT2t3AcT+HTKvmQbTIQpBGHsjsiSdrvAn7wsc2V0bq6KKDpRoOSU4Auwe57Kp0HyW+5D9wqgV0uedMO4YHOdky948C6gCFCkO+VtpGB5GxnyaojiqjHHBi3oZhJbjGtRspnZx1v5ulkUn/fUb6Dv9PW2j3KupBB/DdoOLWJ7z1UzdVZ6CNEz9NvrJCHaSI415ODyHQyaMyvpwzsQzZXBr0bkDesXsCWVYkUIeUQEx83XHGCg4TL4ez0AwwdR3+hvtTc8PP4IiZYWV5pd3yJkZSXssLd3uPo8vsDBAwSaIujqMn4+wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA0ZLTg="}
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

Kyber512 is a Post-Quantum Key Encapsulation Mechanism defined over lattices. It is a cryptographic primitive that allows anyone in possession of some party‚Äôs public key to securely transmit a key to that party. It can be divided in three main part:
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

Regarding the *signature* and *verification* algorithms the test was performed on different message lengths: 100, 500, 1000, 2.500, 5.000, 7.500 and 10.000 bytes. The **results are amazing**: the time and memory consumed by the two algorithms are really close to each other. Their are shown in the following tables where time is measured in Œºs (microsecond) and the memory in KiB (Kibibyte).

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
âPNG

   IHDR  @  Ñ   ˘M˝¢   9tEXtSoftware Matplotlib version3.5.2, https://matplotlib.org/*6E   	pHYs  a  a®?ßi  Ù9IDATxúÏ›wxïÖ›ˇÒ˜…N»Ä0¬Hò≤7Ñ÷Zgã"Püßn˝µV≠äVkkkÌ–V—™≠Z[´≠Ä(j›[≤eäVÿ	+ÛúﬂB©®®Å;9yøÆã˘û;Á|í¶Å‹ü‹˜7âD"Hí$Ií$Ií$≈ê∏†Hí$Ií$Ií$’4Ií$Ií$Iís,@$Ií$Ií$IRÃ± ë$Ií$Ií$I1«Dí$Ií$Ií$≈Ií$Ií$Iís,@$Ií$Ií$IRÃ± ë$Ií$Ií$I1«Dí$Ií$Ií$≈Ií$Ií$Iís,@$Ií$Ií$IRÃ± ë$Ií$Ií$I1«Dí$Ií$Ií$≈Ií$Ií$Iís,@$Ií$Ií$IRÃ± ë$Ií$Ií$I1«Dí$Ií$Ií$≈Ií$Ií$Iís,@$Ií$Ií$IRÃ± ë$Ií$Ií$I1«Dí$Ií$Ií$≈Ií$Ií$Iís,@$Ií$Ií$IRÃ± ë$Ií$Ií$I1«Dí$Ií$Ií$≈Ií$Ií$Iís,@$Ií$Ií$IRÃ± ë$Ií$Ií$I1«Dí$Ií$Ií$≈Ií$Ií$Iís,@$Ií$Ií$IRÃ± ë$Ií$Ií$I1«Dí$Ií$Ií$≈Ií$Ií$Iís,@$Ií$Ií$IRÃ± ë$Ií$Ií$I1«Dí$Ií$Ií$≈Ií$Ií$Iís,@$Ií$Ií$IRÃ± ë$Ií$Ií$I1«Dí$Ií$Ií$≈Ií$Ií$Iís,@$Ií$Ií$IRÃ± ë$Ií$Ií$I1«Dí$Ií$Ií$≈Ií$Ií$Iís,@$Ií$Ií$IRÃ± ë$Ií$Ií$I1«Dí$Ií$Ií$≈Ií$Ií$Iís,@$Ií$Ií$IRÃ± ë$Ií$Ií$I1«Dí$Ií$Ií$≈Ií$Ií$Iís,@$Ií$Ií$IRÃ± ë$Ií$Ií$I1«Dí$Ií$Ií$≈Ií$Ií$Iís,@$Ií$Ií$IRÃ± ë$Ií$Ií$I1«Dí$Ií$Ií$≈Ií$Ií$Iís,@$Ií$Ií$IRÃ± ë$Ií$Ií$I1«Dí$Ií$Ií$≈Ií$Ií$Iís,@$Ií$Ií$IRÃ± ë$Ií$Ií$I1«Dí$Ií$Ií$≈Ií$Ií$Iís,@$Ií$Ií$IRÃ± ë$Ií$Ií$I1«Dí$Ií$Ií$≈Ií$Ií$Iís,@$Ií$Ií$IRÃ± ë$Ií$Ií$I1«Dí$Ií$Ií$≈Ií$Ií$Iís,@$Ií$Ií$IRÃ± ë$Ií$Ií$I1«Dí$Ií$Ií$≈Ií$Ií$Iís,@$Ií$Ií$IRÃ± ë$Ií$Ií$I1«Dí$Ií$Ií$≈Ií$Ií$Iís,@$Ií$Ií$IRÃ± ë$Ií$Ií$I1«Dí$Ií$Ií$≈Ií$Ií$Iís,@$Ií$Ií$IRÃ± ë$Ií$Ií$I1«Dí$Ií$Ií$≈Ií$Ií$Iís,@$Ií$Ií$IRÃ± ë$Ií$Ií$I1«Dí$Ií$Ií$≈Ií$Ií$Iís,@$Ií$Ií$IRÃ± ë$Ií$Ií$I1«Dí$Ií$Ií$≈Ií$Ií$Iís,@$Ií$Ií$IRÃ± ë$Ií$Ií$I1«Dí$Ií$Ií$≈Ií$Ií$IísÇ ’V·pò6êëëA(
:é$Ií$IíTßD"vÌ⁄EÀñ-âãÛgÒuÏYÄHüb√Ü‰ÂÂCí$Ií$I™”
…ÕÕ:ÜÍ!ÈSddd —/–ôôôßë$Ií$IíÍñííÚÚÚ™œ≥I«öàÙ)‹ˆ*33”Dí$Ií$I˙íºΩºÇ‚ç◊$Ií$Ií$IRÃ± ë$Ií$Ií$I1«Dí$Ií$Ií$≈wÄH_QUUA«PñòòH|||–1$Ií$Ií§òb"}IëHÑMõ6±sÁŒ†£(4lÿêÊÕõªLí$Ií$I™! “ót†¸h÷¨iiiû∏÷óâDÿªw/õ7o†Eã'í$Ií$IíbÉàÙ%TUUUóç7:éÍ∏‘‘T 6oﬁL≥fÕºñ$Ií$IíT\Ç.}	v~§••úD±‚¿Áí˚d$Ií$Ií§öa"}ﬁˆJ5≈œ%Ií$Ií$©fYÄHí$Ií$Ií§òc"Èòi€∂-˜ﬁ{ÔQ}çã.∫àQ£F’◊ê$Ií$IíT˚π]
PU8¬¨’€Ÿº´îf)lóM|\Ïﬁ
iˆÏŸ4h–†FûÎ„è?¶]ªv|¡ÙÈ”ßz˛ªﬂ˝éH$R#Ø!Ií$Ií$©Ó≤ ëÚ“¢ç‹ˆ‹6óVœZd•pÎ»nú÷£EÄ…éû¶Mõı◊»  :ÍØ!Ií$Ií$©ˆÛXR ^Z¥ë+ûò{H˘∞©∏î+ûòÀKã6µ◊ﬁ≥g\pÈÈÈ¥h—ÇªÔæõN8ÅkØΩàﬁ¶Íóø¸%Áùw4†U´V¸˛˜ø?¢ÁéD"¸¸Á?ßuÎ÷$''”≤eK~ÉT?˛ﬂ∑¿Z∫t)√á'%%Ön›∫Ò⁄kØ
Öò:uÍÁæVªvÌ Ë€∑/°PàN8¯‰-∞N8·Ææ˙jÆΩˆZ5jDNNè<Ú{ˆÏ·‚ã/&##É„é;é_|ÒêÁ_¥hßü~:ÈÈÈ‰‰‰p˛˘Á≥uÎ÷#˙8Hí$Ií$I
ûàTC"ë{À+?˜◊Æ“
n}v1áªI”ÅŸœü]¬Æ“ä#zæ/zªß˛áº˝ˆ€<ÛÃ3ºÚ +ºı÷[Ãù;˜êcÓ∫Î.z˜ÓÕ|¿è~Ù#ÆπÊ^}ı’œ}Ó)S¶pœ=˜√≥b≈
¶NùJœû={lUU£Fç"--ç˜ﬂü?˛Òè¸‰'?9‚˜c÷¨Y ºˆ⁄kl‹∏ëßûzÍSè}¸Ò«i“§	≥fÕ‚Í´ØÊä+Æ`Ãò1:îπsÁr )ßp˛˘Á≥wÔ^ vÓ‹…â'ûHﬂæ})((‡•ó^¢®®à±c«q>Ií$Ií$I¡ÚXRŸWQE∑üΩ¸ïü'l*)•Áœ_9¢„ó¸‚T“íéÏˇ ªwÔÊœ˛3O<Òﬂ¯∆7Äh9êõõ{»q√Ü„G?˙ ù:ub˙ÙÈ‹sœ=ú|Ú…ü˘¸k◊Æ•yÛÊút“I$&&“∫ukxÿc_}ıUV≠Z≈[oΩEÛÊÕ¯ıØ˝πØq¿Å€i5n‹∏˙Ì?MÔﬁΩπÂñ[ ∏˘Êõ˘Õo~Cì&M∏¸ÚÀ¯Ÿœ~∆É>»Ç<x0< }˚ˆÂˆ€oØ~éG}îºº<ñ/_NßNùé(£$Ií$Ií§‡xàTè¨ZµäÚÚrT=ÀŒŒ¶sÁŒá7d»êO¸˘√?¸‹Á3f˚ˆÌ£}˚ˆ\~˘Â<˝Ù”TVVˆÿeÀñëóówHyÒie…W’´WØÍˇéèèßq„∆á\ôíìì¿ÊÕõò?>oæ˘&ÈÈÈ’ø∫tÈD?Üí$Ií$Iíj?Ø ëjHjb<K~qÍÁ7kıv.˙ÀÏœ=Ó±ã0∞]ˆΩnmëóó«≤eÀxÌµ◊xı’W˘˛˜øœ]w›≈€oøMbbb`π˛˚µC°–!≥P(@8¢W å9íﬂ˛ˆ∑üxÆ-bsAΩ$Ií$Iík,@§
ÖéËVT#:6•EV
õäKª$4œJaD«¶ƒ«Öj4cáHLL‰˝˜ﬂßuÎ÷ Ïÿ±ÉÂÀóÛµØ}≠˙∏˜ﬁ{Ôê∑{ÔΩ˜Ë⁄µÎΩFjj*#Géd‰»ë\yÂïtÈ“ÖÖ“Ø_øCéÎ‹π3ÖÖÖU_Å1{ˆÁC$%%—]"5≠_ø~Lô2Ö∂m€íê‡óIIí$Ií$©.ÚX“1‚÷ë›ÄhŸÒü¸˘÷ë›jº¸ HOOÁ“K/Âá?¸!oºÒã-‚¢ã.".Ó–/”ßOÁŒ;Ôd˘ÚÂ¸˛˜øgÚ‰…\sÕ5ü˚¸è=ˆ˛ÛüY¥h}ÙO<Ò©©©¥i”Ê«û|Ú…tË–Å/ºê0}˙ÙÍ=Æ»¯,Õö5#55µzAyqqÒ~>ﬂïW^…ˆÌ€9ÔºÛò={6´V≠‚Âó_Ê‚ã/>*Öã$Ií$Ií§ög"‡¥-x;˝hûïr»ºyV
~ßßı8z∑Y∫ÎÆª1b#Gé‰§ìNb¯·ÙÔﬂˇêcÆø˛z


Ë€∑/ø˙’Øò0aßû˙˘∑˜jÿ∞!è<Ú√Ü£WØ^ºˆ⁄k<˜‹s4n‹¯«∆««3uÍTvÔﬁÕÄ∏Ï≤À¯…O~@JJ 'éˇo			‹wﬂ}<¸√¥lŸío}Î[G¯¯|-[∂d˙ÙÈTUUq )ß–≥gOÆΩˆZ6l¯â≤Hí$Ií$IRÌäD"áªèTÔïîîêïïEqq1ôôôá<VZZ Í’´i◊Æ›ù¨ˇ4U·≥VogÛÆRöe§0∞]ˆQπÚ„Ûúp¬	ÙÈ”á{ÔΩó∂m€rÌµ◊rÌµ◊Û”ßOg¯·¨\πí:Û◊RM}NIí$Ií$’üu~M:ºπΩ†¯∏C:|ÚÍà˙‚Èßü&==ùé;≤rÂJÆπÊÜVÔ Ií$Ií$I5œ{πH:bˇ˚ﬂIOO?ÏØÓ›ª·Á€µkWı¢Ùã.∫àÃ3œ p˚Ì∑Íkù~˙È5˝ÆIí$Ií$Iä1ﬁK˙«‚XuÕÆ]ª(**:Ïcâââá]v˛emﬂæùÌ€∑ˆ±‘‘TZµjUcØU‘◊œ)Ií$IíÍ´⁄rkÙ£…[`)hﬁK“À»» ##„òºVvv6ŸŸŸ«‰µ$Ií$Iíé•óm‰∂Áñ∞±∏¥z÷"+Ö[Gv„¥-L&≈oÅ%Ií$Ií$I«»Kã6r≈s)? 6ór≈syi—∆ÄíI±«Dí$Ií$IíéÅ™pÑ€û[¬·vò›ˆ‹™¬n-êjÇà$Ií$Ií$≥Voˇƒïˇ)l,.e÷Í√ÔEïÙ≈XÄHí$Ií$I“1∞f˚û#:nÛÆO/I$9Ií$Ií$I: f¨⁄ ˇΩ¥Ïàémñërî”HıÉà§Ø‰¢ã.b‘®Q’>·Ñ∏ˆ⁄kè kµm€ñ{ÔΩ˜®<˜ˇ˝˛Hí$Ií$}•U‹ˆ‹b˛Áë˜Ÿ∫ßú¯–ßZd•0∞]ˆ1À'≈≤Ñ†HıZ∏
÷ÃÄ›EêûmÜB\|–©j≠Ÿ≥g”†AÉyÆè?˛òvÌ⁄Ò¡–ßOüÍ˘Ô~˜;"çIí$Ií§Øn^·N∆Oö«G[¢∑æ:o`k∂Àf¸ƒy á,C?–ã‹:≤Òqü—íH:b RPñ</›%Œ2[¬iøÖngó´k⁄¥ÈQç¨¨¨£˛í$Ií$)∂UTÖπˇı¸˛≠UTÖ#4ÀHÊ∑Áˆ‚Îùõêö«mœ-9d!zÛ¨nŸç”z¥*∂sºñÑ%œ¬§-? J6FÁKû=j/áπ„é;h◊Æ©©©ÙÓ›õ'ü|≤˙Ò≈ãsÊôgíôôIFF#Få`’™U TUU1~¸x6lH„∆çπÒ∆{µD8Ê∆o$;;õÊÕõÛÛüˇ¸à≤E"~˛Ûü”∫ukíììiŸ≤%?¯¡™ˇÔ[`-]∫î·√áìííB∑n›xÌµ◊ÖBLù:ıs_´]ªv ÙÌ€óP(ƒ	'ú ˛ñ^W_}5◊^{-ç5"''áGyÑ={ˆpÒ≈ìëë¡q««ã/æx»Û/Z¥à”O?ùÙÙtrrr8ˇ¸ÛŸ∫uÎ}$Ií$IR›µºhgˇa:˜Ω±í™pÑëΩ[Ú u«Wó ßıh¡ª7ù»?/ÃÔæ›á^>òwo:—ÚC™a RMâD†|œÁˇ*-Åo‰–ã´ü$˙€K7Eè;íÁ˚Ç∑k∫„é;¯Î_ˇ C=ƒ‚≈ãπÓ∫Î¯Œwæ√€oøÕ˙ıÎ9˛¯„INNÊç7ﬁ`Œú9\r…%TVVp˜›wÛÿcèÒË£èÚÓªÔ≤}˚vû~˙ÈOº∆„è?NÉxˇ˝˜πÛŒ;˘≈/~¡´Øæ˙πŸ¶Lô¬=˜‹√√?Ãä+ò:u*={ˆ<Ï±UUUå5ä¥¥4ﬁˇ}˛¯«?Úìü¸‰à?≥fÕ‡µ◊^c„∆ç<ı‘SüzÏ„è?Nì&Mò5kW_}5W\qc∆åaË–°Ãù;óSN9ÖÛœ?üΩ{˜∞sÁNN<ÒD˙ˆÌKAA/ΩÙEEEå;ˆàÛIí$Ií§∫•*·ëw>‚Ã˚ﬂe—˙¶%rˇy}πˇºæ4LK˙ƒÒÒq!ÜthÃ∑˙¥bHá∆ﬁˆJ:
ºñTS*ˆ¬Ì-k‡â"—+C~ìwdáˇx$Ÿ^å≤≤2nø˝v^{Ì5Ü@˚ˆÌy˜›wy¯·ái€∂-YYY¸Î_ˇ"11ÄNù:Uø˝Ω˜ﬁÀÕ7ﬂÃ9Áú¿C=ƒÀ/ø¸â◊È’´∑ﬁz+ ;v‰Å‡ı◊_Á‰ìO˛Ã|k◊Æ•yÛÊút“I$&&“∫ukxÿc_}ıUV≠Z≈[oΩEÛÊÕ¯ıØ˝πØq¿Å€i5n‹∏˙Ì?MÔﬁΩπÂñ[ ∏˘Êõ˘Õo~Cì&M∏¸ÚÀ¯Ÿœ~∆É>»Ç<x0< }˚ˆÂˆ€oØ~éG}îºº<ñ/_~»«Tí$Ií$’}k∑ÌÂÜ…ÛôıÒv æﬁπ)ø›ãfô)'ìÍ7©Yπr%{˜Ó˝DIP^^Nﬂæ}Ÿπs'#Få®.?˛Sqq17nd–†A’≥ÑÑÚÛÛ?q¨^ΩzÚÁ-Z∞yÛÊœÕ7fÃÓΩ˜^⁄∑oœißù∆7ø˘MFéIB¬'øT-[∂åºººC ãO+Kæ™ˇ|‚„„i‹∏Ò!W¶‰‰‰ TøèÛÁœÁÕ7ﬂ$==˝œµj’*Ií$IíbD$·ü≥
˘’ÛKÿ[^EÉ§xn9≥ﬂêG(‰R–,@§öíòΩ„Û¨ô?˜Ûè˚ﬂ'°Õ–#{›#¥{˜n û˛yZµju»c………\{ÌµG¸\üÈø
îP(D8˛‹∑ÀÀÀcŸ≤eºˆ⁄kº˙Í´|ˇ˚ﬂÁÆªÓ‚Ì∑ﬂ>l)s¨Ó˝˘œŸÅ–xwÔﬁÕ»ë#˘Ìo˚âÁj—¬{yJí$Ií6óîr„îºµl €fs˜ÿﬁ‰e˘πIGóàTSB°#ªUá!≥et·˘a˜ÄÑ¢èw8‚‚k4b∑n›HNNfÌ⁄µ|Ìk_˚ƒ„Ωzı‚Ò«ß¢¢‚'˝≥≤≤h—¢Ôøˇ>«< ïïïÃô3á~˝˙’X∆‘‘TFé…»ë#πÚ +È“•.¸ƒktÓ‹ô¬¬Bäää™Ø¿ò={ˆøNRRÙﬁõUUU5ñ˝Ä~˝˙1e ⁄∂m{ÿ´W$Ií$IR›ˆ‹¸¸ÙôEÏ‹[ARB?<•3óoÁ©ñÒÃút¨≈≈√iøÖI !-Aˆˇ%y⁄ojº¸ »»»‡Ün‡∫ÎÆ#3|¯päããô>}:ôôô\u’U‹ˇ˝|˚€ﬂÊÊõo&++ã˜ﬁ{èÅ“πsgÆπÊ~Ûõﬂ–±cG∫tÈ¬Ñ	ÿπsgçÂ{Ï±«®™™b–†A§••ÒƒOêööJõ6m>qÏ…'üLá∏¬πÛŒ;ŸµkWıûé#πƒ¥Y≥f§¶¶Ú“K/ëõõKJJ
YYY5Ú~\yÂï<Ú»#úwﬁy‹x„çdgg≥rÂJ˛ıØÒß?˝â¯¯öˇﬂVí$Ií$};˜ñÛ”gÛ‹¸Ë]@z¥ d¬ÿ>t …8ô§√â:ÄT/u;∆˛2ˇÎvHô-£Ûngµó˛Â/…O˙SÓ∏„∫vÌ ißù∆Ûœ?OªvÌh‹∏1oºÒªwÔÊk_˚˝˚˜ÁëG©æ‰˙ÎØÁ¸ÛœÁ¬/d»ê!dddpˆŸg◊X∂ÜÚ»#è0lÿ0zıÍ≈kØΩ∆sœ=G„∆ç?ql||<SßNe˜Ó›0ÄÀ.ªåü¸‰' §§|˛Ç±ÑÑÓªÔ>~¯aZ∂l…∑æı≠{?Z∂l…ÙÈ”©™™‚îSN°gœû\{Ìµ4lÿê∏8øÏJí$IíTΩπl3ß‹ÛœÕﬂ@|\à|£#OòÂáTãÖ"ˇΩΩX %%%deeQ\\LffÊ!èïññ≤zıj⁄µkwD'€?U∏*∫dw§ÁDw~Ö+?ÍãÈ”ß3|¯pVÆ\IáÇéÛÖ‘ÿÁî$Ií$I™Q{ *˘’ÛÚœYkhﬂ¥˜åÌCÔºÜ¡´>Î¸öt,x,)HqÒ–nD–)Í¨ßü~öÙÙt:vÏ» ï+πÊök6lXù+?$Ií$IRÌ4kıvÆü<è¬Ì˚ ∏xX[n:≠)â˛ ´Tx/I«Ãﬂˇ˛w“””˚´{˜Ó_¯˘vÌ⁄UΩ(˝¢ã.b¿Ä<ÛÃ3 ‹~˚Ìü˙Zßü~zMøkí$Ií$)ÜîVTq˚2Óè3)‹æèVS˘«ÂÉ∏udwÀ©ÒX“ß8&∑¿™gvÌ⁄EQQ—aKLL<Ï≤Û/k˚ˆÌlﬂæ˝∞è•¶¶“™U´{≠ö‡Áî$Ií$Iµ√¢ı≈åü4èÂEª”?óüéÏFfJb¿…ÍoÅ•†y,I«LFF«f1Xvv6ŸŸŸ«‰µ$Ií$IR›WYÊ¡∑VÒª◊WPé–$=â;ŒÈ≈…›rÇé&ÈK≤ ë$Ií$IíTØ≠⁄≤õÒìÊ3øp' ßuoŒØœÓA„Ù‰`ÉI˙J,@§Ø A1¬œ%Ií$IíéΩp8¬„3?Ê7/.•¨2LFJø¯VwFıiE(
:û§Ø»D˙íííàããc√Ü4m⁄î§§$ˇR‘óâD(//gÀñ-ƒ≈≈ëîît$Ií$IíÍÖı;˜q√§˘Ã¸h #:6·Œs{—"+5‡díjäàÙ%ƒ≈≈—Æ];6n‹»ÜÇé£êññFÎ÷≠âãã:ä$Ií$I1-â‰úu¸‚π%Ï*´$51û≥ﬂ‹∆pïbåàÙ%%%%—∫uk*++©™™
:éÍ∞¯¯x¸Gñ$Ií$IGŸ÷›e‹¸‘B^]R@ø÷π{l⁄5ip2IGÉàÙÑB!ILL:ä$Ií$Ií>√Kã6Ú„ß±}O9âÒ!Æ;πﬂ=æÒq˛@¢´,@$Ií$Ií$≈¨‚}‹ˆÏbû˙`= ]ög0al∫µÃ8ô§£ÕDí$Ií$IRLö∂b7>πÄç≈•ƒÖ‡ª_Î¿µ'u$9!>ËhíéIí$Ií$I1eoy%øyq)ùπÄ6ç”ò0∂7˝€dúL“±d"Ií$Ií$)fÃ]ªÉÎ'Õgı÷= ú?∏7≥iIû
ïÍˇ_/Ií$Ií$©Œ+ØsÔkÀyËÌUÑ#–<3Ö;œÌ≈ÒùöMR@,@$Ií$Ií$’in,a¸§˘|∏±Ä≥˚∂‚Á#ªìïñp2IA≤ ë$Ií$IíT'UÖ#¸ÒùèòÍ2*™"4JK‰ˆ≥{rzœAGìTXÄHí$Ií$I™s>ﬁ∫áÎ'œgŒö ú‘µwú”ã¶…'ìT[XÄHí$Ií$I™3"ëOºøñ€üˇê}U§''≥ë›”?óP(t<Iµàà$Ií$Ií§:aSq)7NY¿;À∑ 0∏}6ˇ7¶7πç“N&©6≤ ë$Ií$IíT´E"ûô∑Åü=≥àí“Jí‚∏È¥.\4¥-qq^ı!È,@$Ií$Ií$’Z€˜îsÀ‘Öº∞p Ωr≥ò0∂«5K8ô§⁄ŒDí$Ií$IR≠Ù˙áE‹4e![wóë‚Í;Ú˝Øw 1>.ËhíÍ Ií$Ií$Iµ Æ“
~ıÔôXP@«fÈL€áûπY'ìTóXÄHí$Ií$I™5fÆ⁄∆ìÁ≥~Á>B!∏lx;Æ?•3)âÒAGìT«XÄHí$Ií$I
\iEwæ¥åGßØ ∑Q*wèÈÕ†ˆçN&©Æ≤ ë$Ií$Ií®Îvr›ƒy¨⁄≤ÄÛÊÒì3∫ëûÏÈKI_û_A$Ií$Ií$¢¢*Ão¨‰Å7WRé–4#ôﬂéÓ…â]rÇé&)XÄHí$Ií$I:ÊVÌb¸§˘,\_¿ΩZ´oı†QÉ§ÄìIä í$Ií$Iíéôp8¬£”WsÁÀÀ(Øìïö»/Gı‡¨ﬁ-Éé&)∆XÄHí$Ií$I:&
∑ÔÂÜ…Ûyıv æ÷©)wû€ãúÃîÄìIäE í$Ií$Iíé™H$¬§ÇB~Ò‹ˆîWëñœOŒË ˇlM(
:û§e"Ií$Ií$È®Ÿº´îMY»K70†m#˛oLo⁄4np2I±ŒDí$Ií$I“QÒ¸Çç‹2u!;ˆVê«ßv‚“·ÌâèÛ™IGüà$Ií$Ií§Uº∑Çü=ªàgÊm †{ÀL&åÌCÁÊ'ìTüXÄHí$Ií$I™1o/ﬂ¬çOŒß®§å¯∏ﬂ?°Wüÿë§Ñ∏†£I™g,@$Ií$Ií$}e{ *π˝Ö˘˚˚khﬂ§wèÌMﬂ÷çN&©æ≤ ë$Ií$IíÙï|ºùÒìÊ≥v˚^ .⁄ñõNÎBjR|¿…$’g í$Ií$Iíæî≤ *&º∫ú?æÛë¥ÃJ·Æ1Ωv\ì†£Iíà$Ií$Ií§/nÒÜb∆Oúœ≤¢] åÓóÀ≠gu#3%1‡díe"Ií$Ií$ÈàUVÖyËÌU¸ÓıTTEh‹ â€œÈ…©›õMía"Ií$Ií$Èà|¥e7„'Õg^·N NÌû√ØœÓIìÙ‰`ÉI“aXÄHí$Ií$I˙L·pÑøΩ∑Ü;^¸ê“ä0…	¸¸¨Óú”Ø°P(ËxítX í$Ií$Ií>’Üù˚¯·ìÛôær √èk¬ùÁˆ¢e√‘ÄìI“g≥ ë$Ií$IíÙ	ëHÑßÊÆÁÁœ-fWi%)âq¸¯õ]˘Œ†6ƒ≈y’á§⁄œDí$Ií$I“!∂Ì.„«O/‰Â≈E Ùm›êª«Ù¶}”ÙÄìI“ë≥ ë$Ií$IíTÌÂ≈õ¯ÒSŸ∂ßúƒ¯◊û‘âÔﬂûÑ¯∏†£I“b"Ií$Ií$âí“
n{v	SÊÆ†sN∆ı¶{À¨ÄìI“óc"Ií$Ií$’s”WnÂáìÁ≥°∏îPæ{|Æ;π#…	ÒAGì§/ÕDí$Ií$I™ßˆïWÒ€óñÚÿåèh”8çª«Ù&ømv∞¡$©XÄHí$Ií$Iı–kwp˝§˘|¥u ˇ;®5?˛fW${ PRl´ô$Ií$IíTèîWÜπÔı¸·≠ïÑ#êìôÃoG˜‚ÑŒÕÇé&I5 Dí$Ií$I™'ñm⁄≈uÁ±dc	 ﬂÍ”í_ú’É¨¥ƒÄìIRÕ≥ ë$Ií$Iíb\U8¬ü¶}ƒ›Ø,ßº*L£¥D~5™'gÙjt4I:j,@$Ií$Ií§∂f€nò<üŸÔ ‡]öq«Ëû4ÀH	8ô$] í$Ií$IRäD"¸c÷Z~˝¸áÏ-Ø¢AR<∑éÏŒò¸\B°P–Ò$È®≥ ë$Ií$IíbÃ¶‚Rnö≤Ä∑óo`Pªl˛oLoÚ≤”N&I«éà$Ií$IíCûùøÅüN]DÒæ
í‚∏Ò‘Œ\2¨qq^ı!©~± ë$Ií$Iíb¿é=Â‹ÚÃ"û_∞Äû≠≤ò0∂7s2N&I¡∞ ë$Ií$IíÍ∏7ñq”îÖlŸUF|\à´O<é+ø~âÒqAGì§¿XÄHí$Ií$Iu‘Ó≤J~ıÔ%¸kv! «5Kg¬ÿﬁÙ ml0I™,@$Ií$Ií§:Ë˝è∂q˝‰˘¨€±èP.÷éû⁄ôîƒ¯†£IR≠`"Ií$Ií$’!•U¸ﬂÀÀ¯ÛÙ’D"–™a*wèÌÕ‡ˆçÉé&Iµäà$Ií$IíTG,\WÃ¯IÛX±y7 „ÚÛ∏ÂÃÆd§$úLíjIí$Ií$©ñ´®
Ûá7Wqˇ+®GhíûÃoG˜‰]sÇé&Iµñà$Ií$IíTã≠‹ºõÒìÊ±`]1 ﬂÏŸú_çÍIvÉ§ÄìIRÌf"Ií$Ií$’B·pÑøÃ¯ò;_ZJYeòÃî~9™gınI(
:û$’z í$Ií$IR-S∏}/?|r>Ô}¥Ä„;5ÂŒ—Ωhûïp2I™;,@$Ií$Ií§Z"â0yŒ:~Ò‹vóUíöœOŒË ˇjÌUíÙYÄHí$Ií$Iµ¿Ê]•¸¯©Öºˆ·f ˙∑iƒ›cz”∂IÉÄìIR›d"Ií$Ií$Ï≈Ö˘Ò”Ÿ±∑Ç§¯8∆ü“âÀG¥'>Œ´>$ÈÀ≤ ë$Ií$IíRº∑Ç[ü]ƒ‘y Ë⁄"ì{∆ı¶KÛÃÄìIR›g"Ií$Ií$‡ùÂ[∏Ò…l*)%.Wú–Åkæ—â§Ñ∏†£IRL∞ ë$Ií$Iíé°ΩÂï‹Ò¬R˛ˆﬁ ⁄5i¿›c{”Øu£ÄìIRl± ë$Ií$Iíéë9k∂s˝§˘|ºm/ i√Mßw!-…”tíT”¸ *Ií$Ií$eeïU‹˚⁄
~{·¥»J·Æs{3ºcì†£IRÃ≤ ë$Ií$Iíé¢7ñp›ƒy,›¥Äs˙µ‚÷ë›…JM8ô$≈6Ií$Ií$È(®¨
Û;qÔkÀ©®äê› â€œÓ…i=öMíÍIí$Ií$©Ü≠ﬁ∫áÎ'ÕcÓ⁄ù ú‹-á€œÓI”å‰`ÉIR=b"Ií$Ií$’êH$¬Ô≠·ˆñ≤Ø¢äå‰n=´;£˚µ"
OíÍIí$Ií$©l,ﬁ«çO.`⁄ä≠ Ì–òª∆Ù¶U√‘ÄìIR˝d"Ií$Ií$}ëHÑ©Û÷Û≥g≥´¥í‰Ñ8n>ΩiK\úW}HRP‚Ç†ÿr«w0`¿ 222h÷¨£FçbŸ≤eáSZZ ïW^I„∆çIOOgÙË—rÃ⁄µk9„å3HKK£Y≥f¸á?§≤≤ÚêcﬁzÎ-˙ıÎGrr2«wè=ˆÿ'Ú¸˛˜øßm€∂§§§0h– fÕöU„Ô≥$Ií$I™ø∂Ì.„ä'Êr›ƒ˘Ï*≠§w^C^∏fkg˘!I≥ Qçz˚Ì∑πÚ +yÔΩ˜xı’W©®®‡îSNaœû=’«\w›u<˜‹sLû<ô∑ﬂ~õ6pŒ9ÁT?^UU≈gúAyy93fÃ‡Ò«Á±«„g?˚Yı1´WØÊå3Œ‡Î_ˇ:ÛÊÕ„⁄kØÂ≤À.„Âó_Æ>f‚ƒâå?û[oΩïπsÁ“ªwoN=ıT6oﬁ|l>í$Ií$)¶Ω∫§àSÔ}áóo"!.ƒı'wb ˜Ü–°iz–—$I@(âDÇ°ÿµeÀö5k∆€oøÕÒ«Oqq1Mõ6Âˇ¯Áû{. Kó.•k◊ÆÃú9ì¡ÉÛ‚ã/rÊôg≤a√rrr xË°á∏È¶õÿ≤eIII‹t”M<ˇ¸Û,Z¥®˙µæ˝Ìo≥sÁN^zÈ% ƒÄx‡Å á√‰ÂÂqı’WÛ£˝Ës≥óîîêïïEqq1ôôô5˝°ë$Ií$Iu‘Æ“
~Ò‹&œY@ßút&åÌCèVY'ìjœØ)h^¢£™∏∏ÄÏÏl ÊÃôCEE'ùtRı1]∫t°uÎ÷Ãú9Äô3g“≥gœÍÚ‡‘SO•§§Ñ≈ãWÛüœq‡òœQ^^Œú9s9&..éìN:©˙Ií$Ií§/j∆™≠úvÔ4&œYG(ﬂ=æ=œ^5‹ÚCíj!ó†Î®	á√\{Ìµ6å=z ∞i”&íííhÿ∞·!«Ê‰‰∞i”¶Íc˛≥¸8¯Å«>ÎòííˆÌ€«é;®™™:Ï1Kó.=lﬁ≤≤2   ™ˇ\RRÚﬂcIí$Ií´J+™¯ÌKK˘ÀÙè»ÀNÂÓ1}ÿ.;ÿ`í§Oe¢£Ê +Ød—¢Eº˚ÓªAG9"w‹q∑›v[–1$Ií$IR-3Øp'„'Õ„£-—ßÁlÕOŒËJz≤ß÷$©6ÛX:*Æ∫Í*˛˝ÔÛÊõoíõõ[=oﬁº9ÂÂÂÏ‹πÛê„ãäähﬁºyı1EEEüx¸¿cüuLff&©©©4i“Ñ¯¯¯√s‡9˛€Õ7ﬂLqqqıØ¬¬¬/˛éKí$Ií§òQQf¬+À˝‡>⁄≤áf…¸Â‚‹qNOÀI™,@T£"ëW]uO?˝4oºÒÌ⁄µ;‰Ò˛˝˚ìòò»ÎØø^=[∂lk◊Æe»ê! 2ÑÖ≤yÛÊÍc^}ıU233È÷≠[ı1ˇ˘é9IIIÙÔﬂˇêc¬·0Øø˛zı1ˇ-99ôÃÃÃC~Ií$Ií§˙iy—.Œ˛√tÓ{c%U·#{∑‰ïÎéÁÎùõMítÑ¨™U£ÆºÚJ˛ÒèÃ3œêëëQΩ≥#++ã‘‘T≤≤≤∏Ù“K?~<ŸŸŸdffrı’W3d»¿)ßúB∑n›8ˇ¸ÛπÛŒ;Ÿ¥i∑‹rW^y%……… |Ô{ﬂ„Å‡∆o‰íK.·ç7ﬁ`“§I<ˇ¸Û’Y∆èœÖ^H~~>‰ﬁ{Ôeœû=\|Ò≈«˛#Ií$IíÍÑ™pÑGﬂ]Õ]Ø,£º2L√¥D~5™gˆjt4I“äD"ë†C(vÑB°√ŒˇÚóøp—EPZZ ı◊_œ?ˇ˘O   8ı‘S˘√˛p»≠©÷¨Y√W\¡[oΩEÉ∏¬˘Õo~CB¬¡ŒÓ≠∑ﬁ‚∫ÎÆc…í%‰ÊÊÚ”ü˛¥˙5x‡Å∏ÎÆªÿ¥i}˙Ù·æ˚Óc–†AGÙæîîîêïïEqq±WÉHí$IíT¨›∂ó&œg÷«€¯zÁ¶¸vt/öe¶úL™õ<ø¶†YÄHü¬/–í$Ií$’ëHÑÕ.‰óˇ^¬ﬁÚ*$≈sÀô›¯ˆÄºO˝aOIüœÛk
ö∑¿í$Ií$IRΩµπ§îõ¶,‡Õe[ ÿ6õª«ˆ&/;-‡dí§Ø Dí$Ií$Iı“øl‡ñ©ãÿπ∑Ç§Ñ8~xJg.ﬁé¯8Ø˙ê§X`"Ií$Ií§zeÁﬁr~˙ÃbûõøÄ≠2ô0∂ùr2N&I™I í$Ií$I™7ﬁ\∂ôõû\¿Ê]eƒ«Ö∏ÚÎ«qıâ«ët4IR≥ ë$Ií$IRÃ€SV…ØûˇêŒZ@˚¶∏glzÁ56ò$È®± ë$Ií$IRLõµz;◊OûG·ˆ} \<¨-7ù÷Öîƒ¯ÄìIíé&Ií$Ií$≈§“ä*&º∫úG¶}D$≠¶r◊ò^Ì–$Ëhí§c¿Dí$Ií$I1g—˙b∆Oö«Ú¢› åÈüÀOGv#3%1‡dí§c≈Dí$Ií$I1£≤*ÃÉo≠‚wØØ†2°Izwú”ãìªÂMítåYÄHí$Ií$)&¨⁄≤õÒìÊ3øp' ßuoŒØœÓA„Ù‰`ÉIía"Ií$Ií§:-é¯Ãè˘ÕãK)´ìëí¿/æ’ùQ}Z
ÖÇé'I
àà$Ií$IíÍ¨ı;˜Ò√…Ûô±j #:6·Œs{—"+5‡dí§†YÄHí$Ií$©ŒâD"Lôªû€û]ÃÆ≤JR„˘Ò7ªù¡mºÍCíXÄHí$Ií$©éŸ∫ªåõüZ»´Kä Ë◊∫!wèÌCª&N&I™M,@$Ií$IíTgº¥h?~z!€˜îì‚∫ì;Ò›„;ÁU™c¬U∞fÏ.ÇÙh3‚‚ÉN%≈Ií$Ií$’z≈˚*∏ÌŸ≈<ı¡z ∫4œ`¬ÿ>tkôp2ÈKXÚ,ºtîl88Àl	ß˝∫ù\.)∆XÄHí$Ií$©Võ∂b7>πÄç≈•ƒÖ‡ª_Î¿µ'u$9¡üñW¥‰Yòt9t^≤1:˚WK©ÜXÄHí$Ií$©V⁄[^…o^\ _gÆ†m„4Ó€õ˛m≤N&}I·™Ëïˇ]~¿˛Y^˙t9√€aI5¿Dí$Ií$IµŒ‹µ;∏~“|Vo›¿˘É€pÛ7ªêñ‰È,’akfz€´Oà@…˙ËqÌF≥XR¨ÚoIí$Ií$’Âïa~˜˙r|k·4œL·Œs{q|ß¶AGìæö™
X4Â»é›]tt≥HıÑà$Ií$IíjÖ7ñ0~“|>‹X¿Ÿ}[ÒÛë›…JK8ôÙTÏÉπÉ˜Aq·ëΩMzŒ—Õ$’ í$Ií$I
TU8¬ﬂ˘à{^]NyUòFiâ‹~vONÔŸ"Ëh“óWZ≥ˇÔ={∂DgiM°™ vq¯= !»l	mÜÀ§RÃ≤ ë$Ií$IR`>ﬁ∫á&œß`Õ NÍ⁄å;ŒÈE”å‰ÄìI_“Ó-˛É0Î(ã^ÕD√÷0ÏZËÛø∞‚òt‚–$˝Ì¥ﬂ∏ ]™! í$Ií$I:Ê"ë-ø~˛CˆUTëûú¿œFvcLˇ\B°P–Ò§/ng!Ã∏Ê˛*˜EgMª¬Î†«hàﬂ*∂€Y0ˆØ“Má.Dœl-?∫ùuÏ≥K1 Dí$Ií$I«‘¶‚Rnú≤ÄwñGo4∏}6ˇ7¶7πç“N&}	[ñ√Ù{a¡DWFg≠˙√àÎ°”È˜…∑Èvt9÷Ãà.<Oœâﬁˆ +?§e"Ií$Ií§c"âÏ¸¸tÍ"JJ+INà„¶”∫p—–∂ƒ≈y’áÍòÛ‡›	∞‰Y™oe’Ók0b|Ù˜œªí).⁄ç8⁄)•zÕDí$Ií$IG›ˆ=Â‹2u!/,‹@Ô‹,Ó€á„ö•úL˙"ëËU”ÓÜUØúw>#Z|‰ÊóM“'XÄHí$Ií$È®z˝√"nö≤ê≠ªÀHàÒÉot‰˚'t !˛0∑íj£H$∫º|⁄(|/:≈Cœs£ÀÕs∫O“·YÄHí$Ií$È®ÿUZ¡Ø˛˝!
Ëÿ,ù	c˚–37+‡d“
W¡í©0Ì(Zù≈'CﬂÔ¿∞@£∂A¶ìÙ9,@$Ií$IíT„fÆ⁄∆ìÁ≥~Á>B!∏lx;Æ?•3)â.yVPYÛˇ]næ˝£Ë,)Ú/Å!WBFÛ@„I:2 í$Ií$I™1•U‹ıÚ2˛¸Ój r•r˜òﬁjﬂ8‡d“(ﬂsá˜√Æ—Yj6æ^©çÇÕ'È± ë$Ií$IRçX∞n'„'ÕgÂÊ› ú70èüú—çÙdOA©ñ€∑f=Ô=˚∂Gg-aË’–ˇBHjl>I_ä˚Hí$Ií$È+©®
Û¿+y‡ÕïTÖ#4ÕHÊ∑£{rbóú†£Iüm◊&ò˘{(x £≈ŸÌ£ãÕ{íç'È´± ë$Ií$I“ó∂¢h„'Õg·˙b ŒË’Ç_}´ç$úL˙;>ÜÈ˜¡O@UYtñ”Fåán£ Œ]5R,∞ ë$Ií$I“Gxt˙jÓ|yÂïa≤R˘Â®ú’ªe–—§O∑˘Cx˜X¯$D™¢≥ºA0‚zËx
ÑB¡ÊìT£,@$Ií$IíÙÖnﬂÀìÁÛ˛ÍËÆÑØuj ùÁˆ"'3%‡d“ßX7¶›Àû?8ÎçhÒ—f®≈á£,@$Ií$IítD"ëì

˘≈sKÿS^EZR<?9£+ˇ3∞5!O ´∂âD`ı€0mBÙw B–Ì,~¥Ïh<IGüà$Ií$Ií>◊Ê]•¸h BﬁX∫ÄmÒcz”¶qÉÄìIˇ%ÜÂ/FØ¯X?':ãKÄ^„¢ÀÕõv
4û§c«Dí$Ií$IüÈ˘πeÍBvÏ≠ )>éNÌƒ•√€ÁU™E™*a—îËéè-Fg	)–ÔBz54Ã6ü§cŒDí$Ií$IáUº∑Çü=ªàgÊm †{ÀL&åÌCÁÊ'ì˛CE)Ã˚;LˇÏ\ù%g¬¿Àa–êﬁ4ÿ|íc"Ií$Ií§Ox{˘n|r>E%eƒ«Ö¯˛	∏˙ƒé$%ƒMä*€è¬Ãﬂ√Ó¢Ë,≠	˘>∏R≤ÇÕ')p í$Ií$I™∂ß¨í€_¯êøøøÄˆMp˜ÿﬁÙm›(‡d“~{∂¡˚¡¨á°¥8:ÀÃÖa◊@ﬂÔ@RZ∞˘$’ í$Ií$I†‡„Ì\?y>k∂Ì‡¢°mπÈ¥.§&≈úLJ6¿å`Œ_†"˙9J„é0¸:Ë9íÇÕ'©÷± ë$Ií$I™Á *´òÍr˛¯ŒGD"–2+Öª∆ÙfÿqMÇé&¡∂U0˝^ò˜OWDg-z√àÎ°ÀôgA'È,@$Ií$IíÍ±≈äπ~“|ñn⁄¿Ë~π‹zV72SN¶zo”Bx˜X¸4D¬—Yõ·0b<t8B°`ÛI™ı,@$Ií$IíÍ° ™0øÛ˜æ∂úä™ç$q˚9=9µ{Û†£©æ[˚>LªVº|p÷È4>Z
.ó§:«Dí$Ií$©û˘hÀnÆü<ü÷Ó‡‘Ó9¸˙Ïû4IO6òÍØHVΩ”&¿öÈ—Y(∫ü›Ò—ºg∞˘$’I í$Ií$IıD8·oÔ≠·é?§¥"LFr∑}´;g˜mE»€	)·0,}.z≈«∆˘—Y\"Ù˘v4Ól>Iuöà$Ií$IR=∞aÁ>~¯‰|¶Ø‹¿„öpÁπΩhŸ05‡d™ó™*`¡§Ëéèm+¢≥ƒ4Ë1π≤ZõORL∞ ë$Ií$IäaëHÑßÊÆÁÁœ-fWi%)âq¸¯õ]˘Œ†6ƒ≈y’áé±ÚΩ¡ﬂ`∆˝P\ù•4ÑAﬂÖÅﬂÖçç')∂XÄHí$Ií$≈®mªÀ¯Ò”yyq }[7‰Ó1Ωiﬂ4=‡d™wJãaˆü`Ê`Ô÷Ë,=Ü\˘CrF∞˘$≈$Ií$Ií§ÙÚ‚M¸¯©Öl€SNb|àkOÍƒwèoOB|\–—TüÏﬁÔ˝!Z~îïDg€D˜{Ù˘_HL	6ü§òf"Ií$IíCJJ+∏ÌŸ%LôªÄŒ9L◊õÓ-≥N¶zeÁ⁄ËmÆÊ˛*K£≥¶]aƒxË~ƒ{ZR“—ÁWIí$Ií§1cÂVnò<ü≈•ÑB›„;p›…INà:öÍã-Àa˙Ω∞`"Ñ+£≥V˝aƒı–ÈtàÛ
$I«éà$Ií$IR∑Øºäﬂæ¥î«f|@õ∆i‹=¶7˘m≥É¶˙c√0m|¯âŒ⁄}-Z|¥;B°@„I™ü,@$Ií$IíÍ∞÷Ó‡˙IÛ˘hÎ æ3∏57üﬁï…ûˆ—Qâ¿öÈ0ÌnXı∆¡yó3a¯x»Ì\6I¬Dí$Ií$©N*Øsˇ+¯˝õ+	G '3ô;œÌÕ◊:5:öb]$+^âÖÔGg°xË9Ü_Õ∫Oí∞ ë$Ií$I™cñm⁄≈¯IÛXº°Äoıi…/ŒÍAVZb¿…”¬U∞¯ix˜(Zù≈'CﬂÔ¿∞@£∂Å∆ì§ˇf"Ií$IíTGTÖ#¸i⁄G‹˝ r ´¬4JK‰W£zrFØAGS,´,É˘ˇÑÈøÉÌEgIÈ0‡R|%d‰õOí>Öà$Ií$IR∞f€nò<üŸÔ ‡]öq«Ëû4ÀH	8ôbVŸnò˚8Ã∏vmåŒR≥a0rHml>I˙ í$Ií$IµX$·≥÷ÚÎÁ?doyí‚πudw∆‰Á
ÖÇéßX¥w;ÃzﬁˆE72Z¬–´°ˇÖê‘ ÿ|ítÑ,@$Ií$Iíj©¢íRn|ro/ﬂ¿†vŸ¸ﬂòﬁ‰eßúL1i◊&ò˘{(x wGgŸÌa¯u–k$$õOíæ Ií$Ií§ZËŸ˘¯È‘EÔ´ )!éOÌÃ%√⁄ÁU™a€W√å˚‡ÉøCUYtñ”F\›FA\|†Ò$ÈÀ≤ ë$Ií$I™EvÏ)ÁñgÒ¸ÇËŒÖû≠≤ò0∂7s2N¶òS¥ﬁΩMÅHUtñ7F\Oo±&©é≥ ë$Ií$I™%ﬁ\∫ôß,`ÀÆ2‚„B\}‚q\˘ı„Håè:öb…∫ò6ñ=pv‹I—‚£Õ–‡rIR≥ ë$Ií$I
ÿÓ≤J~˝¸˛9´Ä„ö•3alozÂ66òbG$´ﬂÜiw√ÍwˆC–Ì,>Zˆ	2ù$ í$Ií$Izˇ£m‹‰|
∑Ô#ÇKÜµ„áßv&%—Ω™·0,{ﬁù ÎÁDgq	–Î€0¸Zh“1–xít4YÄHí$Ií$†¥¢äª_Y∆üﬁ]M$≠¶r˜ÿﬁnﬂ8ËhäUï—›ÔNÄ-K£≥ÑTËwΩÊõOíéIí$Ií§cl·∫b∆Oö«äÕªóü«-gv%#%1‡d™Û*Jaﬁ0˝w∞smtñú	/áAW@z”`ÛI“1d"Ií$IítåTTÖ˘√õ´∏ˇçTÜ#4IOÊ∑£{ÚçÆ9AGS]WZè¬{Ä›E—YZr%∏R≤ÇÕ'I∞ ë$Ií$I:VnﬁÕ¯IÛX∞ÆÄoˆlŒØFı$ªAR¿…TßÌŸÔ?≥Ü“ËÁYy0Ù–˜;êîl>I
êà$Ií$I“QG¯ÀåèπÛ••îUÜ…LI‡ó£zpVÔñÑB°†„©Æ*^3Ä9èA≈ﬁË¨I'~ÙÒﬁNMí,@$Ií$Iíéíu;ˆr√‰˘º˜—v éÔ‘î;G˜¢yVJ¿…Tgm[”ÔÖyˇÑpEt÷¢å∏∫ú	qqA¶ì§Z≈Dí$Ií$©ÜE"&œY«/û[¬Ó≤JR„˘…]˘ﬂA≠ΩÍC_Œ¶Ö0m,ô
ëpt÷vDÙäè'ÇüWíÙ	 í$Ií$I5hÀÆ2n~jØ}∏Ä˛mq˜òﬁ¥m“ ‡d™ì÷æ->Vº|p÷È4>Z
.ó$’ í$Ií$I5‰≈Ö˘…‘ElﬂSNR|„OÈƒÂ#⁄ÁOÁÎàD`’Î—‚cÕÙË,›œâ^Ò—ºG∞˘$©é∞ ë$Ií$I˙ää˜UÛgÛÙÎË⁄"ì{∆ı¶KÛÃÄì©N	W¡áœ¡¥ªa”ÇË,>	zü√ÆÅ∆ÇÕ'Iuåà$Ií$I“WŒÚ-‹¯‰6ïîÇ+NË¿5ﬂËDRÇÀ®uÑ*Àa·$x˜ÿ∂2:KLÉ¸K`»ïêŸ2ÿ|íTGYÄHí$Ií$}	{À+π„Ö•¸ÌΩ5 ¥k“Äª«ˆ¶_ÎF'SùQæ>¯LøJ÷Eg)a–˜`–w!-;–xíT◊YÄHí$Ií$}As÷lÁ˙IÛ˘x€^ .“ÜõNÔBZíßZtˆÌÑŸÇ˜ÑΩ[£≥Ùr‰_…Å∆ì§X·ﬂ í$Ií$IG®¨≤ä{_[¡√oØ"ÅY)‹unoÜwlt4’ª7√{ÄŸÜ≤íË¨a~-Ù˛HL	4û$≈Ií$Ií§#·∆Æõ8è•õvpNøV‹:≤;Y©â'S≠∑s-Ã∏Ê˛*K£≥¶]aƒı–˝là˜ù$~uï$Ií$I˙ïUa~Á#Ó}m9U≤$q˚Ÿ=9≠GÛ†£©∂€≤ﬁΩ7∫‡<\ùµ èùNÉ∏∏@„IR¨≥ ë$Ií$I™¬f≠ﬁŒÊ]•4ÀHa`ªl÷nﬂÀıìÊ1wÌN NÓñ√Ìg˜§iFr∞aUªm¯ ¶MÄü"—Y˚¢≈G€
ôNíÍIí$IíTÔΩ¥h#∑=∑Ñç≈•’≥ÃîJ+¬îWÖ…HN‡÷≥∫3∫_+Bûº÷·D"∞f:LªVΩqpﬁÂL1Zı.õ$’S í$Ií$©^{i—FÆxbÓÅü”ØVRΩeQÁútΩx ≠¶˚p™˝"X˛r¥¯X7+:≈Cœ1—ÂÊÕ∫OíÍ3Ií$IíToUÖ#‹ˆ‹íOîˇ©§¥íÊô)«,ìÍà™JX2ﬁΩäEgÒ…–Ô|z54jd:I í$Ií$©õµz€!∑Ω:úç≈•ÃZΩù!£T™’*À`˛?£ÀÕw¨éŒí2`¿%0¯J»»	4û$È Ií$IíTÔÏ‹[Œ‘÷Û«i´èË¯Õª>ª$Q=P∂Ê<3Ä]£≥‘l¸}x§6
4û$Èì,@$Ií$IRΩGòæj+gÚ ‚" ´¬G¸∂Õ2ºVΩµw;ÃzﬁˆÌàŒ2Z¬∞@ø ©A∞˘$Iü Dí$Ií$≈¥u;ˆ2π`OŒY«˙ù˚™Á][d2¶+~Á#6óîvHhûï¬¿vŸ«,Øjâ]õ¢W{¸ wGgŸÌa¯u–k$$õOíÙπ,@$Ií$IRÃ)≠®‚ï%ELö]»ÙU[âÏo72R’ß„‰—Ωe&°PàñSπ‚âπÑ‡ê$¥ˇ˜[Gv#>.ÑÍâÌ´a∆}¡PUùÂÙÑ„°€∑ .>ÿ|í§#f"Ií$Iíb∆‚≈Lö]»‘y(ﬁWQ=⁄°1„‰qj˜Ê§$z˚¥-x;˝∏Ìπ%á,Doûï¬≠#ªqZè«,øT¥ﬁΩMÅHUtñ7F\OÜê%ò$’5 í$Ií$©N+ﬁ[¡≥Û◊3±†êEÎK™Á-≤R”?ó1˘y‰eß}Êsú÷£'wkŒ¨’€Ÿº´îf—€^yÂG=∞Æ ¶›À^88;Ó§hÒ—fhpπ$I_ôà$Ií$I™s¬·Ô}¥çâÖº¥heï—ÖÊâÒ!NÈ÷ú1˘πåËÿÙÒq!Üth|¥"´6âD‡£∑‡›	∞˙ù˝√PÙW√ØÉñ}'I™) í$Ií$©Œÿ∞sOŒY«‰9Ön?∏–ºsNc‰qvﬂVd7H
0°jµp8z•«¥ªa√‹Ë,.zÜ]M:OíT≥,@$Ií$IR≠VVY≈kK63±†êi+∂\hûú¿»>-óüGØ‹,BÓh–ß©™àÓˆx˜ÿ≤4:KHÖ˛¬ê´†a^∞˘$IGÖà$Ií$I™ïñn*a‚ÏB¶~∞û{.4‹>õ±˘yúﬁ£©IÒüÒ™˜*ˆ¡O¿å˚`Á⁄Ë,9^ÉØÄMÇÕ'I:™,@$Ií$IR≠QRZ¡≥Û60π†ê˘Îä´Á9ô…ú€?ó1˝Ûh€§AÄ	U'îñ@¡£0Û˜∞gst÷†)˛>∏R≤ÇÕ'I:&,@$Ií$IR†"ëÔ}¥ù…Öº∞h#•—ÖÊ	q!NÍö√∏yåËÿÑÑ¯∏Äì™÷€≥ﬁf˝J˜hYy0ÏË˚HL6ü$Èò≤ ë$Ií$IÅÿT\ ìs
ô<gk∂Ì≠ûwlñŒ∏yåÍ€ä&È…&TùQºf> sÉä˝üKM:¡Ò–Û\àO4û$) í$Ií$Èò)ØÛ˙áEL*(‰ÌÂ[Ô_hﬁ )û≥˙¥dL~}Û∫–\Gf€™ËbÛ˘ˇÇ˛=1-˙¿àÎ°ÀôÁUCíTüYÄHí$Ií§£nE—.&Œ.‰È÷≥mOyı|`€l∆‰ÁrFØ§%yöBGh„xw,y"—[¶—våÌøhí$,@$Ií$I“Q≤´¥Ç/ÿ»ƒŸÖÃ+‹Y=oöëÃË~πåÕœ•}”Ù‡™ÓY33Z|¨xÂ‡¨”È—‚#o`pπ$Iµíà$Ií$I™1ëHÑŸÔ`‚ÏB^X∏ë}U ƒ«Ö8±K3∆ÂÁqBÁ¶.4◊ëãD`ÂÎ0ÌnX;#:≈A˜s`¯u–ºG∞˘$Iµñà$Ií$I˙ 6óîÚ‰‹uL.X«Í≠{™ÁÌõ6`\~g˜kE≥åî ™Œ	W¡áœ¬¥	∞iAtü}˛Ü˛ w6ü$©÷≥ ë$Ií$I_JEUò7ñnf“ÏBﬁZæÖ™˝Õ”í‚9≥W∆»£_ÎF.4◊SY'Eóõo[ù%6Ä¸ãa»UêŸ"ÿ|í§:√Dí$Ií$}!+7ÔfrA!SÊÆgÎÓ≤Íyˇ6çóü«ΩZ– ŸS˙Ç ˜¬‹ø¬å˚°d]tñ“}}“≤ç'I™{¸◊à$Ií$I˙\{ *y~¡F&2gÕéÍyìÙ$F˜ÀeL~.«5À0°Í¨};aˆü‡Ω?¿ﬁm—YzszÙøí˝ºí$}9 í$Ií$È∞"ës÷Ï`RA!ˇ^∞ëΩÂöΩsS∆‰Áqbóf$∫–\_∆ÓÕ—“cˆü°¨$:k‘Ü]Ωˇ›#I˙j,@$Ií$I“!6Ô*ÂÈπÎôTP»™-ö∑k“Ä1˘πåÓóKN¶'ßı%Ì\”ÔÉ˛ï•—Y≥n0|<t?‚=]%I™˛ç"Ií$Ií®¨
Û÷≤-L,(‰ç•õ´öß&∆ÛÕû—ÖÊ⁄∫–\_¡ñeÓΩ—Á· Ë¨U>å∏:ùq^I$I™Y í$Ií$’cmŸÕ§ÇuLôªé-ª.4Ôì◊êqÚ8≥W2RL®:o˝\xw|¯o Z¨—˛ÑhÒ—vX™IíéIí$IíÍôΩÂ—ÖÊì÷1Î„Ì’ÛÏIú”∑c‰—)«≈”˙
"¯¯›hÒ±ÍçÉÛ.g¬àÒ–™pŸ$IıÜà$Ií$Iı@$·É¬ùL.(‰π˘Ÿ]ΩQ\æ÷©)„‰qbóíºëæÇHñø”ÓÜu≥¢≥P<Ù√ÆÖf]ç'I™_,@$Ií$Iäa[wóU/4_±ywıºM„4∆ÊÁqNøV¥»J0°bBU%,ô
”&¿Ê≈—Y|2Ù;Ü˛ µ	4û$©~≤ ë$Ií$)∆TVÖô∂b+gÚ⁄áETÓ_hûí«7{¥`ÏÄ<∂Õ&.Œ›˙ä*À`˛?£ÀÕw¨éŒí2`¿•0¯˚êëh<IR˝f"Ií$IRåX≥mì

yrŒ:äJ.4Ôùõ≈ò¸<ŒÍ”íLö´&îÌÜ9è¡Ã`◊∆Ë,≠1∫^©çç'IXÄHí$IíTßÌ+Ø‚≈Eô8ªê˜W\hﬁ(-ëQ}[1n@]ögòP1eÔvòıGxˇ!ÿ∑#:ÀlCØÜ~@RÉ`ÛIíÙ,@$Ií$I™c"ë÷3±†êÁÊm`◊˛ÖÊ°åËÿîq˘yú‘≠…	Ò'UÃ(ŸΩ⁄£‡/P±':ÀÓ √ØÉ^„ !)ÿ|í$Üà$Ií$Iuƒˆ=Â<˝¡z&≤t”ÆÍyn£T∆ÊÁqnˇ\Z6t°πj–ˆ’0˝w0ÔÔPUù5Ô	√«C∑oAú%õ$©ˆ≤ ë$Ií$©´
Gò∂bì÷Ò íMTTEö'%ƒqzèÊåÀœcp˚∆.4WÕ*ZÔﬁã¶@$ùµ#Æá„Nä^n$IR-g"Ií$IR-T∏}/ì˜/4ﬂP\Z=Ô—*ìq˘yú’ªYi.4W+úÔNÄe/úw2åmÜóKí§/¡Dí$Ií§Z¢¥¢äóob‚ÏBf¨⁄V=œJM‰Ïæ≠ìüK˜ñY&TLäD‡£∑`⁄›Ò¥˝√t›Ò—¢wÄ·$I˙Ú‚Ç†ÿÚŒ;Ô0r‰HZ∂lI(bÍ‘©á<^TTƒE]DÀñ-IKK„¥”Nc≈äáSZZ ïW^I„∆çIOOgÙË—rÃ⁄µk9„å3HKK£Y≥f¸á?§≤≤ÚêcﬁzÎ-˙ıÎGrr2«wè=ˆÿ—xó%Ií$È+âD",\WÃOß.b‡Ø_„öÕc∆™m˚ö7·æÛ˙Ú˛èø¡œœÍn˘°ö√áœ¡#_áøçäñq	–˜;p’lÛòÂá$©NÛ
’®={ˆ–ªwo.π‰Œ9ÁúCãD"å5äƒƒDûyÊ233ô0a'ùtKñ,°AÉ \w›u<ˇ¸ÛLû<ô¨¨,Æ∫Í*Œ9Á¶Oü@UUgúqÕõ7g∆ål‹∏ë.∏ÄƒƒDnø˝v VØ^Õgú¡˜æ˜=˛˛˜øÛ˙ÎØsŸeó—¢EN=ı‘c˚Aë$Ií§√ÿπ∑ú©¨gb¡:>‹XR=o’0ïs˚Árnˇ\Ú≤”L®òUU›Ì1ml]ù%§Bˇã`ËUêïh<IíjJ(âDÇ°ÿ
Öx˙Èß5j Àó/ßsÁŒ,Z¥àÓ›ªáiﬁº9∑ﬂ~;ó]v≈≈≈4m⁄î¸„ú{Óπ ,]∫îÆ]ª2sÊLÃã/æ»ôgû…Ü»……‡°á‚¶õnbÀñ-$%%q”M7Ò¸Ûœ≥h—¢Í<ﬂ˛ˆ∑Ÿπs'/ΩÙ“Â/))!++ã‚‚b233k##Ií$©æ
á#L_µïâ≥yeqÂU—Â“IÒqú“=áqÚ÷°âÕutTÏÉûÄÈ˜AÒ⁄Ë,9^ÉØÄMÇÕ')Êx~MAÛ
3eee §§§Tœ‚‚‚HNNÊ›wﬂÂ≤À.cŒú9TTTp“I'U”•KZ∑n]]ÄÃú9ìû={Vó ßûz*W\qã/¶oﬂæÃú9ÛêÁ8pÃµ◊^{tﬂIIí$I:åu;ˆ2π`OŒY«˙ù˚™Á][d2.?óQ}[—0-)¿Ñäi•%Pgò˘ÿ≥9:k–Ü\	˘óBä'%%I±…D«ÃÅ"„ÊõoÊ·á¶AÉ‹sœ=¨[∑éç7∞i”&íííhÿ∞·!oõìì√¶Mõ™è˘œÚ„¿„˚¨cJJJÿ∑o©©©ü»WVVV]“@¥°ñ$Ií§/´¥¢äWñ1π†êwWnÂ¿˝2R’ß„‰—Ωe&°êW{Ë(Ÿ≥ﬁf˝Jã£≥¨÷0Ï—=âü¸ﬁXí§Xb¢c&11ëßûzäK/ΩîÏÏl‚„„9È§ì8˝Ù”©wbª„é;∏Ì∂€Çé!Ií$©é[º°òI≥ô:o≈˚*™ÁC;4f‹Ä<NÌﬁúîƒ¯ *ÊØÉ¿ú«†rˇGM:¡Ò–Û\àO4û$I«äàé©˛˝˚3oﬁ<äãã)//ßi”¶4à¸¸| ö7oNyy9;wÓ<‰*ê¢¢"ö7o^}Ã¨Y≥yﬁ¢¢¢Í«¸~`ˆü«dffˆÍÄõoæôÒ„«Wˇπ§§ÑºººØˆKí$I™ä˜VÏ¸ıL,(d—˙ÉWì∑»JaLˇ\∆‰Áπ–\Gﬂ÷ï0˝^òˇ/Ô/ﬂZˆÖ◊CÁ3 ..–xí$k 
DVV +V¨†††Ä_˛Úó@¥ ILL‰ı◊_gÙË— ,[∂åµk◊2d» Ü¬Ø˝k6oﬁL≥fÕ xı’W…ÃÃ§[∑n’«º¬áºÊ´ØæZ˝áìúúLrrrÕæ£í$IíbV8·Ωè∂1±†êóm¢¨2∫–<1>ƒ)›ö3&?óõÔBsm¿ª`ÒT`ˇ⁄éÄ„°˝◊¡€¨IíÍ)’®›ªw≥rÂ Í?Ø^ΩöyÛÊëùùMÎ÷≠ô<y2Mõ6•uÎ÷,\∏êkÆπÜQ£Fq )ß —b‰“K/e¸¯Òdggìôô…’W_Õê!C<x0 ßúr
›∫u„¸ÛœÁŒ;Ôd”¶M‹rÀ-\yÂï’∆˜æ˜=x‡nºÒF.π‰ﬁx„&MöƒÛœ?Ï?(í$Iíb Üù˚xrŒ:&œ)§p˚¡ÖÊùs2; è≥˚∂"ªÅÕu¨ô	”ÓÜïØúu:=Z|‰.ó$IµÑàjTAA_ˇ˙◊´ˇ|‡ñR^x!è=ˆ7nd¸¯Ò—¢E.∏‡~˙”üÚ˜‹sqqqå=ö≤≤2N=ıT˛á?T?œøˇ˝oÆ∏‚
ÜBÉ∏¬˘≈/~Q}LªvÌx˛˘ÁπÓ∫Î¯›Ô~Gnn.˙”ü8ı‘SèÚG@í$IR,*´¨‚µ%õôXP»¥[.4ON`düñåÀœ£WnñÕuÙE"∞ÚıhÒ±vFtäÉ£a¯uê”=ÿ|í$’"°Hmÿ>-’B%%%deeQ\\Lfff–q$Ií$`È¶&Œ.dÍÎŸ±˜‡BÛ¡Ì≥õü«È=Zêö‰Bs·*¯Yò66-àŒ‚ì†œˇ¿∞k ª}∞˘$È0<ø¶†yà$Ií$Iˇ°§¥ÇgÁm`rA!Û◊Wœs2ì9∑.c˙Á—∂IÉ ™^©,á£ÀÕ∑ÌøÂtb»øÜ\ô-ç'IRmf"Ií$I™˜"ëÔ}¥ù…Öº∞h#•—ÖÊ	q!NÍö√∏yåËÿÑÑ¯∏Äì™ﬁ(ﬂsˇ
3ÓÉíı—YJC|¸êñh<IíÍÒ¯„è”§IŒ8„ nºÒF˛¯«?“≠[7˛˘œ“¶MõÄJí$I“—±©∏î)s◊1©†ê5€ˆVœ;6Kg‹Ä<FımEìÙ‰ ™ﬁŸ∑f?Ô={∑EgÈÕaËU–ˇ"HŒ2ù$Iuä;@DÁŒùy¡9Òƒô9s&'ùt˜‹sˇ˛˜øIHH‡©ßû
:b ºG°$Iíõ +√º±¥àâ≥y{˘¬˚ø+nêœY}Z2&?èæy]hÆck˜fò˘{ò˝g(ﬂù5j√ÆÖﬁÁAbJêÈ$ÈKÒ¸öÇÊ ¢∞∞ê„é;Ä©Sß2zÙh˛ﬂˇ˚6åN8!ÿpí$IíTCVÌb‚ÏBû˛`=€ˆîWœ∂ÕfL~.gÙjAZíﬂ&Î€±f‹¸*K£≥f›`¯xË~6ƒ˚9)I“óÂﬂ¢"==ùm€∂—∫uk^yÂ∆è@JJ
˚ˆÌ8ù$Ií$}yªJ+¯˜ÇçLú]»º¬ù’Û¶…åÓóÀÿ¸\⁄7M.†ÍØ-À‡›{`¡$àTEgπ`ƒı–ÒTàsﬂå$I_ïà8˘‰ìπÏ≤ÀË€∑/Àó/Áõﬂ¸& ã/¶m€∂¡Üì$Ií§/(â0˚„Lú]»7≤Ø"zr9>.ƒâ]ö1.?è:7u°πÇ±~Lõ Küˆﬂ≠˝◊£≈G€·‡≠◊$I™1 ‚˜øˇ=∑‹rÖÖÖLô2Ö∆ç0gŒŒ;ÔºÄ”Ií$I“ëŸ\R ìs◊1π`´∑Ó©û∑o⁄Äq˘yú›ØÕ2‹£† D"Òª0Ìn¯ËÕÉÛÆ#£∑∫j’/∏lí$≈0ó†ÎSÌﬁΩõMõ6UÔ©o\“$Ií$’~UaﬁX∫ôI≥yk˘™ˆo4OKäÁÃ^-7 è~≠π–\¡áa≈À—‚c›ÏË,Ω∆Fóõ7Îh<I:⁄<ø¶†yàxÁùw;_¥h∑ﬁz+[∂l9∆â$Ií$È≥≠‹ºõ…ÖLôªû≠ªÀ™Á˝€4b\~gÙjAÉdøÂU@™*aÒ”—õGgÒ…–Ôz54jl>IíÍ	ˇ5(N8·Ñ√ŒC°#Gé<∂a$Ií$ÈSÏ)´‰˘ôXP»ú5;™ÁM“ì›/ó1˘π◊,#¿Ñ™˜*À`ﬁ?`˙Ω∞„„Ë,)\
Éø9A¶ì$©ﬁ± ;vÏ8‰œUUU¨Zµän∏Å·√áîJí$Ií¢ÕÁÆç.4ˇ˜ÇçÏ-?∏–¸Îùõ2&?èª4#—ÖÊ
RŸnòÛòÒ Ïﬁù•5Ü¡W¿ÄÀ!µa†Ò$I™Ø‹¢O5oﬁ<N<ÒD∂oﬂtî@xèBIí$)8[vïÒ‘‹uL*(d’ñÉÕ€5i¿ò¸\F˜À%'”ÖÊ
ÿﬁÌ˛√0Îaÿ∑ˇá3[¡–@øÛ!©A∞˘$)`û_S–ºDü*..é§§§†cHí$I™'*´¬ºµl
ycÈÊÍÖÊ©âÒ|≥gt°˘Ä∂.4W-P≤f> Åä˝]„„¢ãÕ{çÉøóñ$©6∞ ,¯ƒ¨®®à_¸‚\r…%á<ﬁ´WØcMí$IR=—ñ›L*X«îπÎÿ≤Î‡BÛ>y7 è3{µ #%1¿Ñ™7¬U∞fÏ.ÇÙh3‚‚>æ˝#ò˛ªËûè™ÚË¨yOq=t=Î–c%IR‡ºñàãã#
Òiü
ÖBTUU„t¡Ò=Ií$ÈËŸ[]h>π`≥>>x€›ÏIú”∑c‰—)«ÖÊ:Üñ</›%Œ2[¬iøÖ∆‡›{`—àÑ£èµ->é˚xUí$ñÁ◊4Ø ´WØ:Ç$Ií§z âA·N&Ú‹¸çÏ.´ ._Î‘îqÚ8±KI	.4◊1∂‰Yòt_?X≤&ùËÏ∏ìaƒ¯Ë’!í$©V≥ m⁄¥	:Ç$Ií§∂uwS?XœƒŸÖ¨ÿºªzﬁ¶qcÛÛ8ß_+Zd•òPıZ∏*zÂ«óˇ≠€®hÒ—¢˜±H%IíjÄà$Ií$©∆UVÖô∂b+gÚ⁄áETÓ_hûí«7{¥`ÏÄ<∂Õ&.Œ[)`kfz€´O3‡2ÀIíÍIí$IRçY≥mì

yrŒ:äJ.4Ôùõ≈ò¸<ŒÍ”íLö´6Ÿ±Ê»é€]ttsHí§g"Ií$I˙JˆïWÒ‚¢çLú]»˚´.4oîñ»®æ≠7 è.Õ]|™Zf◊&xˇ·ËØ#ëûstÛHí§g"Ií$I˙¬"ë÷3±†êÁÊm`◊˛ÖÊ°åËÿîq˘yú‘≠…	Ò'ï˛ÀÊ•0„~X8	™ £≥P<D™>ÂBêŸ“•Áí$’A  ≥rÂJ6oﬁL8>‰±„è?>†Tí$IíjõÌ{ y˙ÉıL.(dÈ¶]’Û‹F©åÕœ„‹˛π¥lËBs’2ë|<-Z|¨xÂ‡ºız5TU¬‰¸o∏GÕiøÅ8À<IíÍÒﬁ{ÔÒ?ˇÛ?¨Y≥ÜH$r»c°Pà™™O˚)Ií$IıAU8¬¥[ò\∞éWñl¢¢*˙}CRBß˜hŒ∏¸<∑oÏBs’>Uï∞dj¥¯ÿ8oˇ0]G¬–@ﬁÄÉ«Ü˛
/›tËBÙÃñ—Ú£€Y«0¥$I™) ‚{ﬂ˚˘˘˘<ˇ¸Û¥h—ÇP»oZ$Ií$A·ˆΩLﬁø–|CqiıºG´L∆ÂÁqVÔVd•π–\µPŸ.ò˚7xÔA(^ù%§BﬂÔ¿‡+†qáOæM∑≥†À∞fFt·yzNÙ∂W^˘!IRùe"V¨X¡ìO>…q«tIí$I+≠®‚Â≈õò8ªê´∂Uœ≥R9ªo+∆‰Á“ΩeVÄ	•œP≤f=èBiqtñ÷}Ú/Öç?˚Ì„‚°›à£üSí$ b–†A¨\π“Dí$I™«≠/f‚ÏBûô∑ûí“ÉÕá◊Ñ1˘yú“-áîD^µT—ò˘ ,ò·äË¨qGzÙâÓ•ë$©>≤ W_}5◊_=õ6m¢gœû$&z	{Ø^ΩJ&Ií$Èh⁄π∑ú©¨gR¡:ñl,©û∑jò π˝s9∑.yŸi&î>C$´ﬂâÓ˜X˘Í¡yÎ°—≈ÊùNÉ∏∏‡ÚIí§¿Ö"ˇΩıZıN‹a˛A
ÖàD"ız	zII	YYYìôôtIí$©FÑ√¶Ø⁄ ƒŸÖº≤∏àÚ™0 IÒqú“=áqÚ÷°âÕU{UU¿‚©0„>ÿ¥ :≈\lûõh<I“Aû_S–ºD¨^Ω:Ëí$Iíé≤u;ˆ2π`OŒY«˙ù˚™Á][d2.?óQ}[—0-)¿Ñ“Á(€sˇ∫±yatñòvp±yv˚`ÛIí§Z«D¥i”&Ëí$IíéÇ“ä*^YRƒ‰ÇBﬁ]πï◊ˇg§$0™O+∆»£{ÀLB!ØˆP-V≤ﬁ
É≤˝ãÕ4ÖÅﬂÖóBZv†Ò$IRÌeRO=˚Ï≥ú~˙È$&&ÚÏ≥œ~Ê±gùu÷1J%Ií$©&,ﬁPÃ‰Çu<˝¡zä˜UTœávhÃ∏yú⁄ΩπÕU˚-Ü¿¬…ˇµÿ¸Í˝ãÕSÇÕ'Iíj=wÄ‘Sqqql⁄¥âfÕöv»Ó ÒÖí$I™ä˜VÏ¸ıL,(d—˙ÉÕ[d•0¶.cÚÛ\hÆ⁄/Å’o√Ù˚`’ÎÁmÜEãèéß∫ÿ\íÍœØ)h^ROÖ√·√˛∑$Ií§∫#éﬁG€òXP»Kã6QV˝∑}b|àS∫5gL~.#:6%ﬁÖÊ™Ì™*`Ò”˚õ/åŒBq–Ì[0‰j»Ìl>IíT'YÄHí$IR≥aÁ>ûú≥é…s
)‹~p°yÁú∆»„Ïæ≠»n‡Bs’•%õó¨ãŒ”†Ô˘˚õ∑6ü$I™”,@$Ií$©(´¨‚µ%õôXP»¥[.4ON`düñåÀœ£WnñÕU7îlàñsÉ≤˝∑lk–}Ú/q±π$I™ í$IíTã-›T¬ƒŸÖL˝`=;ˆ\h>∏}6cÛÛ8ΩGRì\hÆ:b”"òy`±yet÷§StøGœ±.6ó$I5 Dí$Iíjôí“
ûù∑Å…ÖÃ_W\=œ…LÊ‹˛πåÈüG€&L(}ë|Ù&Ã∏VΩqpﬁf8˚w≤ãÕ%I“Qa"Ií$Iµ@$·Ωè∂3π†êm§¥"∫–<!.ƒI]s7 èõêÔâb’U∞Ë©hÒQÙüãÕG¡–´†ïãÕ%I“—eROïîîÒ±ôôôG1â$IíTøm*.e ‹uL*(dÕ∂Ω’ÛéÕ“7 èQ}[—$=9¿Ñ“TZsﬂøÿ|}tñÿ ˙] Éøç⁄Oí$’ ıT√Üèx9bUU’QN#Ií$’/ÂïaﬁXZƒƒŸÖºΩ|·˝Õ$≈sVüñå…œ£oﬁëˇõ]™ä◊¡˚¡ú«.6Oœâ.6Ô±ãÕ%I“1gROΩ˘Êõ’ˇ˝Ò«Û£˝àã.∫à!CÜ 0sÊL¸qÓ∏„é†"Jí$I1gE—.&Œ.‰È÷≥mOyı|`€l∆‰ÁrFØ§%˘möÍòM£∑πZ4Â?õwé.6Ô5ºÇIí$#âD"AáP∞æÒçopŸeóqﬁyÁ2ˇ«?˛¡ˇ¯GﬁzÎ≠`Ç¨§§Ñ¨¨,äããΩò$Iíæ¥]•¸{¡F&Œ.d^·ŒÍy”ådF˜Àel~.Ìõ¶P˙2"ëËBÛ˜Gú–v˝wíãÕ%Iû_S‡,@DZZÛÁœßc«éáÃó/_Nü>}ÿªwÔßºelÛ¥$Iíæ¨H$¬Ïèw0qv!/,‹»æäËme„„Búÿ•„ÚÛ8°sSö´Ó©,á≈õ/äŒBÒ–}TÙäèñ}ç'I™]<ø¶†ymµ»ÀÀ„ëG·Œ;Ô<d˛ß?˝âºººÄRIí$IuœÊíRûúªé…ÎXΩuOıº}”åÀœ„Ï~≠hñë`BÈK*-Ü9è¡{¡Æ—YbË!˙4jh<Ií§√± ˜‹s£GèÊ≈_d–†A Ãö5ã+V0e îÄ”Ií$Iµ[EUò7ónfRA!o.€B’˛çÊiIÒúŸ´„‰—Øu#ö´n*^Ô=]l^æ+:Ko]lû1§6
6ü$I“gX†∞∞ê|ê•Kó–µkWæ˜ΩÔ’Î+@ºDOí$IüeÂÊ›L.(d ‹ıl›]V=Ôﬂ¶„ÚÛ8£W$˚3g™£6ŒáDowu`±y”Æ—€\ı<◊≈Êí§#‚˘5ÕD˙~Åñ$I“€SV…Û62±†ê9kvTœõ§'1∫_.cÚs9ÆYFÄ	•Ø ÅUØ√Ù˚`ı€ÁÌé?∏ÿ‹+ô$I_ÄÁ◊4I Lõ6çá~òè>˙à…ì'”™U+˛ˆ∑ø—Æ];Üt<Ií$)0ëHÑπk£ÕˇΩ`#{À.4ˇzÁ¶å…œ„ƒ.ÕHt°πÍ™ rXÙdÙäèÕã£≥P<Ù8Ü\-˚Oí$ÈÀ≤ S¶L·¸ÛœÁˇ˜ô;w.ee—À˜ãããπ˝ˆ€y·ÖN(Ií${[vïÒ‘‹uL*(d’ñÉÕ€5i¿ò¸\F˜À%'”ÖÊ™√ˆÌå.6ˇ!ÿµ1:KJá~¬‡ÔA√÷A¶ì$I˙ ,@ƒØ~ı+zË!.∏‡˛ıØUœá∆Ø~ı´ ìIí$I«VeUò∑ñmaRA!o,›LÂ˛ÖÊ©âÒ|≥gt°˘Ä∂.4W∑s-º˜Ã} wGgÈÕ£•Gˇã!µa†Ò$IíjäàX∂l«¸'ÊYYYÏ‹πÛÿí$Iíé±è∂ÏfR¡:¶Ã]«ñ]ö˜…k»∏yúŸ´)â&îj¿∆˘0„~XÙD¢∑r£Y∑ËbÛÁBBR∞˘$Iíjòàhﬁº9+WÆ§m€∂áÃﬂ}˜]⁄∑oL(Ií$È(€[]h>π`≥>ﬁ^=œnêƒ9}[1v@ùr\hÆ:.ÅïØ√åﬂ¡ÍwŒ€}Ü˝ :|√≈Êí$)fYÄàÀ/øúkÆπÜG}îP(ƒÜò9s&7‹p?˝ÈOÉé'Ií$’òH$¬Ö;ô\P»sÛ7≤ª¨Ä∏|≠SS∆»„ƒ.9$%∏–\u\e,|f> õóDg°xË1Ü^-zõOí$È∞ ?˙—èá√|„ﬂ`ÔﬁΩ¸Ò$''s√7pı’WOí$I˙ ∂Ì.„È÷3qv!+6ÔÆû∑iú∆ÿ¸<ŒÈ◊äY©&îj»æùP(ºˇ0Ïﬁù%•Cˇã`–˜†a^êÈ$Iíé©P$âBµCyy9+WÆd˜Ó›tÎ÷çÙÙÙ†#™§§Ñ¨¨,äãã…ÃÃ:é$Iíæ† ™0”Vle‚ÏB^˚∞®z°yJbﬂÏ—Ç±Úÿ6õ∏8oˇ£∞s-º˜ Ã˝Î¡≈Ê-£ãÕ˚]ËbsIR <ø¶†yà™%%%—≠[∑†cHí$I_…öm{òTP»ìs÷QTrp°yÔ‹,∆‰ÁqVüñd∫–\±b√ºËbÛ≈Oˇ«bÛÓ˚õèv±π$I™◊,@Dii)˜ﬂ?oæ˘&õ7o&Ú¯‹πsJ&Ií§˙Æ*a÷ÍÌlﬁUJ≥å∂À&˛0WlÏ+Ø‚≈Eô8ªê˜W\hﬁ(-ëQ}[1n@]ö˚Sáäë¨xf‹O;8o˝t8—≈Êí$IXÄ∏Ù“KyÂïW8˜‹s8p !ˇ°,Ií§Z‡•EπÌπ%l,.≠ûµ»J·÷ë›8≠G"ë÷3±†êÁÊm`◊˛ÖÊ°åËÿîq˘yú‘≠…	ÒAΩRÕ™,ÉÖì£W|lYù≈%DØÙr¥Ël>Ií§Z∆ "++ã^xÅa√Ü•VÒÖí$I¡yi—FÆxb.ˇ˝Õ Å’9∑.◊≥t”ÆÍ«r•26?ès˚Á“≤°ÕCˆÌ¯è≈ÊE—YR‰_]lûïh<Ií>çÁ◊4Ø ≠Zµ"###Ëí$IΩÌ’mœ-˘D˘Tœ&œY@RBß˜hŒ∏¸<∑oÏBs≈ñk.6Øÿùe¥Ñ¡W@ˇ!%+ÿ|í$Iµúà∏˚ÓªπÈ¶õxË°áh”¶M–q$IíTœÕZΩ˝ê€^}öKÜµÂöot"+ÕÖÊä1ÎÁFosµd*DˆÔhÃÈ]lﬁ˝lõKí$!ëüüOii)Ì€∑'--çƒƒCøÅ‹æ}˚ßº•$IíTÛ6Ô˙¸Ú†w^CÀ≈épVæ->˛s±yá£≈G˚Øªÿ\í$È≤ ÁùwÎ◊ØÁˆ€o'''«%Ëí$I
TF ëïÕ2RérÈ®,Éa∆∞uYtó =ŒÖ°WAÛû¡Êì$I™√,@ƒå3ò9s&Ω{˜:ä$IíÍ±H$¬Àãã¯˘≥ã>Û∏–<+ÖÅÌ≤èM0Èhÿª˝‡bÛ=õ£≥‰LË—˛≈Ê≠ç'Ií,@Dó.]ÿ∑o_–1$IíTè≠ﬂπè[üYƒkFO7IObÎÓrBp»2Ù◊*ﬂ:≤Ò.<W]¥„„˝ãÕˇvp±yfnt±yø %3–xí$I±ƒD¸Ê7ø·˙ÎØÁ◊ø˛5={ˆ¸ƒêÃLˇ.Ií§££≤*Ã_¶Ã=Ø-goyâÒ!æ{|Æ:Ò8ﬁZ∂ô€û[r»BÙÊY)‹:≤ßıh`jÈKX?gˇbÛg]l>Ï—≈ÊÒÓ≥ë$I™i°H$˘¸√À‚‚‚ >±˚#â
Ö®™™
"V‡JJJ»  ¢∏∏ÿHí$È(¯`Ì~¸Ù">‹X¿¿∂Ÿ¸˙ÏtÃ…®>¶*a÷ÍÌlﬁUJ≥åËmØºÚCuF8+^Å˜¡öÈÁæ±±˘	.6ó$≈4œØ)h^"ﬁ|ÛÕ†#Hí$©))≠‡ÆóñÒƒ˚kàD†aZ"?>Ω+Áˆœ%Óø ç¯∏C:4(©Ù%UîFõœ| ∂.èŒ‚°Ár%4Ôl>Ií§z¬D|Ìk_:Ç$IíÍÅH$¬øl‰ˇ^¬ñ]e åÓóÀèøŸÖ∆È…ßìj¿ﬁÌPgxˇèá.6œø8∫ÿ<≥e∞˘$IíÍÒŒ;Ô|Ê„«¸1J"Ií§Xµv€^~˙Ã"ﬁ^æÄˆM´≥{0¥CìÄìI5`˚jxÔ¡P±7:ÀÃÖ!ﬂáæÁªÿ\í$)  ‚ÑN¯ƒÏ?˜Å‘◊ í$I˙Í +√<2Ì#Ó{}eïaí‚„∏ÚÎ«ÒΩ⁄ìút<È´Y7'∫ﬂ„√g.6oﬁÜ^›Gπÿ\íÙˇŸªÔ¯*Îªˇ„ØìÕJÿ3Ï!ÑÑîÂ™uÄ »∞jµjµŒﬁ’ﬁ˛l›∂Æ⁄ªÀQ≠m≠⁄÷∂@p†8p±îΩ˜
$lV»8Á˜«ÖâT≠®!W∆Î˘x¯∞˘ú+'Ô®I…yÁ˙~$ÖÃDÏ⁄µÎ∞∑ãããô;w.∑ﬂ~;˜ﬁ{oH©$IíT›}¥n'∑å[» ≠{‹π	˜å §S≥˙!'ìæÅhVLÜi√ÜiÂÛ.ß¡‡A«ì\l.IíTEXÄà¥¥¥œÃN?˝tííí∏Ò∆ô={v©$IíT]Ìﬁ_ƒ˝Ø.„ﬂo†IΩ$n;´£˙¥9ÏNc©Z).ÑˇÇiè¿éï¡,.zùÉÆÉ·Êì$I“gXÄËµh—ÇÂÀóáCí$I’D,c¸‹M‹˚ RvÏ+‡ª˝€rÛ–Ó4¨õr:Èk⁄ø>˙3Ãzˆ;lHNÉ„.É˛?Ñ‘V·Êì$I“≤ ,8ÏÌX,Fnn.< }˙Ù	'î$Ií™ï5€ˆr€ÑEL[ΩÄn-ÍsÔË,éÎ–8‰d“◊¥sL?¥ÿº‰@0KkØÅÏã πA∏˘$IíÙ•,@Dü>}àD"ƒb±√Ê‰…'ü)ï$Ií™ÉÉ%•<6u5xg5E•QR„¯—©]π‚ÑN$%ƒÖO˙Í6~th±˘$‡–œH≠z˚=2FAº?FKí$U˛…M¨]ªˆ∞∑„‚‚h÷¨)))!%í$IRu0mıvnøà5€˜pr∑f¸‚ÏL⁄5©r2È+äFa≈káõO/üw=_Nt±π$IR5d"⁄∑oˇôŸÓ›ª-@$IíÙπvÏ=»ΩØ,e‹‹M 4kêÃù#2û’ %Á™^ä¿¸¡ÙG`«™`óΩŒÉ¡◊AÛ·Êì$I“7b"~˘À_“°CŒ;Ô< Œ=˜\^x·Zµj≈´ØæJÔﬁΩCN(Ií§™ çÒ¸Ïç‹˜Í2Úâ¿E€ÛøCé!5%1Ïx“ë€∑£|±˘˛Ì¡,%éΩ¸¥7ü$Ií*Ñàx¸Ò«˘«?˛¿î)Sò2e
ì'OÊπÁû„¶õn‚ç7ﬁ9°$Ií¬∂bÀnøêè÷Ì†G´TÓìEü∂√&};V√å?¿‹|j±y;tÙ˝ûãÕ%IíjëóóG€∂mx˘Âó9˜‹s9„å3Ë–°9ù$Ií¬TX\ √oØ‰èÔÆ°$£nR<7ûﬁçÔÓ@BºKŒUMlúuh±˘Àî/6Ô«ˇzúÌbsIí§ ?ÂâFç±q„F⁄∂mÀ‰…ìπÁû{ à≈bîññÜúNí$Iayw≈6nü∞à;˜pzFÓŸì6ÎÑúL:—RX~h±˘∆ÂÛÆC-6?¡≈Êí$I5úà3f\p]ªve«éúyÊô Ãù;ó.]∫ÑúNí$IïmkA!?y	//»†UZ
wçÏ…êûÓEP5P| Ê=”Öù´ÉY|Ù:]ÕªáõOí$Iï∆D¸ˆ∑ø•Cál‹∏ë|ê˙ıÎêõõÀ5◊\r:Ií$Uñh4∆?fm‡¡…ÀÿSXB\.=æ#7úﬁç˙…˛Ë†*nﬂˆO-6ﬂÃR¬qóCˇ+]l.IíTEb±X,ÏRUTPP@ZZ˘˘˘§¶¶ÜGí$È®Z≤πÄ[∆/dﬁ∆› ÙJO„æ—Yd∂I7òÙev¨ÜÈèw}î≥ÜÌ`–u–ÁBHÆn>Iíj1__Sÿ¸5.∞rÂJﬁyÁ∂n›J4=Ï±;Ó∏#§Tí$I:⁄ˆ,·woÆ‡…◊QçQ?9ÅõÜ√˜∂'>Œ˝™¬6Ãõ/{Ö≤≈Ê≠˚¬‡Aèë.6ó$Iíà‡O˙W_}5Mõ6•eÀñD>µ0âXÄHí$’Po.Ÿ¬ù≥i˜ Ügµ‚é¥HM	9ôÙ¢•∞¸U¯!»ôU>Ôvf∞ÿº˝`õKí$©åà∏Áû{∏˜ﬁ{π˘Êõ√é"Ií§JêõÄª&.Êı≈[ HoTá_úù…)›õáúL˙E˚a˛'ãÕ◊≥¯$Ë}~p‘U≥c¬Õ'Ií§*…DÏ⁄µãÔ|Á;a«ê$I“QVRÂÈÈÎ˘ÕÀŸWTJB\Ñ+NÏƒˇú⁄ï:IÒa«ì>kﬂvòı'¯ËOˇ±ÿ¸äCãÕ[ÑOí$IUõà¯Œwæ√oº¡UW]vIí$%rvsÀ¯Ö,⁄T @vªÜ‹7&ãÓ-]F©*h˚™`±˘¸~j±y˚‡nèæBRΩpÛIí$©Z∞ ]∫t·ˆ€og∆ådeeëòòxÿ„?˙—èBJ&Ií§ojOa1ø~cœL_G4©)	¸ÙÃú\[‚\rÆ™$Éç3a⁄√á/6o”Ô–bÛÁùJí$I:rëX,;Ñ¬’±c«/|,â∞fÕöJLSuêññF~~>©©˛f§$I™^b±ìÂq◊§≈l)8¿Ÿ}Zs€ö5H9ùÙ)—RXˆrP|‰|T>?fX∞ÿº› õKíTM˘˙ö¬Ê bÌ⁄µaGê$IR⁄∏s?wN\Ã€À∂–°I]~1*ìª69ôÙ)E˚aﬁ?Ç≈Êª˝Lü¸©≈Ê›¬Õ'Ií§jœDá˘‰Ü†àøa%IíTÌóFyÚÉµ¸ÓÕï(.%1>¬’'wÊöS∫êíË—A™"ˆnÉYO¿GÜ;ÉYùFp‹†ˇ†~ÛpÛIí$©∆∞  œ<Ûø˙’ØXπr% ›∫u„¶õn‚¢ã.
9ô$IíéƒÏıª∏u¸BñÂÌ`@«∆‹;:ì.ÕÑúL:d˚ `±˘ºBip,ç:w{Ùπ¿≈Êí$I™p ‚7ø˘∑ﬂ~;◊]w«< |W]u€∑oÁÜn9°$IíæH˛˛b~˘˙2˛9k±4™õ»-√zpNøtÔÍU¯b1ÿ0=ÿÔ±¸’Úyõc·¯A˜≥\l.Ií§£∆%Ë¢c«é‹}˜›\|Ò≈áÕü~˙iÓ∫ÎÆZª#ƒ%Mí$©*ã≈bLúøô_ººÑÌ{ã ¯Nøt~6¨çÎ%ÖúNµ^¥ñN
äèMF>µÿ|†ãÕ%I™|}MaÛëõõÀ‡¡É?3<x0πππ!$í$I“≥n˚>niÔØ‹@Áfı∏wt;5	9ôjΩ¢}0˜0„Qÿµ.ò≈'CüÔG]5Ìj<Ií$’. ¢Kó.<˜‹s‹rÀ-áÕˇ˝Ô”µ´?†Hí$UE%Qûxo5ΩΩä¢í(I	q\JÆ<π…	#§Ì›˙©≈ÊªÇYù∆¡RÛ„~ ıõÖõOí$Iµíà∏˚Óª9ÔºÛxÔΩ˜ vÄ|¯·áºı÷[<˜‹s!ßì$I¿Ã5;∏u¬"Vm›¿	]örœ®L:4uq¥B¥mE∞ÿ|˛ø>µÿº#æz_ Iu√Õ'Ií§ZÕDå;ñô3gÚ€ﬂ˛ñ	& –£GfÕöEﬂæ}√'IíTÀÌ⁄Wƒ}Ø.Â˘Ÿ9 4≠üƒÌge0≤wkóú+±¨üÏ˜XÒZ˘<˝8¸#Ë>‹≈Êí$I™\Ç.}ó4Ií§0≈b1^ú≥â˚^] Œ}¡íÛ¥„Ê!›I´õr:’J•%∞l|¯lûsh	
èOõKí$}äØØ)lﬁ"^}ıU‚„„2d»aÛ◊_ùh4 ôgûR2Ií§⁄i’÷Ω‹6a!3÷Ï‡ò∏oL&˝⁄79ôj•¢}0˜Ô0˝QÿΩ>ò%§@ü`‡µ–¥K∏˘$Ií§/`"~˙”üÚ¿|fã≈¯ÈOj"IíTI
ãK˘√;´x¸›5ïFIIå„«ßu„Ú:ív<’6{∂î/6/‹ÃÍ6	ñö˜ˇ‘kj<Ií$ÈÀXÄàï+WíëëÒôy˜Ó›YµjUâ$IíjüVnÁ∂	Y∑c? ß”åüüùI€∆.ëV%€∂<ÿÔ±‡ﬂPøF„N0Ë:Ë˝]õKí$©⁄∞ iii¨Y≥Ü:6_µjıÍ’'î$IR-±}ÔAÓyy	Êm†Ej2wéË…ôô-]rÆ ã¡˙-6ü\>o; ÿÔqÃ0õKí$©⁄± gü}6?˛Òè?~<ù;wÇÚ„'?˘	#Gé9ù$IRÕç∆¯◊Gy‡µ•ñâ¿%É:ì3∫— ≈%Á™$•%∞tbP||z±yè≥`–ı–n@®Ò$Ií§o¬D<¯‡É:îÓ›ªìûû@NN'ûx"ˇ˜ˇr:Ií§ögyﬁnøêŸÎw–≥u*˜çŒ¢w€Ü·SÌqpo∞ÿ|∆£∞{C0KHÅ>¬†k°IÁpÛIí$I¿D§••1m⁄4¶Lô¬¸˘Û©SßΩzı‚§ìN
;ö$IRçr†®îﬂøµí?øøÜíhåzIÒ‹x∆1\2®=	.9Weÿì3ˇˇ
ÛÉY›&–ˇJ8Ó
õKí$©Fâƒb±Xÿ!§™®††Ä¥¥4ÚÛÛIMM;é$I™ÊﬁYæï€',"g◊ Œ»h¡]#{“∫aùêì©Vÿ∫¶?û˚‘bÛŒ0¯–bÛDˇ;î$Iœ◊◊6Ô ë$Iíé¢-Ö¸|“^Yò@Î¥Ó>;ì”3ZÑúL5^,Î>Äi¡ 7 Ám¬Ò?ÇngBúwIí$©Ê≤ ë$IíéÇ“håÃ\œØ&/gœ¡‚„"\v|~|Z7Í%˚«pE•%∞dB∞ÿ<wﬁ°azåÄ¡◊C€˛!Üì$Ií*è?yIí$Il—¶|nøê˘9¡éÖﬁmrﬂËLz∂N9ôj¥É{Ç≈Ê”ˇ ˘ü,6Ø}øØv±π$IíjIí$©ÇÏ;X¬o¶¨‡ØÆ%É…	¸ø°«p¡Äˆƒ«E¬éßö™ f˝>~ÚSãÕõ¬Ä¬±óCΩ&·Êì$IíBb" VØ^Õ_ˇ˙WVØ^ÕÔˇ{ö7oŒkØΩFªvÌËŸ≥gÿÒ$Ií™º7ÁqÁƒ≈‰ÊpVØV‹qVÕSSBN¶kÎRòˆ,¯7DãÉYì.0Ë:Ë}æãÕ%IíTÎYÄàwﬂ}ó3œ<ì„è?û˜ﬁ{è{ÔΩóÊÕõ3˛|˛Úóø¬/ÑQí$© ⁄º˚ wN\Ãî%[ h€∏ø8;ìo”<‰d™ëb1X˚^∞ﬂc’îÚyª¡¡~ènC]l.Ií$b"~˙”ürœ=˜p„ç7“†AÉ≤˘∑ø˝my‰ëìIí$U]%•Qûö∂éﬂLY¡˛¢R‚"\yR'ÆˇvWÍ$≈áO5Mi1,y	¶=πÛÉY$Ó–bÛA˙±·Êì$Ií™ ±p·Bû}ˆŸœÃõ7oŒˆÌ€CH$IíTµÕ€∏õ[∆-dIn «∂oƒ}c≤Ë÷¢¡óºßÙ‹sûÅèA˛∆`ñP≤/
õ7Ón>Ií$©
≥ 6$77óé;6ü;w.m⁄¥	)ï$IR’SPXÃˇΩæúøÕXO,iu˘Ÿô›9˜ÿ∂ƒπ‰\© f>ˇZl^ØÙˇ!w9‘mn>Ií$©∞ Áü>7ﬂ|3œ?ˇ<ëHÑh4 á~»ˇ˛ÔˇrÒ≈áOí$)t±XåWÊq˜§≈l›sÄ1}€pÀ4≠ür:’([ñ¿ÙG`¡süZlﬁ5ÿÔ—Î<HL	7ü$IíTçXÄà˚ÓªèkØΩñ∂m€RZZJFF•••\p¡‹v€ma«ì$I
’∆ù˚π˝•EL]æÄéMÎqÔ®Lwir2’±¨}˜–bÛ7ÀÁÌèäèÆC\l.Ií$}ëX,;Ñ™Ü6∞h—"ˆÓ›Kﬂæ}È⁄µkÿëBUPP@ZZ˘˘˘§¶¶ÜGí$U≤‚“(zΩµí¬‚(IÒq\˝≠Œ\˝≠Œ§$∫‰\†¥OõÁ-fë8Ë1Ú–bÛ~°∆ì$I˙¶|}MaÛïi◊ÆÌ⁄µ;Ü$IRË>^∑ì[∆/d≈ñΩ Í‘Ñ{Fg“πY˝êì©F(,(_l^êÃÎBﬂOõw¸ÔÔ/Ií$Èàxµà≈b<ˇ¸Û\sÕ5úsŒ9å3Ê∞øæä˜ﬁ{è#F–∫uk"ë&L8ÏÒΩ{˜r›u◊ëûûNù:u»»»‡Ò«?Ïö¬¬BÆΩˆZö4iB˝˙ı;v,[∂l9Ïö60|¯pÍ÷≠KÛÊÕπÈ¶õ())9Ïö©SßíùùMrr2]∫t·©ßû˙Jüã$I™}vÔ/‚g„pŒ„”Y±e/çÎ%ÒÎÔÙÊŸ∞¸–7W∞¶‹øÕÑ7n èzÕ·€∑¡ãaÿÉñí$IRÚÒ„ˇò?˛Òèúr )¥h—ÇH$Úµükﬂæ}ÙÓ›õÀ.ªÏsÀìoºë∑ﬂ~õøˇ˝ÔtË–Å7ﬁxÉkÆπÜ÷≠[3r‰H n∏·^yÂû˛y“““∏Ó∫Î3f~¯! •••>úñ-[2m⁄4rssπ¯‚ãILL‰æ˚Ó`Ì⁄µ>ú´Æ∫ä¸„ºı÷[\q≈¥j’ä!CÜ|ÌœOí$’L±Xå	Û6qœÀKŸ±ØÄÛémÀOœÏN£zI!ßSµó∑(Xlæyà˙•ù¶›Ç˝YÁ∫ÿ\í$I:J‹"7nÃﬂˇ˛wÜV°œâD?~<£Fç*õeffrﬁyÁq˚Ì∑óÕ˙ıÎ«ôgû…=˜‹C~~>Õö5„ŸgüÂúsŒ`Ÿ≤eÙË—ÉÈ”ß3p‡@^{Ì5Œ:Î,6oﬁLã- x¸Ò«π˘ÊõŸ∂mIII‹|ÛÕºÚ +,Z¥®Ï„ú˛˘ÏﬁΩõ…ì'Q~œ(î$©vXª}∑MX»á´v –•y}ÓùEˇéçCN¶j-É5SÉ≈Ê´ﬂ*ü∑?éˇt9›≈Êí$©∆Ûı5ÖÕ?qã¥¥4:uÍT)k‡¡Lú8ëMõ6ã≈xÁùwX±bgúq ≥gœ¶∏∏ò”N;≠Ï}∫wÔNªvÌò>}: ”ßO'++´¨¸ 2d,^º∏ÏöO?«'◊|Úí$IKJ˘˝õ+Úª˜¯p’í‚∏i»1º˙£-?Ùıï√¸√„'¬ﬂFÂG$zéÅºóæ›ÜX~Hí$Iï¿#∞ƒ]w›≈›wﬂÕìO>Iù:uéÍ«z¯·áπÚ +IOO'!!Å∏∏8˛Ùß?q“I'êóóGRR6<Ï˝Z¥hA^^^Ÿ5ü.?>y¸ì«˛€58p‡s?œÉr‡¡≤∑

æŸ'+Ií™¨È´wpÎÑÖ¨Ÿ∂Äª6ÂûQô¥oR/‰d™∂
`Œ”áõo
fâı ˚–bÛFBç'Ií$’F ‚‹sœÂüˇ¸'Õõ7ßCá$&&ˆ¯ú9s*Ïc=¸√Ãò1Éâ'“æ}{ﬁ{Ô=ÆΩˆZZ∑n˝ô;6*€˝˜ﬂœ›wﬂjIíttÌ‹WƒΩØ,Â≈99 4≠üÃ#2—´’7⁄É¶Z,Ã|f?˝M˝0‡á–ÔR®Î›Dí$IRX,@ƒ%ó\¬ÏŸ≥˘ﬁ˜æ˜çó†ˇ7‡ñ[na¸¯Ò>Ä^Ωz1oﬁ<˛Ôˇ˛è”N;çñ-[RTTƒÓ›ªªdÀñ-¥lŸÄñ-[2k÷¨√û{Àñ-eè}Ú˜Ofüæ&55ıÔr˘Ÿœ~∆ç7ﬁXˆvAAm€∂˝fü¥$I™b±œœŒ·æWó≤{1ë\8†7ÈNZùƒ/È?Â-Ñiè¿¢>µÿ¸ò`±yØs!!9‹|í$Ií,@ØºÚ
Øø˛:'úp¬Q˝8≈≈≈˜Á«««çFÅ`!zbb"oΩıc«é`˘ÚÂlÿ∞ÅAÉ0h– ÓΩ˜^∂n›JÛÊÕò2e
©©©dddî]ÛÍ´Øˆq¶LôRˆü'99ô‰dPï$©¶Yµu∑å_ƒ¨µ;Ëﬁ≤˜ç…"ª]£êì©⁄â≈`ı€¡bÛ5Ôîœ;úÉ]Ns∑á$IíTÖXÄà∂m€íööZ!œµwÔ^V≠ZUˆˆ⁄µkô7oç7¶]ªvú|Ú…‹t”M‘©SáˆÌ€ÛÓªÔÚÃ3œõﬂ¸≤_~˘Â‹x„ç4n‹ò‘‘TÆø˛zƒ¿Å8„å3»»»‡¢ã.‚¡$//è€nªçkØΩ∂¨¿∏Í™´x‰ëG¯ˇÔˇqŸeóÒˆ€oÛ‹sœÒ +ØT»Á)Ií™æ¬‚Ry{|o5≈•1Í$∆s√È]πÙ¯é$∆˚"µæÇí"X<.(>∂,
fëxË9
]m≤Cç'Ií$ÈÛEb±X,Ï
◊+Øº¬√?Ã„è?Náæ—sMù:ïSN9Â3ÛK.πÑßûzäºº<~ˆ≥üÒ∆o∞sÁN⁄∑oœïW^…7‹PvÙVaa!?˘…O¯Á?ˇ…¡É2d¯√ é∑Xø~=W_}5SßN•^Ωz\r…%<¿$$$ñÂÜn`…í%§ßßs˚Ì∑Û˝Ôˇà?óÇÇ“““»œœØ∞ÇHí$Ué˜Vl„ˆó±~«~ NÎ—úªFˆ$ΩQ›êì©Z)Ãv{Ãxˆlfâı†ﬂ%0‡*h‘>‹|í$IUúØØ)l ¢Q£FÏﬂøüííÍ÷≠˚ô%Ë;wÓ)Y∏¸-IRı≥uO!˜ººîâÛÉ´[¶¶p◊»ûÈyÙˆú© œ	JèŸOC—û`Vøe∞ÿ¸ÿK°é«ßIí$	__Sÿ<K¸Ówø;Ç$I“7ç∆xv÷~9y{
Kàã¿%É;ì3é°~≤‰’ ]sµx\˘bÛf=Ç≈ÊYÁ∏ÿ\í$I™f¸iP\r…%aGê$I˙⁄ñÊpÎ¯ÖÃŸ∞Ä¨6i‹7:ã¨Ù¥pÉ©zà≈`ı[áõO-üw<©|±πwIí$I’íH-UPPPv€YAA¡Ω÷€”$IRU¥ø®Ñﬂøπí?∞ñ“hå˙…	¸‰ån\<®Òqæ`≠/QRã^äè≠ãÉY$zéÜ¡◊AÎæ·Êì$IíÙçYÄ‘Rç5"77óÊÕõ”∞a√œ=;ãâD(--!°$I“{kÈÓxi1õv ‡ÃÃñ‹9¢'-”RBN¶*Ô¿nò˝Ã|ˆ‰≥§˙ê}	º
∂3ù$Ií§
dRKΩ˝ˆ€4n‹Äwﬁy'‰4í$IG&/øêª'-ÊµEy ¥iXáüü›ìS{¥9ô™º›É“„?õº
˙]
uÜOí$IR≈≥ ©•N>˘‰≤ˇ›±cG⁄∂m˚ôª@b±7n¨Ïhí$IüQçÒÃÙu¸˙çÏ=XB|\Ñ+NË»ˇú÷ï∫I˛ëVˇEÓ¸‡ò´E„ vËŒÊÊ¡bÛÃs !)‹|í$IíéZ;v,;Î”vÓ‹I«é=Kí$ÖjaN>∑å_»¬M˘ Ùm◊ê˚Fg—£ï{ Ùb1XıL{÷æ[>ÔxÚ°≈Êß∫ÿ\í$I™,@T∂Î„?Ì›ªóîœ—ñ$I·ÿ{∞Ñ_ø±úßß≠#É)	‹<¥;ÙoGúKŒıyJä`—áõ/	fëx»,6o’;‹|í$Ií*ïH-v„ç7âD∏˝ˆ€©[∑nŸc•••Ãú9ì>}˙ÑîNí$’V±Xå◊Áq◊ƒ%‰0≤wkn;´Õ¯ÀµN¥÷OÉΩ[†~h?‚‚øÊ¿nò˝Wò˘«√õ˜˚>∏
∂≠Ï‘í$Ií™ êZlÓ‹π@"√¬ÖIJ*?ˇ8))âﬁΩ{Ûøˇ˚øa≈ì$IµPŒÆ˝‹5q1o.›
@ª∆uπgT&'ukr2Öb…Dò|3l.ü•∂Ü°øÑåë∞{ÃxÊ<E{É«¥ÇÅWCˆ%.6ó$IíjπH,ãÖB·∫Ù“K˘˝ÔOj™ÁhZAAiii‰ÁÁ˚œFí§£¨∏4 _?\Àoß¨‰@q)âÒ~xRgÆ˚vR„ø¸	TÛ,ôœ]¸Áè+ë`÷v‰Ã˙‘bÛûáõèu±π$IR·Îk
õàÙ¸-IRÂò≥a∑å[»≤º= ÙÔ–ò{Gg“µEÉêì)4—R¯]Ê·w~|ëNﬂ
õw˛∂ãÕ%Ií™__Sÿ<Kí$I°»?PÃØ^_∆?fn ÉÜuπÂÃú”/›%Áµ›˙iGV~åx˙]rÙÛHí$I™ñ,@$IíT©b±//»ÂÁ//a€ûÉ åÕNÁña›iR?9‰t™ˆn9≤ÎíÍ›í$Ií™5Ií$Uö;ˆs€Kãxo≈6 :5´«Ω£≤‘πI»…TeÏ\ã«Ÿµı[›,í$Ií™5Ií$uE%Q˛Ù˛zk%K¢$%ƒqÌ∑∫p’∑:ëú‡ís?Çi¡≤ó!˝íã#ê⁄⁄Æîhí$Ií™'Ií$U≥÷Ó‰÷ÒYπu/ «wi¬=£≤Ëÿ‘„ãjΩh),¶=gñœªúm˙¡ªø<4à}ÍùÌá˙ ƒYûIí$I˙b í$I:*vÌ+‚Å◊ñÒÔè7–§^∑üï¡Ÿ}Zâ∏‰ºV+⁄Û˛3˛yüΩŒÖA◊AÛ¡¨EOò|Û·—S[ÂG∆» œ-Ií$©Z± ë$IRÖä≈båõ≥â{_] Œ}E |∑[n⁄ùÜuìBNßPÌ›
≥ûÄè˛v≥îÜp‹–ˇJh;=2FB˜·∞~Z∞Ω~ã‡ÿ+Ô¸ê$Iít,@$IíTaVo€ÀÌ1mı ∫µ®œ}£≥8∂C„êì)T[ó¡ÙG`¡sPz0ò5Í‹Ì—ÁH˙/«°≈≈C«+%¶$Ií§ö≈Dí$IﬂXaq)èM]ÕcSWST%%1éù⁄ï+NËDRB\ÿÒÜX÷ΩÏ˜X˘F˘<Ω?æ>∏≥√;9$Ií$E í$I˙F¶≠⁄Œm±f˚> NÓ÷å{Fe“∂q›êì)•≈∞xL{ÚF†«Y0Ëzh7 Ãtí$IíjIí$}-€˜‰ﬁWñ2~Ó& ö5HÊŒœjÂíÛ⁄®∞ Ê<3áÇú`ñP˙~^M:áõOí$IR≠c"Ií§Ø$çÒ‹«πˇµe‰(&Åã∂ÁáCjJbÿÒTŸÚs`∆c0Á8XÃÍ5áW¬±óC]˜øHí$I
áà$Iíéÿä-{∏u¸B>Z∑ÄåV©‹7&ã>mÜLïoÛº`±˘‚Ò-	fÕ∫√†k!Î\HL	5û$Ií$YÄHí$ÈK(*Â·∑WÚƒ{k(â∆®õœçßw„˚É;êÔíÛZ#ÖUo¬ÙáaÌ{ÂÛé'¡‡AÁS!Œˇ$Ií$U í$I˙Ø¶.ﬂ Ì/-b„Œ úû—ÇªFˆ§M√:!'S•).ÑÖœ¡ÙGa€≤`âáÃ±0¯:h’;‹|í$IíÙ9,@$IíÙπ∂ÚÛóóÚÇ\ Z••p◊»ûÈŸ2‰d™4˚w¬GÅYO¿æ≠¡,©˚}p§•áOí$Ií˛Ií$¶4„ŸôÎypÚrˆ,!.óﬂëNÔF˝dˇ¯X+ÏX3˛ sˇ%¡ù?§¶√¿´!˚bHI7ü$Ií$Çï$IRô≈õÛπe¸"Êo‹@ÔÙ4ÓùEfõ¥pÉ©rlò	”ÇeØ ±`÷™7∫zéÇ¯ƒ0”Ií$I“Wb"Ií$ˆ,·woÆ‡…◊QçQ?9ÅõÜ√˜∂'>.v<M—RXˆ2L{rfïœª	ˆ{t8"˛7 Ií$©˙± ë$I™Â¶,Ÿ¬ù/-bs~! √≥Zq«àZ§¶ÑúLGU—æ‡à´è¬Æu¡,>	züØÖÊ›Cç'Ií$Iﬂîà$IR-µy˜Óö∏ò7ñl ΩQ~qv&ßtor2U{ÚÇ•Ê˝
w≥:ç‡∏+‡∏@É°∆ì$Ií§äb"IíTÀîîFyz˙z~Û∆rˆïí·ä;Ò?ßv•NR|ÿÒt¥l]
”ÅœAiQ0k‹	^}.Ä§z·Êì$Ií§
f"IíTã,»ŸÕœ∆-dÒÊ ˙µoƒΩ£3Èﬁ25‰d:*b1X˚n∞ﬂc’îÚy€Å¡~ècÜAú•ó$Ií§ö…Dí$©ÿSXÃØﬂX¡3”◊çAjJ?÷ÉÛémKúKŒkû“bX<¶=yÉY$zåÄA◊C€„¬Õ'Ií$Iï¿Dí$©ã≈bº∂(èª'-fK¡A FıiÕ≠√3h÷ 9‰t™pÖ˘0˚iò˘8l
fâu°ÔE0jh‹1‹|í$IíTâ,@$Iíj®ç;˜s«Kãxg˘6 :4©À=£≤8°k”êì©¬Ìﬁî≥üÜ¢=¡¨~Ë%{‘mn>Ií$I
Åà$IRS\Â/¨ÂwoÆ†∞8Jb|Ñ´OÓÃ5ßt!%—}5 Êπ¡~è≈„!VÃöıˆ{d}ºÀGí$IRÌe"IíTÉÃ^øã[«/dY^p¿Äéçπwt]ö◊9ô*L4
+ﬂÄÈè¿∫˜ÀÁOÜ¡?Ç.ßBƒΩ.í$Iíd"IíT‰Ô/ÊÅ…À¯Á¨ 4™õ»-√zpNøt"æ^3¬Ç≈«ˆ¡,.2«¬†Î†UØpÛIí$IRc"IíTç≈b1&ŒﬂÃ/^^¬ˆΩE |ß_:?÷É∆ıíBNß
±o|¸òıÏˆπêú
˝æÆÇ¥6°∆ì$Ií§™ Dí$©öZ∑}∑ø¥à˜Wn†s≥z‹7:ãùöÑúLb«jò˛(Ã{J≥¥∂0jË{§§ÜõOí$Ií™8Ií§jÊ`I)OºªÜáﬂYEQIî§Ñ8Æ?•Wû‹â‰óúWk±lú	”ÜeØ ±`ﬁ™æ2FAºÑó$Ií§#·OOí$I’»å5;∏u¸BVo€¿â]õÚã≥3È–¥^»…ÙçDKaÈ§†¯ÿÙq˘º€–†¯hºãÕ%Ií$È+≤ ë$I™vÓ+‚˛WóÚ¸Ï ö÷O‚ˆ≥2ŸªµKŒ´≥É{aﬁ?Ç£ÆvØfÒ…–˚¸`±y≥n·Êì$Ií§jÃDí$©
ã≈bº0;á˚^] Æ˝≈ \0†7ÈNZ›ƒê”Èk€ì3ˇ,7/ÃfuCˇ¿q?Ä˙Õ¬Õ'Ií$I5Äà$IRµjÎ^nøêôkw–ΩeÓùEøˆçBN¶ØmÀò˛,x¢A°E„Œ0ËZË˝]H™n>Ií$I™A,@$Ií™ò¬‚R˛Œ*{w5≈•1R„∏·¥n\vBG„„¬éßØ*É5SÉ˝´ﬂ*ü∑Ï˜Ëv&ƒ˘ÔUí$Ií*öà$IRÚ¡ Ì‹6a!ÎvÏ‡€›õs˜»û¥mÏù’NI,[≥HÙÈ«ÜõOí$Iíj8Ií§*`€ûÉ‹Û ^ö∑Ä©…‹5¢'C3[∫‰º∫9∞f?3á=π¡,±d_ØÜFB'Ií$Iµáà$IRà¢—ˇ˙h#º∂îÇ¬"∏dP~rF7§∏‰ºZŸµ>(=Ê<E{ÉY˝ñ0‡ápÏ•P«›-í$IíTô,@$IíB≤,ØÄ[«/bˆ˙] d∂IÂæ—YÙJon0}5õÊ«\-y	b•¡¨yFpÃUÊXHH7ü$Ií$’R í$IïÏ@Q)øk%~%—ıí‚˘…«pÒ†ˆ$∏‰ºzàFaÂÎAÒ±˛√ÚyßS`u–˘TË2Ií$I
ïà$IR%zgŸVni9ª 0§gÓŸìViuBN¶#R| Êˇ¶?
;V≥∏D»:]-≥¬Õ'Ií$I*c"IíT	∂r˜§≈º∫0Ä6Îp˜»ûúñ—"‰d:"˚∂√GÜYÇ˝€ÉYrZ∞€c¿!µu∏˘$Ií$Iüa"IítïFc¸}∆z~ı˙rˆ,!>.¬e«w‡«ßu£^≤´Ú∂ØÓˆòˇO()fiÌ`–5–˜{ê‹ ‹|í$Ií§/‰O›í$IG…¢M˘‹:~!ÛsÚË”∂!˜çŒ"£uj»…Ù_≈b∞az∞ﬂc˘k@,ò∑Œõ˜	Ò˛1Zí$Ií™:rì$I™`{ñõ7V‘¥µDc– 9Åˇ7Ù.–û¯8cWY•%∞tbP|lûS>?f∫⁄v±π$Ií$U# í$IËı≈y‹5q1π˘¡qIgıj≈ge–<5%‰d˙B˜¿‹ø√å?¿Ó¡,!z7Xlﬁ¥k∏˘$Ií$I_ãà$IRÿ¥˚ wæ¥ò7ón†m„:¸‚ÏLæuLÛêìÈlÜôÑŸÖ¬‡ò2Í6Å˛W¬qW@Ω¶·Êì$Ií$}# í$Iﬂ@Iiîß¶≠„7SV∞ø®îÑ∏Wû‘âÎø›ï:IÒa«”Á…[”ÅÖ/@¥8ò5È‹Ì—˚ªêX'‹|í$Ií§
a"IíÙ5Õ€∏õ[∆-dIn «uhƒΩ£≥Ë÷¢A»…Ù±¨~;ÿÔ±ÊùÚy˚„É˝›ÜB\\x˘$Ií$IŒDí$È+*(,Êˇ^_Œﬂf¨'É¥:â‹2¨;ﬂÈ◊ñ8óúW-%E∞Ëòˆl]Ã"qê1
_m˙ÖOí$IítÙXÄHí$°X,∆+s˘˘§%l›sÄ1}€pÀ4≠ür:Ê¿.¯¯Ø0Î	ÿìÃÎAøK`¿U–®}∏˘$Ií$IGùà$I“ÿ∏s?∑MXƒª+∂–©i=Óï…‡.. ÆRv≠Éè¡úøAÒæ`÷†UPzÙ˚>‘ib8Ií$IRe≤ ë$I˙/äK£¸È˝5<Ù÷J
ã£$≈«qÕ)ùπÍ‰Œ§$∫‰º »ô”Ç•!f-2É˝ôc!!)‹|í$Ií§Jg"IíÙ>^∑ì[∆/d≈ñΩ Í‘Ñ{Fg“πY˝êì	ÄhVºÏ˜ÿ0≠|ﬁ˘‘`øGßS ‚NIí$I™≠,@$Ií˛√Ó˝E<⁄2˛ı—F ◊K‚∂·=›∑_P_Òò˜,Ã¯ÏXÃ‚!Î;0ËZhôn>Ií$IRï`"IítH,c¬ºM‹ÛÚRvÏ+‡ºc€Ú”3ª”®ûG(ÖnÔ6¯Ëœ—ü`ˇé`ñí«^˝©≠¬Õ'Ií$I™R,@$IíÄ5€ˆr˚Kã¯pU¬z◊Êıπwt˝;69ôÿæ¶?Û˛	•ÉY√v0ZË˚=HˆH2Ií$I“gYÄH™6J£1f≠›…÷=Ö4oêBˇéçâèÛ(IﬂÃ¡íRü∫ÜGßÆ¢®$JrB?:µ+?8±I	qa«´Ωb1Xˇa∞ﬂc≈kÂÛ6˝`ı–}ƒ˚GYIí$I“ÛßFI’¬‰Eπ‹=i	π˘Öe≥Vi)‹9"É°ôy"ÈÎôæz∑NX»öm˚ 8©[3~qvO⁄7©r≤Z¨¥ñLÓ¯ÿ<˜–0«äèv]l.Ií$I:" í™º…ãrπ˙Ôsà˝«</øê´ˇ>á«æóm	"È+Ÿ±˜ ˜æ∫îqs6–¨A2wúï¡YΩZπ‰<,˜¿úg`∆„êø!ò%§@üÇ£Æöv	7ü$Ií$©⁄± ëT•ïFc‹=i…g ÄÓû¥Ñ”3Zzñ§/ã≈x˛„Ó{m)ª˜â¿Ö⁄q”êÓ§’I;^Ìîø	f>≥üÜÉ˘¡¨nSË%w9‘kn>Ií$IRµe"©JõµvÁa«^˝ßêõ_»¨µ;‘πIÂìTÌ¨‹≤á[«/b÷∫ù toŸÄ˚«d—∑]£êì’RyÉ˝ã^ÄhI0k⁄]ΩŒÉƒ:·Êì$Ií$U{ í™¥≠{æ∏¸¯:◊I™}
ãKy¯Ìï<ÒﬁäKc‘IåÁÜ”ªrÈÒIåw…y•ä≈`’[0˝aX3µ|ﬁ˛Ñ`øG◊3 Œ'í$Ií§äa"©Jkﬁ •BØìTªº∑b∑MXƒÜù˚8≠GsÓŸìÙFuCNVÀîÑÖ/ãÕ∑.	fëxË9
]m≤Cç'Ií$I™ô,@$Ui˝;6¶UZ ÉZ¶•–øc„ &©J€∫ßê_ººîIÛ7–25ÖªFˆdHœ.9ØL˚w¬Ïø¬Ã?¬ﬁ-¡,©>d_ØÇÜÌ¬Õ'Ií$I™—,@$UiÒq.‹Å˚^[ˆπè«Ä;Gd∏ ] —håggm‡óìó±ß∞Ñ∏\2∏?9„Í'˚«ûJ≥s-ÃxÊ˛äÉªoh–:(=≤/Å:Cç'Ií$I™|%@RïVçÒ ¬\ R„(,éˆxvªÜÕlF4IUÃ“‹nøêπvê’&ç˚«dëŸ&-‹`µ…∆èÇ˝K'AÏ–˜ÎY¡~èû£!!)‹|í$Ií§Z≈DRïˆÏÃıÃœ…ßAJo‹pÎ∂ÔgÎûBïrÀ¯ÖÃŸ∞õ∑óm·€›[ÑURHˆï˚7WÚÁ÷RçQ?9Åˇ=£Í‡›aï!Z
À_Öiè¿∆ÂÛ.ß≈G«ì¡c«$Ií$I!∞ ëTem›S»ÉØ/‡¶!«–*≠≠“Íî=æv˚>˛¯ﬁnü∞òÅ76°níﬂ“§⁄Ê≠•[∏„•≈l⁄} Ä33[rÁàû¥LK	9Y-P¥Ê?”ÖùkÇY|dùÉÆÖ·Êì$Ií$’zæZ(© ∫Ôï•Ï),°Wzhˇô«ˇÁ¥Æºº óMªª7WrÀ∞!§îÜº¸BÓö∏ò…ãÛ h”∞ø’”ª¡*√ﬁ≠0ÎO—ü·¿Œ`ñ“éª˙_	ZÜOí$Ií§OXÄH™í>\µù	Û6Å{Ge}Ó16uì∏gT&ó>ı˘`-g˜iMœ÷ûı/’d•—œL_«ØﬂX¡ﬁÉ%ƒ«E∏‚ƒé¸œ©]ΩÏh€∂¶?Ûˇ•ÉY√ˆ0Ë:Ë{!$’7ü$Ií$Iˇ¡W
$U9KJπ}¬" .ÿû¨Ù/.5NÈﬁú·Y≠xea.∑å_ƒ∏´{ÊøTC-Ã…ÁñÒY∏)ÄæÌrﬂË,z¥J9Yã¡∫`⁄√∞ÚıÚy˙q¡~èÓgA\|x˘$Ií$I˙/,@$U9OºªÜ5€˜—¨A2?rÃó^«àﬁ[±ç˘wÛèôÎπxPá£RR•ŸSXÃØﬂX¡3”◊çAÉî~zfwæ{\;‚,<èé“bXÚL{rÁF†˚p¸#h7 ‘xí$Ií$	IU ˙˚x¯ùU ‹~V©)â_˙>-RS¯gvÁˆ	ãxpÚrŒ»hÈd©à≈bºæ8èª&.!Ø†ÄëΩ[s€Y=hﬁ¿ØÒ£¢∞ Ê<3ÉÇú`ñP'8‚j‡5–§s∏˘$Ií$I˙
,@$U±Xå;^ZLQIî∫4eDØVG¸æˆo«ã≥sò∑q7wOZÃcﬂÎwìJ:⁄rvÌÁŒóÛ÷≤≠ ¥oRó_úù…I›öÖú¨Ü œÅôè√Ïß·`A0´◊˙ˇéΩÍ5	7ü$Ií$I_Éà§*„µEyºªbIÒq¸¸ÏûD"G~¥M\\Ñ˚«dq÷√⁄¢<ﬁ\≤Ö”2Z≈¥íéÜ‚“(O~∞ñﬂΩπí≈•$∆G∏Í‰Œ\{JR›5Q·rÁ√¥G`Ò8àñ≥¶«¿‡Î Î\HÙNIí$IRıe"©JÿSXÃ›ìpı∑:”©Y˝Ø¸=Z•r≈â˘„ªk∏s‚bunBΩdøÕI’≈úª∏e‹BñÂÌ†«∆‹7:ì.ÕÑú¨Üâ≈`’õ¡~èµÔïœ;ú,6Ôr:ƒ≈ÖóOí$Ií§
‚+Éí™ÑﬂNY…ñÇÉthRó´øııœòˇüSªÚ Ç\rv‡woÆ‡÷·òR“—ê†ò'/„ŸYà≈†a›Dn÷ÉÔÙKˇJwÇÈKîÑœ¡ÙG`€≤`âáÃ10Ë:h›'‘xí$Ií$U4I°[¥)üß¶≠‡Ágg~£cnÍ&%ãQô\˙◊èxÚ√uú›ßôm“**™§
ã≈ò¥ óüOZ¬ˆΩõùŒ-√∫”§~r»Èjê˝;·„ø¿Ã'`_∞SÖ§–Ôp4ln>Ií$IíéI°äFc‹6a—ú’´UÖ,8>ÂòÊÔ’äW‰rÀ¯ÖåøÊx‚„¸-r©*Yøc∑MXƒ˚+∑–©Y=Óï≈†Œ.€Æ0;◊¿Ù?¿º@Ò˛`ñ⁄^ŸCäÂ∞$Ií$©f≥ ë™~¥ÅywS?9Å€œ™∏„™Ó<+É˜VlcAN>õæéÔﬂ±¬û[“◊WTÂâ˜VÛ€´8X%)!éÎNÈ¬OÓDrÇKŒ+ƒ∆Y¡~è•/±`÷≤˛ÙÒâa¶ì$Ií$©“XÄH
Õ∂=˘Âk¡9Ù?9£-RS*Ïπõß¶pÛ–Ó‹6aˇ˜∆
Üd∂§UZù
{~I_›¨µ;πe¸BVm›¿Ò]öpœ®,:6≠r≤ Z
À^ÅiCŒ¨Úy◊3Ç˝O˜©Hí$IíjI°πˇ’•ñêŸ&ïã∂ØÁø†;^úì√‹ªπ{‚ø®_ÖI_n◊æ"Óm)œ}ú@”˙I‹6<É≥˚¥v…˘7U¥Ê=”Ö]¡.%‚ì†◊yAÒ—º{∏˘$Ií$I
ëà§PL[Ωùqs7â¿Ω£≤Hàè´è·˛1Yúı–L^ú«î%[8=£EÖIü/ã1nŒ&Ó}u);˜›˛Ì¯È–Ó§’ı¶odœòıD∞‹¸¿Æ`Vß{9Ùø¯ΩNí$Ií$IïÆ®$ Ìp·ÄvÙn€®}¨Ó-Sπ‚ƒN<˛ÓjÓ|iÉ;7°^≤ﬂ˙§£mı∂Ω‹6~”◊Ï ‡ò∏wt&«vhr≤jnÎRò˛,xJÉRâFa–µ–ÁHÚ81Ií$Ií>·´Äí*›üﬁ_√Ím˚hZ?âõÜ˝„Y˛Á‘Æº≤p3w‡7SVTË≤u©∂*ç∆òµv'[˜“ºA
˝;6&>.Baq)èM]ÕcSWST%%1éˇ9µWúÿëƒ£pßW≠ã¡⁄˜Ç˝´¶îœ€éπÍ>‚\ /Ií$I“≤ ëT©6ÏÿœCo≠‡∂·§’9˙«‡‘IäÁggÚ˝ø~ƒ_?\ÀËæm»lìv‘?ÆTSM^îÀ›ìñêõ_X6kïñ¬y«∂Â•˘õYª} ﬂ:¶ø8;ì∂çÎÜµz+-Ü≈„a⁄Cê∑–0=F¿‡Î°mˇP„Ií$IíT’YÄH™4±Xå;'.‚`Iî¡ùõpvü÷ïˆ±øuLsFÙnÕ§˘õ˘Ÿ∏ÖL∏ˆx‚„\æ,}UìÂrıﬂÁ˚èyn~!ø;Tn6oêÃù#z2,´•KŒøé¬|ò˝4Ã|
6≥ƒ∫–˜{0jh‹)‹|í$Ií$U í*ÕÎãÛxg˘6„#¸¸ÏÃJaÙˆ≥z0u˘Vn ÁôÈÎ∏Ù¯éï˙Ò•ÍÆ4„ÓIK>S~|Z›§x^ø·$’M™¥\5∆ÓçAÈ1˚i(⁄ÃÍ5áWÀÕÎ∫?Eí$Ií§Ø¬√∏%UäΩK∏{“ Æ:π3]ö◊ØÙÕ§”3Éù#ˇ˜˙rrÛTz©:õµvÁa«^}û˝E•,À›SIâjàÕÛ‡ÖÀ·˜ΩÉÁE{†Yw˘‹∞N∫…ÚCí$Ií§Ø¡;@$UäﬂMYAn~!Ì◊Â⁄S∫Ññ„ª«µ„≈Ÿ9ÃŸ∞õª&.ÊèZ©:â≈b|¥nÁ]ªuœ/ID£¡BÛi√∫˜ÀÁOˆ{t9<>Lí$Ií§oƒD“Q∑4∑ÄøN[¿›g˜$%1>¥,qqÓ”ã·ΩœÎã∑∆‚<ŒËŸ2¥<RU∑y˜∆œ›ƒ∏99¨ﬁ∂ÔàﬁßyÉî£ú™+.ÑˇÜÈè¬ˆÂ¡,.zéÅ¡◊A´ﬁ·Êì$Ií$©± ëtTE£1nøê“håaY-9ÂòÊaG‚òñ∏Ú§N¸aÍjÓú∏ò¡]öR?Ÿoá“'ˆï0yQ/Œ…a⁄Íƒ-˝HNàâD(,é~Ó˚EÄñi)ÙÔËqMü±o|¸òıÏ€ÃíS°ﬂ%0‡*HK7ü$Ií$I5êØ¯I:™˛˝ÒFÊlÿMΩ§xÓ8´gÿq \ˇÌÆºº ó;˜Ûõ7Vp«àå∞#I°äFcÃXªÉgo‚µEπÏ/*-{¨«∆úìùŒôY-˘p’vÆ˛˚Ä√ñ°rX”ù#2àèÛË¶2;Vw{Ã{JÌJMáÅWCˆ≈êín>Ií$Iíj0IGÕéΩy‡µe ‹pz7Z¶UùcqÍ$≈ÛãQô\Ú‰,ûö∂ñ—}€êïûv,©“≠ﬁ∂óÒs61~Ó&6Ì>P6oﬂ§.c˙¶3&ªm◊-õÕl≈cﬂÀÊÓIK[àﬁ2-Ö;Gd04≥U•ÊØíb1ÿ83ÿÔ±Ï ™¢VΩaè „làO5¢$Ií$IµÅà§£Ê˛◊ñë†ò≠R˘˛‡a«˘åìª5cdÔ÷Lúøôüç_¿Ñké'!>.ÏX“Q∑{ì‰Ú‚ÏÊm‹]6oêí¿YΩZ36ª˝⁄7"ÚK∏áf∂‚ÙåñÃZªì≠{
iﬁ 8ˆ™÷ﬂ˘-Ö•ì`˙#êÛQ˘ºÎê`±yá\l.Ií$IR%≤ ëtTÃ\≥ÉfÁâ¿Ω£3´l±p€Y=ò∫|+ã6ÃÙı\vB«∞#IGEqiîwóo„≈99ºµt+E•¡è¯∏'um òÏtNœhAJb¸=_|\ÑAùõÕ»’«¡Ω0Ô0„∞k]0ãOÜﬁÁ¡†Î†Ÿ1°∆ì$Ií$©∂≤ ëT·äJ¢‹6a Á◊éÏvçBNÙ≈ö7H·ßgˆ‡ñÒ˘ıÀöŸí÷ÎÑK™±Xå≈õxqNÁmf«æ¢≤«∫∑l¿9˝“Ÿß5ÕTù„È™ï=y¡RÛè˛ÖªÉYù∆p‹–ˇPøy®Ò$Ií$I™Ì,@$U∏ø|∞ñï[˜“§^7≠˙ø˘|˛qm7'áè◊Ô‚Œâã˘”≈«ÜI˙F∂2aﬁ&^úΩâÂ[ˆîÕõ÷O‚Ï>mõùNFkóom[ñãÕ>•áJ•∆ù`–µ–˚H™˚ﬂﬂ_í$Ií$U
Ij„Œ˝¸˛≠ ‹2¨Î&ÖúËÀ≈≈E∏oL√~ˇ>Sñl·ı≈yÈŸ2ÏX“WRX\ ÎãÛ7gÔØ‹FÙ–ﬁÌ§Ñ8Nœh¡ÿÏ6ú‘µYï=éÆ ã≈`Õ‘`ø«™7ÀÁm˚=é9‚éÏ¯0Ií$IíT9,@$U®ª'-¶∞8 Äéçì›&Ï8G¨[ã¸‰N<˙ŒjÓ|i1«wiJ˝døE™jã≈b|¥n/ŒŒ·’ÖπÏ9XRˆXøˆçõùŒ¨V§’M1e5WRã«¡¥G`À¬`âÉ#`–ı–ˆ∏pÛIí$Ií§/‰´{í*ÃãÛxsÈV„#‹;:ìH$v§Ø‰˙owe“¸\6Ï‹œØﬂXŒù#zÜI˙\vÏÁ≈99åõõ√∆ù Êm÷alvFgß”±iΩ÷ v√Ïß`ÊaœÊ`ñX˙^ØÜ∆√L'Ií$IíéÄà§
±Ô`	wM\¿NÏDóÊBNÙ’•$∆sœ®L.~rOO[«ËæmËïﬁ0ÏX Ö≈º∫ óÁ‰—∫]eÛzIÒÀj≈ÿ~ÈÙÔ–ò∏∏ÍU<V9ª7¿å«aŒ”P¥7ò’o~˝.Ö∫ç√Õ'Ií$Iíéòà§
Ò–[+Ÿú_Hz£:\ˇÌÆa«˘⁄NÍ÷å≥˚¥Ê•yõπe¸B&\sº;öí“(ÔØ⁄Œ∏9õxcqK¢ D"pBó¶åÕNgHœñ‘Ir˜ƒ7∂iN∞ﬂcÒàï≥f=Ç˝YÁ@Br®Ò$Ií$I“Wg"È[ñW¿_>X¿œœÓYÌ_åΩ˝¨¶.ﬂ∆¢M<5mWúÿ)ÏH™eñÂ‚Ï&Ã€Ã∂=ÀÊ]ö◊glv:£˚∂°eZJà	kàhVæÏ˜XˇA˘º”∑Ç‚£Û©A€$Ií$Ií™%IﬂH4„∂Òã(â∆“≥ﬂÓﬁ"ÏHﬂX”˙…¸ÏÃÓ¸t‹B~3egfµ¢M√:a«R∑}ÔA^ö∑ôgÁ∞$∑†lﬁ®n"g˜i√òÏ6dµI´vªu™§‚BXØ†¯ÿ±2ò≈%@Ê90ËZh’+‹|í$Ií$©BXÄH˙F^òù√«ÎwQ7)æF-?˜ÿ∂eªÓ|i∫¯X_xVÖ+,.ÂÌe[yqvSWl£4 1>¬∑ª7gLv:ß”ú§èa´˚v¿GÜYO¿˛Ì¡,9é˝>Ùˇ!§µ	5û$Ií$I™X íæ∂ù˚ä∏ˇµ• ‹pZ7Z◊†ª$‚‚"‹7:ãaΩœõK∑Ú˙‚-Õlv,’ ±Xå9v3nNìÊo¶†∞§Ï±ﬁm26ªgıjM„zI!¶¨a∂ØÇè¬ºg°§0ò•µÖÅ◊@ˆEê‹ ‹|í$Ií$È®∞ ëÙµ=⁄RvÌ/¶{À|ˇ¯a«©p][4‡á'uÊëwVq◊ƒ≈ﬂ•	R√é•j*g◊~&Ã›ƒ∏9õX≥}_Ÿºej
£≥€06ª]ö˚B|Öâ≈`√Ù‡ò´ÂØ¡›5¥ÓÏ˜Ëq6ƒ˚« Ií$Iíj2ÚóÙµ|ºn'œ}ú¿=£2IåØôGÙ\˜Ì.ºº`3ÎvÏÁ◊o¨‡Æë5Áò/}{ñ⁄¬\∆ÕŸƒÙ5; Êu„93≥%c≤”‘π	ÒqØVaJK`ÈDò˛lö]>ÔvfP|¥ÏbsIí$Iíjâö˘ä•BÛﬁ{Ô1bƒZ∑nM$a¬Ñ	á=âD>˜Ø_˝ÍWe◊Ï‹πì/ºê‘‘T6l»Âó_ŒﬁΩ{{ûp‚â'íííB€∂my¡?ìÂ˘Áüß{˜Ó§§§êïï≈´ØæzT>Á⁄®∏4 ≠„p˛qm9∂C„ê=)âÒ‹3*ÄßßØc˛∆›·RïWçÒ¡ Ì‹Ôywœõ‹Ù¬Ç≤ÚcPß&¸ﬂwzÛ—mßÒõÛ˙pB◊¶ñÂ‡^òÒ8<‹^∏4(?‚ì°ﬂ˜·⁄è‡ÇAá„-?$Ií$I™EºDjﬂæ}ÙÓ›õÀ.ªå1c∆|ÊÒ‹‹‹√ﬁ~Ìµ◊∏¸ÚÀ;vlŸÏ¬/$77ó)S¶P\\Ã•ó^ ïW^…≥œ>@AAgúqßùvè?˛8.‰≤À.£a√Ü\yÂï Lõ6çÔ~˜ª‹ˇ˝úu÷Y<˚Ï≥å5ä9sÊêôôyˇ	‘O~∞ñÂ[ˆ–∏^7Ìvú£ÓÑÆM›∑„Án‚g„2Ò∫„I®°wºËÎ[µu//Œ…a¬‹M‰ÊñÕ;6≠«ÿÏ6åÍ€ÜÙFuCLXC‰¬¨?¬«OBa~0´€é˚w‘on>Ií$IíöH,ãÖB5S$a¸¯Òå5ÍØ5j{ˆÏ·≠∑ﬁ`È“•ddd—GqÏ±«0yÚdÜFNN≠[∑Ê±«„÷[o%//è§§`IO˙S&Lò¿≤eÀ 8ÔºÛÿ∑o/ø¸rŸ«8p }˙Ù·Ò«?¢¸§••ëüüOjjÍ◊˘GP#m⁄}Ä”~˝.äKyú^ú{l€∞#UäÌ{rÍØﬂ%ˇ@1∑Ô¡'v
;í™Ä]˚äò¥`3/ŒŒa~N~Ÿ<5%ÅΩ[3∂_:}€6$‚]oÀ‚`ø«¬Á!ZÃwÜA◊BÔÔBíeì$Ií$ÖÕ◊◊6Ô Qh∂lŸ¬+Øº¬”O?]6õ>}:6,+? N;Ì4‚‚‚ò9s&£Gèf˙ÙÈút“IeÂ¿ê!C¯Â/…Æ]ªh‘®”ßOÁ∆o<Ï„2‰3GrÈ´ª{‚bó“øCcŒ…N;N•iZ?ô[ÜuÁÊÚÎ7V04≥•øÕ_KïDyg˘V∆Õ…·Ìe[).~è >.¬∑∫5cløtæ›Ω9)âÒ!'≠Åb1XÛL{Vø]>o7_Ï˘àÛÓ,Ií$Ií∞ Qhû~˙i4hpÿQYyyy4oﬁ¸∞Îh‹∏1yyye◊tÏÿÒ∞kZ¥hQˆX£Fç»ÀÀ+õ}˙öOû„Û<xêÉñΩ]PPı>±ÏÕ%[xc…‚"‹3:ì∏Z∂ª‡;˝⁄Ú‚ÏMÃZ∑ì;_ZÃü/9÷ﬂÏØ%b±7ÂÛ‚Ï&ŒﬂÃÆ˝≈eèılù òÏtŒÓ”ö¶ıìCLYÉï¡¢É≈Ê[Ç˝CD‚ „lt=§˜7ü$Ií$I™í,@ö'ü|í/ºêîîî∞£ pˇ˝˜s˜›wá£ ⁄_T¬ùp˘âÈ÷¢A»â*_\\Ñ{Gg2Ï°˜ykŸV^_ú«–ÃVa«“Qîó_»¯πõ7'áï[˜ñÕõ5Hftﬂ6å…nC˜ñﬁ¬{‘ÿ≥ˇ
3ˇ{ÌêJ¨Ÿ√¿´†Qá0”Ií$Ií§*ŒD°xˇ˝˜Yæ|9ˇ˛˜øõ∑lŸí≠[∑6+))aÁŒù¥lŸ≤Ïö-[∂vÕ'oŸ5ü<˛y~ˆ≥üvlVAAm€÷é˝G‚·∑W±i˜⁄4¨√ˇú⁄5Ï8°È⁄¢Wù‹ôáﬂ^≈ù3∏KSRS√é•
¥ø®Ñ7o·≈99|∞j;ül JNà„åû-ì›Üª4%!ﬁ£ñéö]Îa∆c0Á(ﬁÃÍ∑Jè~ﬂá:çBç'Ií$Ií™Ö‚/˘˝˙ı£wÔﬁáÕƒÓ›ªô={6˝˙Göº˝ˆ€D£QPvÕ≠∑ﬁJqq1ââ¡œS¶L·òcé°Q£Fe◊ºı÷[¸¯«?.{Ó)S¶0h–†/ÃîúúLr≤«◊|û[ˆß˜÷ p◊»û‘M™›ﬂ:Æ=•ìÊof›é˝¸˙ıÂ‹}vfÿëÙE£1fÆ›…∏99º∫0ó}E•eèıÔ–ò1Ÿm÷´ïe◊—ñ3¶?K^ÇX4ò5ÔÏ˜»<í˛˚˚Kí$Ií$}JÌ~SnÔﬁΩ¨Zµ™ÏÌµk◊2oﬁ<7nLªvÌÄ‡ŒäÁüû_ˇ˙◊üyˇ=z0tËP~É¯„èS\\Ãu◊]«˘ÁüOÎ÷≠∏‡Ç∏˚Óªπ¸ÚÀπ˘ÊõY¥høˇ˝Ô˘Ìo[ˆ<ˇÛ?ˇ√…'üÃØ˝kÜŒø˛ı/>˛¯cûx‚â£¸O†Êâ≈b‹6a%—ßıh¡È-æ¸ùj∏îƒxÓù≈Öû…33÷3:;ù>mÜK_√⁄Ì˚?'áqs7ë≥Î@Ÿºm„:åÈõŒòÏ6¥oR/ƒÑµ@4
+&ãÕ7L+üw˛6∫.¯ªªv$Ií$I“◊â≈>9‹C˙Ê¶Nù )ßúÚô˘%ó\¬SO=¿O<¡è¸crssIKK˚Ãµ;wÓ‰∫ÎÆc“§Iƒ≈≈1vÏXzË!Í◊Ø_vÕÇ∏ˆ⁄k˘Ë£èh⁄¥)◊_=7ﬂ|ÛaœÛ¸Ûœs€m∑±n›:∫vÌ É>»∞a√é¯s)(( --ç¸¸|RSkÔˇ/ÃŒ·üüOùƒx¶‹xÈçÍÜ© ∏ÒﬂÛ7w=Z•2È∫„=©ö»?PÃÀ63nŒ&fØﬂU6oêú¿^≠ìùŒqπ‡˛h+> Ûˇ	”ÖáäÛ∏D»˙∫Zzgï$Ií$Uwææ¶∞YÄH_¿o–∞k_ß˛Ê]vÓ+‚ßgvÁ™ì;á©JŸ±˜ ß˛Ê]vÔ/Ê÷a=¯¡Iù¬é§/PRÂΩï€xqˆ&¶,›BQIpºR\NÏ⁄å±˝“9#£)âÒ!'≠ˆnÉè˛˝	ˆÔf…ipÏ•0‡áê⁄:‹|í$Ií§
„Îk
õG`I˙Bææåù˚äË÷¢>óü–1Ï8UNì˙…‹rf˛ﬂã¯Õîúô’“;d™ò%õxqN/Õ€ƒˆΩEeÛcZ4`lø6ú›ß-RSBLXãl_	”Å˘ˇÇí¬`÷∞º˙~íÑõOí$Ií$’8 í>◊Ïı;˘Á¨ç ‹3*ãDèw˙\ﬂ96ùÊ‰0kÌNÓxi1π‰XèN
Ÿ÷=ÖLú∑ôfÁ∞,oOŸºIΩ$FˆiÕÿÏtz∂NıﬂSeà≈`˝¥`ø«ä◊ Á≠≥aı–c$ƒ˚GIí$Iítt¯™É§œ()çrÎ¯E |ß_:˝;69Q’âD∏otg˛˛=ﬁ^∂ï◊Â1,´Uÿ±jù¬‚R¶,Ÿ¬∏99º∑r;•—‡t«§¯8NÌ—ú±ŸÈú|L3ãºä- çΩ[†~h?‚!VZK_
äèÕsΩCéÉØÉvÉ\l.Ií$Iíé:IüÒ‘¥u,À€C√∫â¸lXè∞„Ty]ö◊ÁÍou·°∑Vr◊ƒ≈ú–µ)©)âa«™Òb±≥◊Ô‚≈99ºº ó=Ö%eèım◊ê1ŸÈåË’äÜuìBLYC-ôìoÜÇÕÂ≥‘÷p⁄]∞oÃxÚ7ÛÑËsºöv	%Æ$Ií$I™ù,@$fÛÓ¸f 
 ~vfw◊Û≈„#qÕ∑:3i˛f÷nﬂ«ˇΩæúüüùv§k„Œ˝åõ≥âqssXøcŸºuZ
c≤”ù›ÜŒÕÍáò∞Ü[2ûªà>/ÿ„Æ,ªnSËˇ8Ó
®◊¥R#Jí$Ií$Åà§ˇÛIKÿ_TJøˆç¯Nø∂a«©6R„πwT&¸y&õ±û—}€–∑]£∞c’{
ãyma^ŸæïO‘MäÁÃÃVåÌ◊ÜÅõÁ±JGU¥4∏Û„?ÀèOãKÄ3Ó˙H¨Si—$Ií$Ií˛ìà§2o/€¬‰≈yƒ«E∏gT¶/&EÉª4eLv∆ÕŸƒœ∆-d“ı'∏s‚(ç∆¯`’v∆Õ…·ı≈yGÅ`uƒÒùÉ÷C3[R7…ˇ+´4Îß~Ï’Áâñ@”nñí$Ií$)tæj$	ÄE•‹Ò“b .?°#=Z•Üú®z∫uXﬁY∂ïey{xÚÉµ¸‰ŒaG™vVlŸ√ãsrò0w[
ñÕ;5´«ÿÏtF˜mCÎÜæ∏^©b1»˘¶ﬁd◊Ô›rtÛHí$Ií$I <ÚŒJrv†uZ
ˇsj◊∞„T[MÍ'sÀ∞‹Ù¬~˚Ê
Üeµ¢m„∫a«™ÚvÏ=»ƒ˘õ7g7ÂóÕ÷MddÔ÷å…Nßwzëàw%U™Ω€`¡ø`Œﬂ`˚Ú#ø˙-é^&Ií$Ií§#d"âU[˜ƒ{k ∏cDOÍ%˚≠·õ8ß_:/ÃŒaÊ⁄ù‹Ò“"û¸˛qæpˇ9ñîÚŒ≤≠º0{Sóo•$ÏïHàãpJ˜ÊåÕNÁîÓÕHNà9i--Ö’o√úg`˘´¡ëV âu°«HXı&Ïﬂ¡ÁÔâ@jkh?∏2Kí$Ií$}._ÂîjπX,∆mQ\„‘ÓÕ“”ﬂ‹˛¶"ë˜éŒbÿÔﬂÁùÂ€xua√{µ
;Vïã≈òüìœã≥sò¥`3ª˜ó=ñ’&ç±Ÿm—ª5MÍ'áò≤ñ⁄µÊ˛Ê=õ Á≠≥!˚b»)©∞d"<w1·‰P…7Ùà≥¥í$Ií$I·≥ ëj°“håYkw≤uO!ÀÛˆ0cÕNR„∏kdOÔT® ]ö◊ÁÍouÊ˜o≠‰ÆIã9±[SRS√éöÕª0~Ó&∆Õ…aı∂}eÛ©…åÍ€Ü±ŸÈtk— ƒÑµTq!,{9∏€cÌªÂÛ:ç†◊˘ê}¥Ëy¯˚dåÑsüÅ…7æ=µuP~då¨úÏí$Ií$I_¬D™e&/ ÂÓIK»Õ/<l>§gKwUT∞´ø’ôIÛ7≥f˚>~5y9øïv§JµÔ`	ìÂ1nn”VÔ vËfÅîƒ8ÜÙl…ÿÏtéÔ“î¯8K∑Jó∑0ÿÎ±‡ﬂP∏˚–0ùæî›œÇÑˇrN∆HË>÷Oû◊o{Âùí$Ií$©
âƒb±œ;ƒ[™ı


HKK#??ü‘‘‘∞„Tà…ãrπ˙ÔsæË‰~˚^6C3=™©"M[Ωù˛4ìH^∏j0˝⁄7
;“Qç∆ò±f/Ã…aÚ¢<ˆïñ=6†cc∆fßsfVK‘‚ªaBSò_Óˆ»ùW>OMáæBü°Q˚–‚Ií$Iíjûö¯˙ö™Ô ëjâ“håª'-˘‹Ú„wOZ¬È-˝ç¸
4∏s”≤•Ë∑é_»§ÎO 1>.ÏXnı∂Ωåõì√¯9õÿ¸©ªã⁄7©ÀÿÏtF˜m„Faà≈`˝á¡›K^Çí¡<.∫v{t:≈;7$Ií$IRçd"’≥÷Ó¸Ã±WürÛôµv'É:7©º`µ¿-√z÷“-,À€√_>XÀU'w;RÖÿΩøàIryqvÛ6Ó.õ7HI‡¨^≠9ß_≤€5rØLˆ‰ÀÃÁ˛vÆ.ü7Îq’Î<®◊4º|í$Ií$Iï¿D™%∂Ó˘‚Ú„Î\ß#◊∏^∑œ‡üüœÔﬁ\¡¨V’ˆnà‚“(Sóoc‹úﬁZ∫ï¢“( ÒqNÓ÷å1Ÿm8≠GRΩ£†“ïñ¿ 7`Óﬂ`≈Î;t¸XR}»}/ÜÙc¡BJí$Ií$’ R-—ºAJÖ^ßØflv^òΩëkvr€ÑE<uÈq’ÊŒàX,∆‚Õº8'áâÛ6≥c_QŸc=Z•26ª#˚¥ˆøù∞ÏXîÛûí¢Ì Ë{Ù…ı√À'Ií$Ií©ñËﬂ±1≠“R»À/¸¬%Ë-”RËﬂ±qeG´"ë˜éŒ‚ÃﬂΩœª+∂Ò ¬\ŒÍ’:ÏXˇ’ñÇB&Ã›ƒ∏9õXæeOŸºi˝dFıiÕòÏt2Zª¿,E˚ÉùsˇÏ¯¯D›¶–ÁªAÒ—ÏòÚIí$Ií$U R-·Œ\˝˜9D‡∞‰ì˚Óë·Ù£®s≥˙\sJg~˜ÊJÓû¥Ñª6#≠Nbÿ±s†®î7ñ‰Ò‚úM|∞r—Cˇ°$%ƒqzFŒ…NÁƒÆMI®Åã‹´ºX6œJèÖ/¿¡Ç`âÉ.ß•G∑°êênNIí$Ií§*"ã≈>Ôó¡•ZØ††Ä¥¥4ÚÛÛIM≠9øÂ>yQ.wOZrÿBÙVi)‹9"É°ô≠BLV;,)ÂÃﬂøœöm˚∏p@;Óùv$¢—≠€…∏9õxua.{ñî=÷Ø}#∆fß3<´iu´VYSkÏﬂ	üá9œ¿ñEÂÛÜÌÉ“£œê÷&º|í$Ií$}Åö˙˙ö™È‘‰o–•—≥÷ÓdÎûBö7éΩÚŒè 3cÕŒb /^=ò~ÌÖíc˝é}º8g„ÁÊ∞qÁÅ≤yõÜuõ›Ü1ŸÈthZ/îlµ^4
kﬂÓˆX˙2îÊÒ…ê12(>:úqﬁâ#Ií$I™∫jÚÎk™<K™Ö‚„"Í‹$Ïµ÷¿NM¯Nøtûüù√-„ÚÚèN ±íéî*(,Êïπåõì√GÎvïÕÎ%≈3,´c˚•”øCc‚,ƒ¬ëü,3ü˚7ÿΩ°|ﬁ"≤/Ü¨s†Æ{z$Ií$IíéÑà$Ö‡ña=xkŸVñoŸ√üﬂ_À’ﬂÍ|‘>VIiî˜WmÁ≈Ÿ9LY≤ÖÉ%Q "8°KS∆fß3§gKÍ$≈µ˙/Jä`≈k0Áo∞˙-àˇ~HN
èÏã†Uü‡_ò$Ií$Iíéòà$Ö†QΩ$n÷Éü<?üﬂøµÇ·Y≠h◊§nÖ~åeyº8;á	Û6≥mœ¡≤y◊Êı€/ùQ}⁄–2-•B?¶æÇmÀÉΩÛˇ˚∑óœ€üî=FBR≈˛7!Ií$IíTõXÄHRH∆d∑·ÖŸ9L_≥É€^Zƒ”óG‰˛ñˇ∂=ô83/ŒŒaInAŸºQ›DŒÓ”Ü±ŸÈd∂I˝∆G_”¡Ω∞x\p∑GŒ¨Úy˝ñ¡2ÛæﬂÉ&GÔn Ií$Ií§⁄ƒDíBâD∏wt&Cˇ>Ô≠ÿ∆§πåÏ›˙+?Oaq)o-› ∏99L]±ç“hÄƒ¯ßvo¡òÏ6|ÎòÊ$%∏0;±‰|‹Ì±x<ÌÊëxË64∏€£ÀÈÔˇ%Kí$Ií$U$_më§ujVüÎNÈ¬o¶¨‡ÁìñpBÁ¶,ﬂ≤á≠{
iﬁ Ö˛ˇ9…c±s6ÏÊ≈99º<3Ö%eèın€ê±Ÿm—´5çÍ%UÊß£O€∑=8ﬁjÓﬂ`€≤Úy„ŒAÈ—˚ª–†ex˘$Ií$Iíj8I
ŸOÓƒKÛ6±z€>Nxmˆïñ=÷*-Ö;Gd04≥ 9ªˆ3~Œ&∆Õ›ƒ⁄Ì˚ªntﬂ6å…nCóÊ*˝s–!—RX˝Ãyñø—‚`ûPzéÇæA˚¡.4ó$Ií$I™ í≤‰ÑxŒÓ”ÜﬂLYqX˘êó_»’ü√EÉ⁄≥bÀf¨ŸYˆXùƒxŒÃl…ÿ~ÈÏ‘‰sÔQ%ŸµÊ˛Ê=9ÂÛ÷}!˚b»)i·Âì$Ií$I™Ö,@$)d•—ˇúµ·sã˙˚3”◊óÕuj¬ÿ~ÈÕlI˝døçá¶∏ñΩqµÊ] ˛m•4ÑﬁÁw{¥Ã3°$Ií$IR≠Ê+gí≤Ykwíõ_¯•◊ù{l:?:µ+ÈçÍVB*}°ºE¡BÛˇÜ¬›ÂÛNﬂ
JèÓgAbJXÈ$Ií$Iítàà$ÖlÎû//? éÔ“‘Ú#,Ö˘∞Ö‡nèÕsÀÁ©m†œÖ–˜Bh‘!¥xí$Ií$I˙,I
YÛGv∑¿ë^ß
ã¡˙iAÈ±xîÊqâ–}ÙΩ:üqÒ°∆î$Ií$I“Á≥ ë§êıÔÿòVi)‰ÂñÌ¸¯¥–2-Ö˛Wv¥⁄iœòˇl∞‘|«™Úy≥Ó¡WΩœázM√À'Ií$Ií§#b"I!ãèãpÁàÆ˛˚"pX	9Ù˜;Gd˘ú˜VÖ(-ÅUSÇ›+^áXi0O¨ôc ˚H?"˛;ê$Ií$I™.,@$©
öŸä«æóÕ›ìñ∂ΩeZ
wé»`hf´”’`;VG\Õ˚'ÏÕ+üß˜áÏã°ÁhHÆ^>Ií$Ií$}m íTEÕl≈È-ôµv'[˜“ºApÏïw~T∞¢˝∞t"Ã˘¨ˇ†|^∑	Ù˛npÃUÛÓ·Âì$Ií$IRÖ∞ ë§*$>.¬†ŒM¬éQÛƒbê;/(=æ ÛÉy$:ü
ŸA∑3!!)‘òí$Ií$I™8 í§öÎ¿.X|∞€cÀ¬Úy√v¡ù}.Ä¥ÙÚIí$Ií$È®± ë$’,—(¨{/∏€cÈ$(=Ã„ì†«à`∑Gáì ..‹úí$Ií$I:™,@$I5C˛&ò˜l∞‘|˜˙ÚyãÃ†Ù»˙‘m^>Ií$Ií$U*IRıUR+&G\≠~b—`ûú
YÁ«\µÓ…Kí$Ií$’6 í§Íg€Ú†Ùòˇ/ÿøΩ|ﬁ˛¯†Ù»8íÍÜóOí$Ií$I°≥ ë$U˜¬‚Ò¡WgñœÎ∑Äﬁﬂäè¶]¬À'Ií$Ií§*≈DíTu≈bêÛ1Ã}çÉ¢Ω¡<]œv{t=‚√Õ)Ií$Ií§*«DíTıÏ€˛sµmY˘ºqß‡Nè>@Éñ·Âì$Ií$IRïg"I™¢•∞Êù†ÙXˆ*DãÉyBù`ßGˆE¡éöKí$Ií$ÈXÄHí¬µk=Ã˚Ã˝‰îœ[˜Óˆ»:R“¬À'Ií$Ií§j…DíT˘J¬≤óaŒﬂ`ÕT ÃSBØÛÇª=ZfÖPí$Ií$I’ùà$©ÚlYî˛vïœ;û,4Ô~$¶ÑóOí$Ií$I5Üà$ÈË*,ÄE/≈«Ê9ÂÛ≠°ÔÖ–ÁBh‹1º|í$Ií$I™ë,@$I/É”É“cÒx(9Ã„‡òa¡›ùøqÒ·Êî$Ií$IRçe"I™8{∂¿¸¬‹ø¡éUÂÛ¶«{=zùıõÖóOí$Ií$IµÜà$Èõ)-ÅUo¬úg`≈dàïÛƒzê9˙^m˚C$nNIí$Ií$’* í§Øg«jò˚wò˜,ÏÕ+üß}/ÇÃ1ê‹ º|í$Ií$I™’,@$IGÆ¯ ,ôqµÓ˝Úy›&–˚ª–˜{–ºGx˘$Ií$Ií§C,@$I_nÛº†ÙX<Ã?4å@óSÉª=é	Ia&î$Ií$Iíc"I˙|vÖ«‹g oa˘<≠]pßGü†a€ÚIí$Ií$IˇÖà$©\4m5˜o¡QW•Éy|t?≤/ÇéﬂÇ∏∏0SJí$Ií$I_ Díõaﬁ?Ç•Êª÷ïœõ˜ÑÏã°◊πP∑qhÒ$Ií$Ií§Ø Díj´“bX1Ê<´ﬁÑX4ò'5Ä¨sÇª=ZgC$nNIí$Ií$Èk∞ ë§⁄f€ä`Ø«¸¡æmÂÛvÉÉ“#„lH™^>Ií$Ií$©XÄHRmpp/,ô s˛gîœÎ5ñô˜Ωöv	-û$Ií$IíT—,@$©¶ä≈`”Ï‡à´E/B—ﬁ`âÉÆCÇª=∫ûÒâ·Êî$Ií$IíéI™iˆÌÄˇ
Óˆÿ∂¥|ﬁ®cPzÙæ R[ÖóOí$Ií$I™ íTDKaÕ;AÈ±ÏàÛÑî`ßGˆ≈–˛xöKí$Ií$©÷∞ ë§Íl˜ò˚ò˜»ﬂX>o’;(=2œÅ:Cã'Ií$Ií$Ö≈Dí™íh)¨ü{∑@˝–~0ƒ≈~M…¡‡.èπÉ’Ô ±`ûíΩŒö∑ÍUÈ—%Ií$Ií§™ƒDí™ä%aÚÕP∞π|ñ⁄Ü˛2F¬ñ≈¡W˛vñ_”Ò$Ë{1Ù8ÎT~nIí$Ií$©
≤ ë§™`…DxÓb ÓÊ¯DA.<w4Ó;◊îœ¥Ü>@ﬂÔA„éïUí$Ií$I™,@$)l—“‡Œèˇ,?†|∂sD‚·ò3!˚ËrÍgè∆í$Ií$IíT∆Dí¬∂~⁄·«^}ëÔ<#é~Ií$Ií$©à;Ä$’zõÁŸu•èjIí$Ií$©&ÒI
C¥Vº≥ûÄ5ÔŸ˚‘oqt3Ií$Ií$I5àà$U¶˝;aÓﬂ‡£?√ÓÂÛÑ()¸Çwä@jkh?∏R"Jí$Ií$I5Åà$UÜºÖ0Ûè∞˘Ú¢#•!d_«]πÛ·πã]¸ÈeËë‡oCpÈπ$Ií$IíÙXÄH“—RZK'«\mò^>oëÆÑÃs ©n0k‘Œ}&ﬂ|¯BÙ‘÷A˘ë1≤r≥Kí$Ií$I’úà$U¥=[`Œ”Òì∞'7ò≈%@èë–ˇJh7"ëœæ_∆HË>÷OÉΩ[ÇùÌ{Áá$Ií$IíÙ5XÄHREà≈ Á„‡nè≈„!ZÃÎ5ác/Ö~óBj´/û∏xËx‚—Õ*Ií$Ií$’ íÙM¬‚qAÒ±yn˘<˝8ËˇC»8í¬À'Ií$Ií$’R íÙu‰Á¿G	é∫⁄ø#ò≈'CÊXËˇhìn>Ií$Ií$©ñ≥ ë§#ã¡∫`÷aŸ+ãÛ‘t8Ó2»æÍ57£$Ií$Ií$¿Díæ\—>Xoòı'ÿ∫§|ﬁ·ƒ`©˘1√ ﬁoßí$Ií$IRU‚+víÙEv¨éπö˚w8òÃÎBÔÛ·∏@ãåpÛIí$Ií$I˙B íÙi—(¨~+Xjær
Êç;•Gü†N√0Jí$Ií$I: íPòsˇ˝	vÆ)üw=#8Ê™Û©^>Ií$Ií$I_âà§⁄mÎ“‡nè˘ˇÜ‚}¡,9˙~éªöt7ü$Ií$Ií§Ø≈DRÌSZ+^ÉôÑuÔóœõıÄWB÷πê\?º|í$Ií$Iíæ1Iµ«æ0Ái¯¯I»ﬂÃ"q–}8Ùˇ!t8"ëp3Jí$Ií$I™ íjæÕsa÷ü`·Pz0ò’mŸó¿±óA√∂·Êì$Ií$IíT·,@$’L%E∞‰•`øGŒ¨Úy´>0‡á–s$¶ÑOí$Ií$I“—e"©˙àñ¬˙i∞w‘oÌC\¸·◊‰¬Ïø¬«Ö}[ÉY\"Ù˝ØÑÙc=ÊJí$Ií$I™,@$UK&¬‰õ°`s˘,µ5˝%ÙgKÕóNÑhIxÉV¡WŸó@É·‰ñ$Ií$Ií
IUﬂíâ‹≈@ÏyA.<w4lª7îœ€
ÓˆË1‚+5™$Ií$Ií§™¡DR’-Ó¸¯œÚ gª7@|2Ù:7(>Zı™ÃÑí$Ií$Ií™ IU€˙iá{ıEæÛtv‘„Hí$Ií$I™‚¬ IˇU˛¶#ªÆxˇ—Õ!Ií$Ií$©ZÒIU”˛ù0˚)òˆ»ë]_ﬂ%Áí$Ií$Ií YÄH™Zv¨Üè¡ºîﬂ’âÉXÙﬁ!©≠°˝‡Jã(Ií$Ií$©Í≥ ëæX÷”ÖÂØQ∂‹ºE∫í‡ÖÀ?π¯SÔ	˛6ÙàãØƒ¿í$Ií$Ií™:I·))Ç≈„a∆£ê;ø|ﬁmhP|t8"áJé∏Dò|Û·—S[ÂG∆» Õ-Ií$Ií$© ≥ ëT˘ˆÔÑŸÖYÇ=π¡,°Ù˘.ºöv˝Ï˚dåÑÓ√a˝4ÿª%ÿ˘—~∞w~Hí$Ií$I˙\ í*œˆU0Û1ò˜l˘~è˙-°ˇ‡ÿÀ†n„ˇ˛˛qÒ–Òƒ£üSí$Ií$IRµg"ÈËä≈`›¡~èì)€·—2]=«;>$Ií$Ií$©YÄH::Jä`Ò∏†¯»[P>ˇº˝í$Ií$IíT¡,@$U¨Oˆ{Ã|ˆÊ≥Ñ:–ÁxıÁÔ˜ê$Ií$Ií§
f"©bl_3˛ Ûˇy¯~èWBøKø|øá$Ií$Ií$U I__,ÎﬁáÈÄØïœ›Ô!Ií$Ií$)d íæ∫≤˝è@ﬁ¬Úy∑3Ì˜8¡˝í$Ií$IíBe"È»Ìﬂ	?	≥˛t¯~èæ¬Ä´°iópÛIí$Ií$I“! íæ‹'˚=Ê=%ÇYÉV–ˇÓ˜ê$Ií$IíT%YÄH˙|e˚=ÖìÀÁ-{⁄Ô1⁄˝í$Ií$Ií™,©6äñ¬˙i∞w‘oÌC\|XI,z1(>∂|≤ﬂ#«ú	Øqøá$Ií$Ií§j¡D™mñLÑ…7C¡ÊÚYjk¯ˆÌ¡Ï”˚=ÎBü‹Ô!Ií$Ií$©⁄± ëjì%·πãÅÿ·ÛÇÕ0·ÍÚ∑¥Ç˛WBøÔªﬂCí$Ií$IRµd"’—“‡Œèˇ,?>-.F>ôc›Ô!Ií$Ií$©Zã;Ä§J≤~⁄·«^}ûh1§•[~Hí$Ií$I™ˆ,@§⁄bÔñäΩNí$Ií$Ií™0©∂®ﬂ¢bØì$Ií$Ií§*ÃD™-⁄Ü‘÷@‰.à@jõ‡:Ií$Ií$I™Ê,@§⁄".Ü˛Ú–ˇYÇz{Ë¡uí$Ií$IíTÕYÄHµI∆H8˜Hmu¯<µu0œN.Ií$Ií$I™`	aêT…2FB˜·∞~Z∞º~ã‡ÿ+Ô¸ê$Ií$IíTÉxà*‘{ÔΩ«à#h›∫5ëHÑ	&|Êö•Kó2r‰H“““®WØ«w6l({º∞∞êkØΩñ&MöPø~}∆éÀñ-[{é60|¯pÍ÷≠KÛÊÕπÈ¶õ())9Ïö©SßíùùMrr2]∫t·©ßû:ürıOÑ¨sÇø[~Hí$Ií$I™a,@T°ˆÌ€GÔﬁΩyÙ—G?˜Ò’´Ws¬	'–Ω{w¶Nù Ç∏˝ˆ€III)ªÊÜn`“§I<ˇ¸Ûº˚Óªlﬁºô1c∆î=^ZZ ·√)**b⁄¥i<˝Ù”<ı‘S‹q«e◊¨]ªñ·√ás )ß0oﬁ<~¸„s≈W˙ÎØΩO^í$Ií$IíTeDb±X,Ï™ô"ë„«èg‘®Qe≥Ûœ?üƒƒD˛ˆ∑ø}Ó˚‰ÁÁ”¨Y3û}ˆYŒ9Á ñ-[Fè=ò>}:‰µ◊^„¨≥ŒbÛÊÕ¥h—Ä«úõoæôm€∂ëîîƒÕ7ﬂÃ+Øº¬¢Eã˚ÿªwÔfÚ‰…Gîø††Ä¥¥4ÚÛÛIMM˝öˇ$Ií$Ií§⁄…◊◊6Ô Q•âF£ºÚ +tÎ÷ç!CÜ–ºyspÿ1Y≥gœ¶∏∏ò”N;≠l÷Ω{w⁄µk«ÙÈ”ò>}:YYYeÂ¿ê!C(((`Ò‚≈e◊|˙9>πÊìÁê$Ií$Ií$’l ™4[∑neÔﬁΩ<¿:î7ﬁxÉ—£G3fÃﬁ}˜] ÚÚÚHJJ¢a√ÜáΩoã-»ÀÀ+ªÊ”Â«'èÚÿª¶††Ä|næÉRPPpÿ_í$Ií$Ií§Í)!Ï ™=¢—( gü}67‹p }˙Ùa⁄¥i<˛¯„ú|Ú…a∆„˛˚ÔÁÓªÔ5É$Ií$Ií$©bxà*M”¶MIHH ##„∞yè=ÿ∞a -[∂§®®à›ªwvÕñ-[hŸ≤eŸ5[∂l˘Ã„ü<ˆﬂÆIMM•Nù:üõÔg?˚˘˘˘em‹∏ÒÎ}¢í$Ií$Ií§–YÄ®“$%%q‹q«±|˘Ú√Ê+V¨†}˚ˆ ÙÎ◊èƒƒDﬁzÎ≠≤«ó/_ŒÜ4h Éb·¬Öl›∫µÏö)S¶êööZVÆ4Ë∞Á¯‰öOû„Û$''ìöözÿ_í$Ií$Ií§Í…#∞T°ˆÓ›À™U´ ﬁ^ªv-ÛÊÕ£q„∆¥k◊éõn∫âÛŒ;èìN:âSN9Ö…ì'3i“$¶Nù
@ZZó_~97ﬁx#ç7&55ïÎØøûAÉ1p‡@ Œ8„222∏Ë¢ãx¡…ÀÀ„∂€n„⁄kØ%99Ä´Æ∫äGyÑˇ˜ˇ˛ó]voø˝6œ=˜ØºÚJ•ˇ3ë$Ií$Ií$UæH,ãÖB5«‘©S9ÂîS>3ø‰íKxÍ©ß xÚ…'πˇ˛˚………·òcé·ÓªÔÊÏ≥œ.ª∂∞∞êü¸‰'¸Ûüˇ‰‡¡É2Ñ?¸·e«[¨_øû´Øæö©SßRØ^=.π‰x‡ ;Ω©Sßr√7∞d…“””π˝ˆ€˘˛˜øƒüKAAiii‰ÁÁ{7à$Ií$IíÙ˘˙ö¬f"}øAKí$Ií$I_üØØ)lÓ ë$Ií$Ií$I5éà$Ií$Ií$I™q,@$Ií$Ií$IRçc"Ií$Ií$IíjIí$Ií$IíT„XÄHí$Ií$Ií§«Dí$Ií$Ií$’8 í$Ií$Ií$©∆± ë$Ií$Ií$I5éà$Ií$Ií$I™q,@$Ií$Ií$IRçc"Ií$Ií$IíjIí$Ií$IíT„$Ñ@™™b± !'ë$Ií$Ií™üO^W˚‰u6©≤YÄH_`œû= ¥m€6‰$í$Ií$IRıµgœ“““¬é°Z(≥~ì>W4eÛÊÕ4h–ÄH$vú#RPP@€∂mŸ∏q#©©©a«ëj5ø•™¡ØE©ÍÎQ™:¸zî™éö˛ıã≈ÿ≥g≠[∑&.Œm™|ﬁ"}Å∏∏8“””√éÒµ§¶¶÷»ˇ”î™#ø•™¡ØE©ÍÎQ™:¸zî™éö¸ıËù
ìµõ$Ií$Ií$I™q,@$Ií$Ií$IRçc"’ ………‹yÁù$''áE™ı¸zî™ø•™√ØG©ÍÎQ™:¸zîé.ó†Kí$Ií$Ií§«;@$Ií$Ií$IRçc"Ií$Ií$IíjIí$Ií$IíT„XÄHí$Ií$Ií§«D™!}ÙQ:tË@JJ
`÷¨YaGí™µ˚Ôøü„é;é–ºysFç≈ÚÂÀª¶∞∞êkØΩñ&MöPø~}∆éÀñ-[ªf√Ü>ú∫uÎ“ºysn∫È&JJJªfÍ‘©dggìúúLó.]xÍ©ßéˆß'Uk< ëHÑˇ¯«e3ø• ≥i”&æ˜ΩÔ—§IÍ‘©CVV¸qŸ„±Xå;Ó∏ÉV≠ZQßNN;Ì4VÆ\yÿsÏ‹πì/ºê‘‘T6l»Âó_ŒﬁΩ{ªf¡Çúx‚â§§§–∂m[|¡J˘¸§Í†¥¥î€oøùé;RßN:wÓÃ/~Òb±XŸ5~-JG«{ÔΩ«à#h›∫5ëHÑ	&ˆxe~Ì=ˇ¸ÛtÔﬁùîî≤≤≤xı’W+¸Ûï™;©¯˜øˇÕç7ﬁ»ùwﬁ…ú9sË›ª7CÜaÎ÷≠aGì™≠wﬂ}ókØΩñ3f0e äãã9„å3ÿ∑o_Ÿ57‹pì&M‚˘ÁüÁ›wﬂeÛÊÕå3¶ÏÒ““RÜNQQ”¶M„ÈßüÊ©ßû‚é;Ó(ªfÌ⁄µ>úSN9ÖyÛÊÒ„ˇò+Æ∏Ç◊_ΩR?_©∫¯Ë£è¯„ˇHØ^Ωõ˚ı(Ué]ªvq¸Ò«ìòò»kØΩ∆í%K¯ıØM£Fç Æy¡yË°áx¸Ò«ô9s&ıÍ’c»ê!ñ]s·Ö≤xÒb¶Lô¬À/øÃ{ÔΩ«ïW^YˆxAAgúqÌ€∑gˆÏŸ¸ÍWø‚ÆªÓ‚â'û®‘œW™™~˘À_ÚÿcèÒ»#è∞tÈR~˘À_Ú‡ÉÚ√ó]„◊¢ttÏ€∑èﬁΩ{ÛË£è~Ó„ïıµ7m⁄4æ˚›Ôr˘Âó3˜ˇ∑wˇQY÷˜«_¿"Çê˜çÕ†§tDLE<ÍÑÃ√]≤ú«©ùF:L‹V4á€<ùV∂i€©≥UˆGÿôŒµ%n´DA°Ç*" RL±∆-kFJr·Û˝√„U˜W3Kπ|>Œ·ÔÎ˙‹üÎ˝π8Ôsnyùœ}UW+##C™≠≠Ì∫≈Ωë–Îç7Œdgg[Ø;::Ã†AÉÃ”O?›ÉUˆ“‹‹l$ô∑ﬂ~€cLKKãÒıı5˝Î_≠1á2íLEEÖ1∆ò∑ﬁzÀx{{∑€mçy·ÖLpp∞˘¸Ûœç1∆‰ÊÊöë#Gz\Î{ﬂ˚ûIKKÎÍ%ΩŒŸ≥gMtt¥)**2S¶L1999∆˙ËNè?˛∏ô4i“WûÔÏÏ4.óÀ¸ˆ∑øµéµ¥¥ÛÁ?ˇŸcÃ˚Ôøo$ô={ˆXc∂m€fºººÃG}då1Êè¸£	µ˙Û“µá~£óÙJ3gŒ4>¯†«±9sÊò˘ÛÁcËE†ªH2÷ÎÓÏΩÃÃL3sÊLèz∆èo~¯·∫F†∑c–Àù?^UUUJII±éy{{+%%E=X`/ü~˙©$i¿Äí§™™*µ∑∑{Ùﬁà#4d»´˜***'ß”içIKK”ô3gÙÔˇ€ÛÂ9.ç°ÅÀeggkÊÃôóı˝tü¸„;v¨ÊŒù´Å*>>^/ø¸≤u˛¯Ò„rª›Ω‘øç?ﬁ£CBB4vÏXkLJJäºΩΩUYYiçô<y≤¸¸¸¨1iii™´´”'ü|“’Ànz'N‘Œù;u‰»IRMMç   4c∆IÙ"–S∫≥˜¯Ï
\†ó˚¯„è’——·ÒIr:ùrª›=T`/ùùùZ±bÖííí4j‘(Ií€ÌñüüüBBB<∆~π˜‹n˜{Û“π´ç9sÊå⁄⁄⁄∫b9@Ø¥yÛfÌ€∑OO?˝ÙeÁËG†˚;vL/ºÇ¢££µ}˚v-]∫TÀó/◊Ü$}—OW˚lÍvª5p‡@èÛáC¯F=‹ ~ˆ≥üÈÅ–à#‰ÎÎ´¯¯x≠X±BÛÁœóD/=•;{Ô´∆–õÄ'GO  ¿Õ.;;[µµµ*++ÎÈRÄ[“…ì'ïìì£¢¢"ıÈ”ßßÀniùùù;v¨ûzÍ)IR||ºjkkı‚ã/j·¬Ö=\pÎxÌµ◊¥q„Fm⁄¥I#Gé¥û]5h– z Ä/a–ÀÖááÀ««GßNùÚ8~Í‘)π\Æ™
∞èeÀñÈç7ﬁPIIâæÛùÔX«].óŒü?ØññèÒ_Ó=óÀu≈ﬁºtÓjcÇÉÉp£óÙJUUUjnn÷ò1c‰p8‰p8Ùˆ€oÎπÁûì√·ê”È§Ån°ªÓ∫À„Xll¨%}—OW˚lÍrπ‘‹‹Ïq˛¬Ö:}˙Ù7ÍY‡VˆÿcèYª@‚‚‚¥`¡˝¯«?∂vJ“ã@œËŒﬁ˚™1Ù&‡â ËÂ¸¸¸îêê†ù;wZ«:;;µsÁN%&&ˆ`e@Ôfå—≤eÀTPP†]ªv)22“„|BBÇ|}}=zØÆÆNçççVÔ%&&Í‡¡Énãääl˝Ò(11—céKcË_‡………:x†ˆÔﬂo˝å;VÛÁœ∑˛M?›#))Iuuu«é9¢°CáJí"##Ârπ<zÈÃô3™¨¨ÙË«ññUUUYcvÌ⁄•ŒŒNç?ﬁÛŒ;Ô®ΩΩ›STT§·√á+44¥À÷ÙÁŒùì∑∑Áüt|||‘ŸŸ)â^zJwˆü]Åk‘”Oap˝6oﬁl¸˝˝M~~æyˇ˝˜MVVñ			1n∑ªßKz≠•Kóö˛˝˚õ““R”‘‘d˝ú;wŒ≥d…3d»≥k◊.≥wÔ^ìòòh≠Û.\0£Fç2©©©fˇ˛˝¶∞∞–‹v€mfÂ ï÷òc«éô¿¿@ÛÿcèôCáô?¸·∆«««vÎzÅﬁf î)&''«zM?›c˜Ó›∆·pò_ˇ˙◊ÊÉ>07n4ÅÅÅÊO˙ì5fÕö5&$$ƒ¸˝Ô70≥fÕ2ëëë¶≠≠ÕsÔΩ˜ö¯¯xSYYi   Ltt¥ô7oûuæ••≈8ùN≥`¡S[[k6oﬁlÕK/Ω‘≠ÎnV.4∑ﬂ~ªy„ç7ÃÒ„«Õñ-[Lxx∏…ÕÕµ∆–ã@◊8{ˆ¨©ÆÆ6’’’FíyˆŸgMuuµ9q‚Ñ1¶˚zØºº‹8≥vÌZsË–!Û´_˝ ¯˙˙öÉvﬂÕ z¿&û˛y3d»„ÁÁg∆çg˛ıØıtI@Ø&Èä?ØºÚä5¶≠≠Õ¸ËG?2°°°&00–Ãû=€455yÃ”––`fÃòaLxx∏˘ÈOj⁄€€=∆îîîò—£G???s«wx\¿ï˝ˇ Ñ~∫œ?ˇ˘O3j‘(„ÔÔoFåa÷Ø_Ôqæ≥≥”¸‚ø0Nß”¯˚˚õ‰‰dSWWÁ1Êˇ˚üô7oû	

2¡¡¡fÒ‚≈ÊÏŸ≥cjjjÃ§Iìåøøøπ˝ˆ€Õö5k∫|m@oqÊÃìììcÜb˙ÙÈcÓ∏„ìóóg>ˇ¸skΩtçííí+˛_q·¬Ö∆òÓÌΩ◊^{Õƒƒƒ???3r‰HÛÊõovŸ∫Åﬁ ÀczfÔ	        @◊‡         ¿v@        ÄÌÄ         €!         ∂C         lá         ÿ        ∞    ΩFCCÉººº¥ˇ˛û.Eí¥h—"edd|£˜¨^ΩZ£GèÓíz    |Å     æ∆ç^}ÙQÌ‹πÛ∫Ê»œœóóóóı§ÑÑmŸ≤Â∫Î   ÏÇ     ∫QPPê¬¬¬Æ{û‡‡`555©©©I’’’JKKSff¶ÍÍÍn@ï   @ÔG    ÙSßN’#è<¢+V(44TNßS/ø¸≤>˚Ï3-^ºX˝˙ıSTTî∂m€ÊÒæ⁄⁄ZÕò1CAAAr:ùZ∞`Å>˛¯cÎ¸ﬂ˛ˆ7≈≈≈)  @aaaJII—gü}&I*--’∏q„‘∑o_ÖÑÑ())I'Núê$’◊◊k÷¨Yr:ù


“=˜‹£‚‚bèk755iÊÃô
Pdd§6m⁄§a√ÜÈ˜øˇΩ5¶••E=ÙênªÌ6k⁄¥i™©©˘F˜ÊÎ÷8uÍT-_æ\πππ0`Ä\.óVØ^Ì1«·√á5i“$ıÈ”Gw›uóäããÂÂÂ•≠[∑Jí"##%IÒÒÒÚÚÚ“‘©S=ﬁøvÌZEDD(,,LŸŸŸjooˇ zˇˇW`]˙≠o2á$yyy…Âr…Âr)::ZO>˘§ºΩΩu‡¿ÅØøi   ¿-Ä    Ë%6lÿ†pÌﬁΩ[è<Úàñ.]™πsÁj‚ƒâ⁄∑oüRSSµ`¡ù;wN“≈pa⁄¥iäèè◊ﬁΩ{UXX®SßN)33S“≈Äbﬁºyz¡uË–!ïññjŒú92∆Ë¬Ö »»–î)St‡¿UTT(++K^^^í§÷÷V›wﬂ}⁄πsß™´´uÔΩ˜*==]çççVΩ?¯¡Ùüˇ¸G•••z˝ı◊µ~˝z577{¨iÓ‹πjnn÷∂m€TUU•1c∆(99YßOüæ¶{Úuk¸ÚΩÎ€∑Ø*++ıõﬂ¸FO<ÒÑäää$I »»P``†*++µ~˝zÂÂÂyº˜Ó›í§‚‚b555y|’TIIâÍÎÎURR¢6(??_˘˘˘◊Tˇçö£££C6lê$ç3Ê]   ∞+/cåÈÈ"    \›‘©S’——°wﬂ}W“≈?x˜Ôﬂ_sÊÃ—´Øæ*Irª›äààPEEÖ&Lò†'ü|RÔæ˚Æ∂oﬂnÕÛ·áj‡¡™´´Skk´‘––†°Cáz\ÔÙÈ”
Sii©¶LôrM5é5JKñ,—≤eÀt¯a≈∆∆jœû=;v¨$ÈË—£äéé÷Ô~˜;≠X±Beeeö9s¶öõõÂÔÔoÕ•‹‹\eee]vçÜÜEFF™∫∫Z£Gè˛⁄5∆ƒƒ\vÔ$i‹∏qö6mö÷¨Y£¬¬B•ßßÎ‰…ìrπ\í.”ßOWAAÅ222.ªÓ%ã-Rii©ÍÎÎÂ„„#I ÃÃî∑∑∑6oﬁ|≈˚¥zıjm›∫’zû»∑ô#??_ã/Vﬂæ}%ImmmÚıı’ã/æ®Eã]Ì◊   ‹2=]    Äks˜›w[ˇˆÒÒQXXò‚‚‚¨cNßSí¨]555*))QPP–es’◊◊+55U………äããSZZöRSSuˇ˝˜+44T–¢Eãîññ¶È”ß+%%Eôôôäààêtq»Í’´ıÊõo™©©I.\P[[õµ§ÆÆNá√c7BTTîBCC≠◊555jmmΩÏymmm™ØØø¶{ÚukåââπÏﬁIRDDÑuüÍÍÍ4x`+¸ê.$◊j‰»ëVpqiÓÉ^Û˚øÌ˝˙ı”æ}˚$IÁŒùSqq±ñ,Y¢∞∞0•ßß£Î   vD    ÙæææØΩºº<é]˙z™ŒŒNICäÙÙt=ÛÃ3óÕ!ÈΩ˜ﬁ”é;Ù¸Ûœ+//Oïïïäåå‘+Øº¢ÂÀó´∞∞P˘À_¥j’*i¬Ñ	zÙ—GUTT§µk◊***J∫ˇ˛˚u˛¸˘k^Okk´"""TZZzŸπêêêkû„jkº‰J˜Ó“}∫^7bÓo3á∑∑∑¢¢¢¨◊wﬂ}∑vÏÿ°gûyÜ       `[c∆å—ÎØøÆa√Ü…·∏ÚG///%%%)))Iø¸Â/5tËPË'?˘â§ã˝éèè◊ ï+ïòò®Mõ6i¬Ñ	*//◊¢Eã4{ˆlIÉàÜÜkﬁ·√áÎ¬Ö™ÆÆVBBÇ§ã_Åı…'üx‘ÁvªÂp84lÿ∞.[„◊>|∏Nû<©SßNYªhˆÏŸ„1∆œœO“≈Øªô˘¯¯®≠≠≠ßÀ    n
<   ∞©ÏÏlù>}ZÛÊÕ”û={T__ØÌ€∑kÒ‚≈ÍËËPee•ûzÍ)Ì›ªWççç⁄≤eã˛˚ﬂˇ*66V«è◊ ï+UQQ°'Nh«é˙‡É+Iäéé÷ñ-[¥ˇ~’‘‘Ë˚ﬂˇæ«éÖ#F(%%EYYY⁄Ω{∑™´´ïïï•ÄÄ kßJJJäïëë°;v®°°AÔΩ˜ûÚÚÚ¥wÔﬁ≤∆k1}˙t›yÁùZ∏p°8†ÚÚr≠ZµJ“ªj®ÄÄ Î!Îü~˙È5ˇ∫ä1Fn∑[n∑[«è◊˙ıÎµ}˚vÕö5´ßK   n
    ÄM4HÂÂÂÍËËPjj™‚‚‚¥b≈
ÖÑÑ»€€[¡¡¡zÁùwtﬂ}˜)&&F´V≠“∫uÎ4c∆Í·√˙Ówø´òòeee);;[?¸∞$ÈŸgüUhh®&Nú®ÙÙt•••y<ÔCí^}ıU9ùNMû<Y≥gœ÷¯CıÎ◊O}˙Ùët1\xÎ≠∑4yÚd-^ºX111z‡Åt‚ƒ	k'∆ıÆÒZ¯¯¯hÎ÷≠jmm’=˜‹£ázHyyyíd’Íp8Ù‹sœÈ•ó^“†AÉnäê·Ãô3äààPDDÑbccµn›:=ÒƒVÌ   ¿≠ŒÀcz∫    ˆ˜·áj‡¡*..VrrrOósUÂÂÂö4iíé=™;Ôº≥ßÀ   -Ä    ËªvÌRkk´‚‚‚‘‘‘§‹‹\}Ù—G:r‰»e˝Ói


Rtt¥é=™úúÖÜÜ™¨¨¨ßK   -Òt    ]¢ΩΩ]?ˇ˘œuÏÿ1ıÎ◊O'N‘∆ço∫CíŒû=´«\ççç
WJJä÷≠[◊”e   ∏Ï         ∂√C–       ÄÌÄ         €!         ∂C         lá         ÿ        ∞        `;         ¿v@        ÄÌÄ         €!         ∂C         lá         ÿ        ∞        `;         ¿v@        ÄÌÄ         €!         ∂C         lá         ÿ        ∞        `;         ¿v@        ÄÌÄ         €!         ∂C         lá         ÿ        ∞        `;         ¿v@        ÄÌÄ         €!         ∂C         lá         ÿ        ∞        `;         ¿v@        ÄÌÄ         €!         ∂C         lá         ÿ        ∞        `;         ¿v@        ÄÌÄ         €!         ∂C         lá         ÿ        ∞        `;ˇ¬⁄ŒÿõÔ    IENDÆB`Ç
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
âPNG

   IHDR  @  Ñ   ˘M˝¢   9tEXtSoftware Matplotlib version3.5.2, https://matplotlib.org/*6E   	pHYs  a  a®?ßi  ‚¨IDATxúÏ›wòîÂ˘∑Òsf+[qÅ•˜∫ÿ@E@È5Òµ$1jå∆ñcT¨àBPc7±&&b~ñƒ5&Ù"¢¢(F§w§◊]`Ÿ63ÔO‹∏Q#*0Àp~éÉCÔ{.ûÁö=aæ˚‹W(ã≈ê$Ií$Ií$IJ ·x7 Ií$Ií$Iít†ÄHí$Ií$Ií§Ñc "Ií$Ií$Iíéà$Ií$Ií$IJ8 í$Ií$Ií$)·ÄHí$Ií$Ií§Ñc "Ií$Ií$Iíéà$Ií$Ií$IJ8 í$Ií$Ií$)·ÄHí$Ií$Ií§Ñc "Ií$Ií$Iíéà$Ií$Ií$IJ8 í$Ií$Ií$)·ÄHí$Ií$Ií§Ñc "Ií$Ií$Iíéà$Ií$Ií$IJ8 í$Ií$Ií$)·ÄHí$Ií$Ií§Ñc "Ií$Ií$Iíéà$Ií$Ií$IJ8 í$Ií$Ií$)·ÄHí$Ií$Ií§Ñc "Ií$Ií$Iíéà$Ií$Ií$IJ8 í$Ií$Ií$)·ÄHí$Ií$Ií§Ñc "Ií$Ií$Iíéà$Ií$Ií$IJ8 í$Ií$Ií$)·ÄHí$Ií$Ií§Ñc "Ií$Ií$Iíéà$Ií$Ií$IJ8 í$Ií$Ií$)·ÄHí$Ií$Ií§Ñc "Ií$Ií$Iíéà$Ií$Ií$IJ8 í$Ií$Ií$)·ÄHí$Ií$Ií§Ñc "Ií$Ií$Iíéà$Ií$Ií$IJ8 í$Ií$Ií$)·ÄHí$Ií$Ií§Ñc "Ií$Ií$Iíéà$Ií$Ií$IJ8 í$Ií$Ií$)·ÄHí$Ií$Ií§Ñc "Ií$Ií$Iíéà$Ií$Ií$IJ8 í$Ií$Ií$)·ÄHí$Ií$Ií§Ñc "Ií$Ií$Iíéà$Ií$Ií$IJ8 í$Ií$Ií$)·ÄHí$Ií$Ií§Ñc "Ií$Ií$Iíéà$Ií$Ií$IJ8 í$Ií$Ií$)·ÄHí$Ií$Ií§Ñc "Ií$Ií$Iíéà$Ií$Ií$IJ8 í$Ií$Ií$)·ÄHí$Ií$Ií§Ñc "Ií$Ií$Iíéà$Ií$Ií$IJ8 í$Ií$Ií$)·ÄHí$Ií$Ií§Ñc "Ií$Ií$Iíéà$Ií$Ií$IJ8 í$Ií$Ií$)·ÄHí$Ií$Ií§Ñc "Ií$Ií$Iíéà$Ií$Ií$IJ8 í$Ií$Ií$)·ÄHí$Ií$Ií§Ñc "Ií$Ií$Iíéà$Ií$Ií$IJ8 í$Ií$Ií$)·ÄHí$Ií$Ií§Ñc "Ií$Ií$Iíéà$Ií$Ií$IJ8 í$Ií$Ií$)·ÄHí$Ií$Ií§Ñc "Ií$Ií$Iíéà$Ií$Ií$IJ8 í$Ií$Ií$)·ÄHí$Ií$Ií§Ñc "Ií$Ií$Iíéà$Ií$Ií$IJ8 í$Ií$Ií$)·ÄHí$Ií$Ií§Ñc "Ií$Ií$Iíéà$Ií$Ií$IJ8 í$Ií$Ií$)·ÄHí$Ií$Ií§Ñc "Ií$Ií$Iíéà$Ií$Ií$IJ8 í$Ií$Ií$)·ÄHí$Ií$Ií§Ñc "Ií$Ií$Iíéà$Ií$Ií$IJ8 í$Ií$Ií$)·ÄHí$Ií$Ií§Ñc "Ií$Ií$Iíéà$Ií$Ií$IJ8 í$Ií$Ií$)·ÄHí$Ií$Ií§ÑìÔ§Í*ç≤a√≤≥≥	ÖBÒnGí$Ií$I:¨ƒb1vÔﬁMÉá˝^|z “óÿ∞aç7éwí$Ií$I“am›∫u4j‘(ﬁmËd "}âÏÏl ¯:'''Œ›Hí$Ií$Iáó¢¢"7n\˘9õt®ÄH_‚”cØrrr@$Ií$Ií§o»„Â/º&Ií$Ií$Iíéà$Ií$Ií$IJ8 í$Ií$Ií$)·8D˙ñ"ëÂÂÂÒnC	"%%Ö§§§x∑!Ií$Ií$ˆ@§o(ã±i”&vÌ⁄ÔVî`j÷¨IΩzı&Ií$Ií$} “7Ùi¯ëüüOFFÜVÎ[ã≈b≥eÀ Í◊ØÁé$Ií$Ií§√óàÙD"ë £V≠ZÒnG	§Fç lŸ≤Ö¸¸|è√í$Ií$Iíæ!á†Kﬂ¿ß3?222‚‹â—ßøÆú-#Ií$Ií$}s “∑‡±W:¸u%Ií$Ií$}{ í$Ií$Ií$)·ÄHJX°PàW_}5ﬁmHí$Ií$Iäá†Kqâ∆òªj[vóêüùNóÊy$Ö=˛ËÎ˙’Ø~≈´Øæ ¸˘Û´Ïo‹∏ë£é:*>MIí$Ií$Iä+)N&.ÿ»®,dcaIÂ^˝‹tF~∑=è©«Œ™óX,F$!9˘ÎˇvUØ^ΩÉ–ë$Ií$Ií§√ÅG`Iq0q¡FÆxˆ˝*·¿¶¬Æxˆ}&.ÿx–ÓΩwÔ^~¸„ìïïE˝˙ıπˇ˛˚ÈŸ≥'◊\s Õö5„é;Ó‡‹sœ%33ìÜÚË£èÓ◊µœ;Ô<Œ9Áú*{ÂÂÂ‘Æ]õ?˝ÈO D£Q∆åCÛÊÕ©Q£«</ΩÙRe˝å3ÖBLò0ÅNù:ëññ∆[oΩı•˜;v,£Fç‚√?$

Ö;v,Pı¨’´W
ÖxÒ≈È—£5j‘‡ƒOdÈ“•º˚ÓªtÓ‹ô¨¨,ƒ÷≠[´‹„©ßû¢††ÄÙÙt⁄µk«cè=∂__Ií$Ií$IÒ„ “ã≈ÿW˘ ∫H4∆»◊>&ˆE◊ B¿Ø^[H∑Vµ˜Î8¨)IÑB˚l÷7‹¿oº¡ﬂˇ˛wÚÛÛπÂñ[xˇ˝˜È–°CeÕΩ˜ﬁÀ-∑‹¬®Q£ò4iW_}5m⁄¥°_ø~ˇÛ⁄Áü>ﬂˇ˛˜Ÿ≥gYYY Lö4â‚‚bŒ<ÛL ∆å√≥œ>ÀO<AÎ÷≠ô9s&?˙—è®SßßùvZÂµnæ˘fÓªÔ>Z¥hÒ?è±:ÁúsX∞`'NdÍ‘© ‰ÊÊ~i˝»ë#yË°áh“§	_|1ÁùwŸŸŸ<¸√dddÉ¸Ä#F¯„è‹sœ1bƒy‰:vÏ»|¿eó]Fff&^x·ˇ˛bKí$Ií$IäÈ ŸW°˝àIﬂ˙:1`SQ	«˛jÚ~’/º} ©˚˜üÚû={¯√˛¿≥œ>Kü>} xÊôgh‘®Qï∫n›∫qÛÕ7–¶MfÕö≈É>¯ï»Ä»ÃÃ‰ïW^·Ç. ‡˘ÁüÁÙ”O';;õ““RÓ∫Î.¶NùJ◊Æ]h—¢oΩıO>˘dï ‰ˆ€oˇ ˚‘®QÉ¨¨,íìì˜Î»´ÎØøû pı’WsÓπÁ2m⁄4∫uÎ¿%ó\R˘	Å…˝˜ﬂœYgù@ÛÊÕY∏p!O>˘§à$Ií$IíTçÄHGê+VPVV∆I'ùTπóóóG€∂m´‘}N|v˝–C}Âıììì˘¡~¿sœ=«\¿ﬁΩ{˘˚ﬂˇŒüˇ¸g ñ/_NqqÒÁÇç≤≤2:vÏXeØsÁŒ_Á≠Ì∑„é;ÆÚﬂÎ÷≠¿±«[eoÀñ-@p\ÿä+∏‰íK∏Ï≤À*k***˛ÁS&í$Ií$Ií‚œ D:@j§$±ˆ_Y7w’.z˙›Ø¨˚ìÈ“<oøÓ[ùú˛˘úv⁄ilŸ≤Ö)S¶P£FO† å7éÜV˘yiiiU÷ôôô•øîîî ˇÙË∞ˇﬁãF£U˙˝˝Ô_%4HJ™^_wIí$Ií$IUÄHH(⁄Ø£®z¥ÆC˝‹t6ñ|·êP/7ù≠ÎÏ◊êØ£eÀñ§§§Œ;Ô–§I vÓ‹…“•K´?5gŒú*?oŒú9Ï◊=N9Â7nÃ_˛Ú&Lò¿˜øˇ˝ Ä°}˚ˆ§••±vÌ⁄*˜˚∂RSSâDæz˛ ◊U∑n]4h¿ ï+9ˇ¸Û¯ı%Ií$Ií$< “!ñ1ÚªÌπ‚Ÿ˜	Aï‰”∏c‰w€ ++ãK.πÑn∏ÅZµjëüüœ·√	á√UÍfÕö≈=˜‹√gú¡î)S¯Î_ˇ ∏q„ˆ˚>ÁùwO<ÒKó.Âı◊_Ø‹œŒŒÊ˙ÎØÁ⁄kØ%ç“Ω{w
ô5k999ﬂx¶F≥fÕXµjÛÁœßQ£FdggÓâíoj‘®Q¸Úóø$77óÅRZZ {ÔΩ«Œù;:tËπá$Ií$Ií§/¸’%í¥Å«‘ÁÒù@Ω‹Ù*˚ır”y¸G'0ò˙Ìﬁ˜ﬁ{/=zÙ‡ªﬂ˝.}˚ˆ•{˜ÓtÍ‘©JÕu◊]«{ÔΩG«éπÛŒ;y‡Å*áÔèÛœ?üÖ“∞a√ ·‚ü∫„é;∏Ì∂€3f8êq„∆—ºyÛo¸ûŒ>˚lHØ^Ω®Sß/º¬7æ÷ªÙ“KyÍ©ßx˙Èß9ˆÿc9Ì¥”;vÏ∑ÍWí$Ií$I“¡ä≈b_t
ètƒ+**"77ó¬¬Brrr™ºVRR¬™U´hﬁº9ÈÈÈ_rÖØâ∆òªj[vóêüùNóÊyÂ…èØ“≥gO:tË¿C=D≥fÕ∏Êök∏Êöky
®__í$Ií$IÒÙø>_ìè¿í‚()¢kÀZÒnCí$Ií$IíéG`I⁄oœ=˜YYY_¯„Ë£è>h˜=˙Ë£øÙæœ=˜‹AªØ$Ií$Ií§√óOÄHb∆åïˇæzıÍ/≠;˝Ù”9È§ìæµîîî‹’å?ûÚÚÚ/|≠n›∫Ìæí$Ií$IM4kﬁÜ=õ!´.4=¬IÒÓJJ( íˆ[vv6ŸŸŸá¸æMõ6=‰˜î$Ií$I:hæoÇ¢ˇŸÀi ÌOè__RÇÒ,Ií$Ií$I:Tæ/˛∏j¯P¥1ÿ_¯Z|˙íêà$Ií$Ií$
—H‰±/xÒﬂ{oÍ$}k í$Ií$Iít(¨y˚ÛO~TÉ¢ıAù§oÕ Dí$Ií$Ií∂H9|¯¬˛’ÓŸ|p{ëéAó$Ií$Ií§É%É%„a Hÿælˇ~NV›É€ìtÑ	Iﬂ E]ƒgúQπÓŸ≥'◊\sM‹˙9êB°Øæ˙jº€ê$Ií$Iá´ıÛ`Ï¯ÛyA¯Q#èÚîl¢_4à∆`_çz–ÙîC€ßî†@§xäF`’õ—K¡?pø˙’ØË–°√Áˆ7n‹»†AÉ}Cí$Ií$È∂s5ºt1¸æ7¨ô…È–}(ë´>‡∂ÿ üA>]è*ˇ1?∂ïè¿í‚e·k0Ò¶™ÉØr¿¿_C˚”„◊WÇâ≈bD"íìø˛owıÍ’;Ií$Ií§Ñµo'ÃºÊ˛"e@é?zá‹FÃ]±ù?ÔÈ¿Œ5åL˘ÿQ˘S7QãQÂ0©¥ˇo’∫∂¨ø˜!%£D)æ/˛∏j¯P¥1ÿ_¯⁄Aªu4eÃò14oﬁú5jp¸Ò«Û“K/Uæ˛Ò«ÛùÔ|áúú≤≥≥È—£+V¨  â0tËPj÷¨I≠Zµ∏Ò∆â≈>ˇÃf4Â∆o$//èzıÍÒ´_˝jøz;ÔºÛ8Áús™ÏïóóSªvm˛Ùß?ÌWˇ3fÃ 
1a¬:uÍDZZoΩı÷óﬁsÏÿ±å5ä?¸êP(D(bÏÿ±@’#∞VØ^M(‚≈_§Gè‘®QÉO<ë•KóÚÓªÔ“πsg≤≤≤4h[∑n≠rèßûzäÇÇ“””i◊Æè=ˆÿ~}=$Ií$I“a¢¢ﬁ~Ó ≥	¬è=·ß3·Ã«!∑ 70)⁄ÖÓ•ø·áe∑ÚÀ≤_√≤[È^˙0ì¢] ÿ≤ª$NoDJ,>"(±îu]4næË∞«
ûi—¬I_}ΩîÖˆªÕ1c∆Ï≥œÚƒO–∫ukfŒú…è~Ù#Í‘©C´V≠8ı‘SÈŸ≥'”ßO'''áY≥fQQQ¿˝˜ﬂœÿ±c˘„ˇHAA˜ﬂ?ØºÚ
Ω{˜ÆrègûyÜ°CáÚŒ;Ô0{ˆl.∫Ë"∫uÎFø~˝˛goÁü>ﬂˇ˛˜Ÿ≥gYYY Lö4â‚‚bŒ<ÛÃØÏˇ¥”N´º÷Õ7ﬂÃ}˜›Gã-8Í®£æÙûÁús,`‚ƒâLù:Ä‹‹‹/≠9r$=ÙMö4·‚ã/ÊºÛŒ#;;õá~òåå~É0bƒ¸q û{Ó9Få¡#è<B«é˘‡É∏Ï≤À»ÃÃ‰¬/¸ü_Ií$IíTÕ≈bÒÀ0uÏZÏÂ∑á~w@´>ïüŸÏÿ[∆o¶-„ˇÊ¨Æ¸©Q¬Ãâ∂ˇ¬ÀÊgßÏŒ•#Çàt†î√]¿Öb¡ì!w7ﬁøÚ[6@jÊ~ïñññr◊]w1uÍT∫vÌ
@ã-xÎ≠∑xÚ…'i÷¨πππ¸˘œ&%%Ä6m⁄T˛¸ázàa√Üq÷YgƒO0i“§œ›Á∏„éc‰»ë ¥n›öGyÑi”¶}e 2`¿ 233yÂïW∏‡Ç x˛˘Á9˝Ù”…ŒŒ˛ ˛?Ä‹~˚Ì_y?Ä5jêïïErrÚ~yu˝ı◊3`¿  Ææ˙jŒ=˜\¶MõF∑n› ∏‰íK*ü Å 0πˇ˛˚+øfÕõ7g·¬Ö<˘‰ì í$Ií$Œ÷ºìoùd’é∫Íp~Â7µñîGxz÷jõ±ú›%¡7ò¶&á)´à~·%C@Ω‹t∫4œ;Ô@Jx “d˘ÚÂ.(++£c«éÏ⁄µã=zTÜüUXX»∆ç9È§ì*˜íììÈ‹πÛÁé¡:Ó∏„™¨Î◊Øœñ-[æ≤ø‰‰d~É‹sœq¡∞wÔ^˛˛˜øÛÁ?ˇyø˙ˇ¨Œù;Â˝æâœæ∑∫uÎpÏ±«VŸ˚ÙΩÓ›ªó+Vp…%ópŸeóU÷TTT¸œßL$Ií$IR5∂mL	K∆ÎîLË~tΩ≤ÚõT£—ØŒ_œ}ìñ∞°08Œ™}˝n\¿û“rÆxˆ}†Í˘ üûÔ1ÚªÌI
Ôˇiíæúàt†§dOc|ï5o√sﬂ˚Í∫Û_Ç¶ßÏﬂ}˜”û={ 7n6¨ÚZZZ◊\sÕ~_Î∂Ù_J("˝‚Ôl¯oÁü>ßùv[∂la î)‘®QÉÅ_›ˇgefÓﬂS1_◊gﬂ[Ëﬂè±˛˜ﬁßÔı”~ˇ˚ﬂW	é ííˆ„x3Ií$IíT}ÏŸ
o‹Ô=±Ñí‡ÑCœaê]∑≤l÷Úm‹5~o(†An:◊ıoÀô˛w∞Ò¯èN`‘?≤±?≥>ÍÂ¶3ÚªÌxL˝C˚æ§f "(°–˛E’≤7‰4û·êPzÀﬁ˚7‰khﬂæ=iii¨]ª∂ qQü:Ó∏„xÊôg(//ˇ\àëõõK˝˙ıyÁùw8ı‘SÅ‡IÜyÛÊq¬	'∞O9Â7nÃ_˛Ú&Lò¿˜øˇ˝ ^æ™ˇo*55ïH$r¿Æ˜©∫uÎ“†AVÆ\…˘Áü¿Ø/Ií$IíÅ≤bòÛ(ºı0îÌˆ⁄Ç~£†N€ ≤%õv3f¬"f,Ÿ
@vZ2WÙj…≈›öìûRı3ûÅ«‘ß_˚zÃ]µÉ-ªK»œéΩÚ…È¿2 ëµp¸5º¯cÇáø‡a«Åw ;;õÎØøûkØΩñh4J˜Ó›),,d÷¨Y‰‰‰ã_¸Çﬂ˛ˆ∑¸á?dÿ∞a‰ÊÊ2gŒ∫tÈB€∂mπ˙Í´π˚Óªi›∫5Ì⁄µ„Å`◊Æ]ºœÛŒ;è'ûxÇ•KóÚ˙ÎØÔwˇﬂt¶F≥fÕXµjÛÁœßQ£FdggÓâíoj‘®Q¸Úóø$77óÅRZZ {ÔΩ«Œù;:tËπá$Ií$I:¢¯œ0˝Nÿ˝ÔS?ÍwÄ˛wBÛïeõãJx`ÚR˛:o—$áC¸Ë‰¶\’ªµ≤æ¸ÛÖ§pàÆ-k‰7!Ÿ@§xh:¸‡O0Ò¶`‡˘ßr·G˚”⁄≠Ô∏„Í‘©√ò1cXπr%5k÷‰ÑN‡ñ[n°V≠ZLü>ùn∏Å”N;ç§§$:tËP9‡˚∫ÎÆc„∆ç\x·ÖÑ√a.æ¯bŒ<ÛL
hèÁü>£Gè¶i”¶ï˜ﬁü˛ø©≥œ>õó_~ô^Ωz±k◊.û~˙i.∫Ë¢o˘.ó^z)‹{ÔΩ‹p√dffrÏ±«∞„∆$Ií$I“A∞|LõÎ‹&–gs6Ñ√ Ï)≠‡wo¨‡˜oÆb_yp≤ƒ†cÍq„¿v4Ø}péÊñÙıÑbˇ=ΩX EEE‰ÊÊRXXHNNNï◊JJJXµjÕõ7'==˝õﬂ$	fÇÏŸYuÉô·…^ÿØ/Ií$IíÙılZ SnÉ”ÉuZ.úz=tπRÇø£WD¢¸ÂΩu<8e€ˆîpBìöR@ß¶yÒÍºZ˙_üØIáÇOÄHÒN™Ú»§$Ií$Ií‚†hLÛübNÅ.ó¡©7@Fjƒb1¶-⁄¬›≥|À ö’ ‡¶ÅÌxL=B!ÁwH’çà§CÊπÁû„ß?˝Èæ÷¥iS>˛¯„Érﬂ£è>ö5k÷|·kO>˘§ %Ií$I:RïÓÜ∑ÇŸèB≈æ`ÔË3É„ÆÚZTñ}∏nwç_ƒ;´v pTF
W˜iÕy'5%59á∆%ÌIáÃÈßüŒI'ùÙÖØ•§§¥˚é?ûÚÚÚ/|≠n›∫Ìæí$Ií$©öäî√˚œ¿åªaÔ÷`ØÒ…¡ÄÛ∆'Vñ≠€QÃΩìñ⁄á¡◊¥‰0woŒ=[íì~>Àêt`ÄH:d≤≥≥…ŒŒ>‰˜m⁄¥È!øß$Ií$I™Üb1X2¶åÑÌÀÇΩºñ–o¥˚¸˚´¬‚ry}œºΩÜ≤HîPŒÏÿêÎ˚∑•AÕq|íæIí$Ií$Iâo˝<ò|¨ô¨3jAœa–È"H
ûÊ(≠à≥◊€ÈÀ)‹ú&—ΩUmn‘écÊ∆©qIﬂîàÙ-D£—x∑†‰Ø+Ií$Ií†ù´a⁄Ì∞‡o¡:9N˛9tø“ÉP#ãÒèm‰ﬁIãY∑#ò“∂n6√∑„¥6up.¶@§o 55ïp8ÃÜ®Sß©©©˛èPﬂZ,£¨¨å≠[∑áIMMçwKí$Ií$æˆÌÑô˜¡‹ﬂA§¡ÒÁBÔ·ê€®≤Ïùï€πk¸">¸§Ä∫9i\◊Ø-gwjDRÿœ{§√ôàÙÑ√aö7oŒ∆çŸ∞aCº€QÇ…»»†Iì&Ñ√·x∑"Ií$I“·ß¢Ê˛fﬁ%ªÇΩ=°ﬂPˇ∏ ≤Â[ˆp˜Ñ≈L]¥ÄÃ‘$~vZK.È—úåT?6ïÅˇ%KﬂPjj*Mö4°¢¢ÇH$Ôvî íííHNNˆâ"Ií$IíæÆX>~¶éÇ]kÇΩ¸ˆA—™OÂÄÛ≠ªKyhÍR˛¸Ó:"—I·ÁviÃ’}⁄P';-éo@“Åf "}°PàîîRRR‚›ä$Ií$I“ëkÕ€0˘÷`–9@VΩ‡®´ÁC8	Ä‚≤
ûzsOæ±ÇΩe¡7≥ˆk_óõ∂£U~Vº:ótÄHí$Ií$I:<m[SF¬íq¡:%3nﬁıJHÕ çÒ“ºu<0e)õãJ8æQ.∑.‡§µ‚‘∏§C¡ Dí$Ií$I“·eœVx„nxÔiàE î'¸zÉÏ∫ ƒb1f,› ›„≥dÛn Á’‡ÜÌ¯Œ±ı	;‡\Jx í$Ií$Iíe≈0ÁQxÎa(B⁄Ç~£†N€ ≤Î3a≥ño ∑F
Wın≈]õíñúèŒ%≈Åà$Ií$Ií§Í-Åˇ”ÔÑ›ÇΩ˙†ˇù–ºGeŸ˙]˚∏“^ôøûXRì¬\xJS~—´5πŒpïé4 í$Ií$Ií™ØÂ”` ÿº XÁ6Å>#‡ò≥!†®§ú«^_¡g≠¢¨"
¿È«7‡ÜmiúóØŒ%≈ôà$Ií$Ií§Íg”òr¨ò¨”r·‘Î°ÀÂêí@YEîÁﬁY√o¶-cgq9 '5œc¯êékT3NçK™.@$Ií$Ií$UE`˙hòˇÉp
tπNΩ2ÚÄ`¿˘Ñõ∏g‚bVo/†eùLÜ*†OA>°êŒ%ÄHí$Ií$I™Jw√[¡ÏG°b_∞wÙô¡qWy-*ÀÊ≠Ÿ¡ËqãxÌ. jg•qmø÷ú”π1…I·Cﬂ∑§jÀ Dí$Ií$IR¸D ·˝g`∆›∞wk∞◊§k0‡ºQÁ ≤U€ˆrœƒ≈LX∞	Ä)I\vj.?µYi~Ã)ÈÛ¸ùAí$Ií$I“°ã¡íÒ0e$l_ÏÂµÑ~∑Cª!Ôc¨vÏ-„7”ñÒÏú5TDcÑCÉŒçπ∂_ÍÊ§«ÒH™Ó@$Ií$Ií$ZÎÁ¡‰€`Õ¨`ùQzÉNAR
 %Â˛8kèøæÇ›• Ùj[áõ–∂^vúót81 ë$Ií$IíthÏ\”ná÷…È–ıJËv§Á ç∆xÂÉı‹?y	
K 8∫A√pJ´⁄ÒÈ[“a… Dí$Ií$I“¡µo'ÃºÊ˛"e@é?zá‹Fïeo-€∆]„±pc k÷‡˙m¯«7$≈©yIá+Ií$Ií$IGE)Ã˝=ÃºJv{-zBø;†˛qïeã71f¸bﬁXAœNOÊ ^≠∏Ëîf§ß$˙æ%%Ií$Ií$IV,øSG¡Æ5¡^~˚ ¯h’ßr¿˘¶¬ò≤ÑóÊ}B4)I!~trSÆÍ›öºÃ‘8æIâ¿ Dí$Ií$I“Å≥Êmò|k0Ë ª>ÙŒÉp4«û“
û|cøs%%ÂQ Ü[ü∂•i≠Ãxu.)¡ÄHí$Ií$I˙ˆ∂-É)#a…∏`ùö›ÆÜúß°Fy$ üﬂ]«√Só≤mO ùö≈-ÉË‘Ù®xu.)AÄHí$Ií$I˙ÊˆlÖ7ÓÜ˜ûÜXBI–ÈBË9≤Úà≈bLY∏ôª'.fÂ÷Ω 4Øù…M€1‡Ë∫ÑB8ót‡ÄHí$Ií$I˙˙ äaŒ£÷√P∂;ÿk3˙çÇ:m+ÀÊØ€≈]„1wı Ú2Sπ¶okŒÌ“Ñî§p<:ótÑ0 ë$Ií$Ií¥ˇ¢¯œ0˝NÿΩ!ÿk–˙ﬂ	Õ∫Wñ≠›^Ã=ìÛœm -9Ã•=öÛ≥”ZíùûèŒ%a@$Ií$Ií$ÌüÂ”` ÿº XÁ6Åæ#·Ë≥ <Õ±´∏åﬂN_ŒüfØ¶<#Ç≥:6‚∫˛mhP≥Fõót§1 ë$Ií$IíÙømZ SnÉ”Éuz.Ù∏∫\)È îîG¯”Ï’<2}9E% Ùh]õaÉ
hﬂ '^ùK:ÇÄHí$Ií$I˙bE`˙hòˇÉpJzúz=d‰ç∆¯«ø6pÔ§%|≤s ÌÍe3lpßµ©«Ê%È@$Ií$Ií$UU∫ﬁzf?
A®¡—gBüê◊¢≤lˆäÌåô∞à}R@›ú4ÆÎﬂñ≥OhDR8á∆%È?@$Ií$Ií$"Â˛30„nÿª5ÿk“5pﬁ®seŸÚ-ª3~1”o +-ôüù÷ÇK∫∑†FjR<:ó§œ1 ë$Ií$Iíét±,SF¬ˆe¡^^KËw;¥°‡ié-ªKxhÍ2˛ÚÓ:"—I·Áui¬’}[S;+-éo@í>œ Dí$Ií$I:í}2/pæfV∞Œ®=áAßã )Ä‚≤
~?sOŒ\AqYÄ˛ÌÎr”†v¥¨ìß∆%È3 ë$Ií$IíéD;W√¥€a¡ﬂÇur:tΩ∫]È9 D¢1˛˙ﬁ:ò≤î-ªKË–∏&∑.†KÛº¯Ù-I˚… Dí$Ií$I:íÔÄ7ÔáπøÉHÇ„œÖﬁ√!∑ ±XåK∂2f¬"ñnﬁ@ìºnÿñ!«÷'r¿π§Íœ Dí$Ií$I:Tî°«Ã˚†dW∞◊¢'ÙªÍWY∂`}!wç_ƒ€+∂P3#Ö´z∑ÊG'7!-ŸÁí í$Ií$IR"ã≈ÇcÆ¶›ª÷{˘ÌÉ‡£Uü ÁüÏ,Ê˛…KyÂÉı §&á˘…)Õ¯yœV‰f§ƒ´{I˙∆@$Ií$Ií§DµzLæ6º¨≥ÎCØ·–·<OsÓ+Á±Àyz÷j *¢ ú—°◊hK££2‚’π$}k í$Ií$IR¢Ÿ∂¶åÑ%„Çujtª:rûö	@YEîgÁ¨·∑”ó±≥∏Äì[‰qÀ‡ékT3NçK“Åc "Ií$Ií$%ä=[a∆ò7b%Aß°Á0» ÇÁ„?⁄ƒ=ì≥f{1 ≠Û≥6∏Ω⁄Ê;‡\R¬0 ë$Ií$Iíwe≈0ÁQxÎ!(€Ïµ˝FAù∂ïeÔ≠ﬁ¡ËÒã¯`Ì. Ídß1¥_æﬂ©…I·Cﬂ∑$D í$Ií$I“·*Å_ÄÈ£a˜Ü`ØAGË'4Î^Y∂rÎ~=q1ì>ﬁ@çî$~zZ.Î—ÇÃ4?"îîò¸›Mí$Ií$I:-üSF¿Ê¡:∑	Ù	Gü·‡iéÌ{Jyx⁄2ûg-—·úsbcÆÌ€Ü¸úÙ86/Iüà$Ií$Iít8Ÿ¥ ¶‹+¶ÎÙ\Ëq=tπRÇPc_YÑ?ŒZ≈„3V∞ß¥Ä>ÌÚπiP;⁄‘ÕéWÁítHÄHí$Ií$IáÉ¬ı˙hòˇ<ÉpJzúz=d‰â∆x˘˝Ox` R6ñ pL√n\¿)-k«±yI:Ù@$Ií$Ií§Í¨§f=≥Öä}¡ﬁ—gBüê◊¢≤lÊ“≠åô∞òEã hX≥7hÀÈ«7 ≈£sIä+Ií$Ií$©:äî√º±0„n(ﬁÏ5È8o‘π≤l—∆"Óøà7ó5ŸÈ…¸¢W+.<•È)Iqh\í™Ií$Ií$©:â≈`…xò2∂/ˆÚZBø€°›Osl*,·˛…KxÈ˝Oà≈ %)ƒ'7„™ﬁ≠8*35éo@í™Ií$Ií$©∫¯dLæ÷æ¨3jAœa–È"HJ`wI9Oº±Ç?ºµäíÚ( Cé´œç⁄“¥Vfúó§Í« Dí$Ií$Iä∑ù´a⁄Ì∞‡o¡:9∫^	›ÆÅÙ  #Q^òªñáß.c˚ﬁ2 Nlv∑.†cì£‚”∑$Uc í$Ií$IRºÔÄ7ÔáπøÉHÇ„œÖﬁ√!∑ ±Xå…7ÛÎ	ãYπm/ -jgr”†vÙo_óP»ÁíÙE@$Ií$Ií§C≠¢4=fﬁ%ªÇΩ=°ﬂPˇ∏ ≤÷Ó‰ÆÒãxwıN je¶rMﬂ÷¸∞KRí¬áæoI:åÄHí$Ií$IáJ,s5Ìvÿµ&ÿÀo≠˙T8_≥}/˜LZ¬∏m =%Ã•›[””ZêùûØÓ%È∞b "Ií$Ií$
´gŒ7º¨≥ÎCØ·–·<'∞soøùæúˇõ≥öÚHåPæwB#ÜˆoC˝‹ql^í? í$Ií$I“¡¥mL	K∆Î‘,Ëvu0‰<5ÄíÚœºΩöG^_ŒÓí
 NmSáaÉ⁄QP?'^ùK“aÕ Dí$Ií$I:ˆlÖc`ﬁXàE îù.Ñû√ +Äh4∆kn‡ﬁIKXøk ıs∏ep;z¥Æ«Ê%Èg "Ií$Ií$He≈0ÁQxÎ!(€Ïµ˝FAù∂ïeoØÿ∆]„±`} ıs”πÆ[ŒÏÿê§p(çKRb1 ë$Ií$IíÑh>|¶èÜ›ÇΩ°ˇù–¨{eŸ≤Õª3a1”o +-ô+z∂‰íÓÕIOIäGÁíîê@$Ií$Ií§ok˘4ò26/÷πM†ÔH8˙,áÿRT¬ÉSóÚów◊çAr8ƒy'5·ó}ZS;+-éÕKRb2 ë$Ií$Iíæ©M` m∞bz∞NœÖ◊CóÀ!%ÄΩ•¸nÊJ~ˇÊJäÀ" <∫7lKã:YÒÍ\íûà$Ií$IíÙuÆá◊G√¸ÁÅÑSÇ–„‘Î!#ÄäHîﬂ˚Ñß.eÎÓR :6©…¡tnñ«Ê%È»` "Ií$Ií$ÌØí"òı0Ã~*ˆ{Gü	}F@^ b±”o·Ó	ãY∂%Çﬁ¥V7h«‡cÎ
9‡\íIí$Ií$È´D aﬁXòq7oˆötú7Í\Yˆ—'Öåøê9+w P3#Ö_ˆnÕèNnJjr8çK“ëÀ Dí$Ií$I˙2±,SF¬ˆe¡^^KËw;¥ˇ~öc›ébÓõºÑøœﬂ @jròütk∆œ{∂"∑FJº∫ó§#öà$Ií$IíÙE>ôìoÖµoÎåZ–st∫íÇP£∞∏úGg,gÏ¨’îE¢ úŸ±!◊ıoC££2‚‘∏$	¿ÁÓt@ç3ÜO<ëÏÏlÚÛÛ9„å3X≤dIïöííÆºÚJj’™EVVgü}6õ7oÆR≥vÌZÜBFF˘˘˘‹p√TTTT©ô1c'úpiii¥j’ä±c«~ÆüG}îfÕöëûûŒI'ùƒ‹πs¯{ñ$Ií$I	fÁjxÈbx™w~$ßCèÎ‡óÛ°ÀeêîBiEÑßﬁ\…i˜ΩŒÔfÆ§,Âîñµ¯ÁU›yúÜíTÄËÄz„ç7∏Ú +ô3gS¶L°ººú˛˝˚≥wÔﬁ ökØΩñ¸„¸ıØÂç7ﬁ`√Üúu÷YïØG"ÜBYYoø˝6œ<Ûc«éeƒàï5´V≠b»ê!ÙÍ’ã˘ÛÁsÕ5◊pÈ•ó2i“§ öø¸Â/:îë#GÚ˛˚Ôs¸Ò«3`¿ ∂lŸrhæí$Ií$ÈRº&áGNÑBp¸yp’º`»yz±Xå˛k}xÉ;«-bWq9mÍfÒÙE'Ú‹•'qL√‹xøI“øÖb±X,ﬁM(qm›∫ï¸¸|ﬁx„N=ıT
©Sßœ?ˇ<ﬂ˚ﬁ˜ Xºx1Ãû=õìO>ô	&ùÔ|á6P∑n] ûx‚	n∫È&∂n›Jjj*7›t„∆çc¡Çï˜˙·»Æ]ªò8q" 'ùt'ûx"è<Ú —hî∆çs’UWqÛÕ7eÔEEE‰ÊÊRXXHNNŒÅ˛“Hí$Ií§Í¢¢Ê˛fﬁ%ªÇΩ=°ﬂPˇ∏ ≤wWÔ`Ù∏EÃ_‘‰gß1¥_æ◊©…I~ü±Ùﬂ¸|MÒÊÔÃ:®
»ÀÀ`ﬁºyîóó”∑oﬂ övÌ⁄—§Ifœû¿ÏŸ≥9ˆÿc+√ÄPTTƒ«\YÛŸk|ZÛÈ5   ò7o^ïöp8Lﬂæ}+k˛[ii)EEEU~Hí$Ií§ã¡G/O|Læ5?Ú€√˘É^≠?Vl›√ÂzèÔ?1õ˘Îvëëöƒµ}€0„Üû¸∞K√I™¶ÇÆÉ&çrÕ5◊–≠[7é9Ê 6m⁄Djj*5k÷¨R[∑n]6m⁄TYÛŸ„”◊?}Ì’±oﬂ>vÓ‹I$˘¬ö≈ãaøc∆åa‘®QﬂÏÕJí$Ií§√ÀÍYAË±·˝`ù]záÁA8	Äm{JyxÍ2ûüªñH4FR8ƒ9'6Êöæ≠…œNècÛí§˝a ¢ÉÊ +Ød¡Çºı÷[Òneø6å°CáVÆãääh‹∏q;í$Ií$I‹∂e0e$,¨S≥†€’–ıJHÕ`_YÑ?ºµí'ﬁX…û“
 ˙‰sÛ†v¥ œéWÁí§Ø… D≈/~Ò˛˘œ2sÊL5jTπ_Ø^=   ÿµkWïß@6oﬁLΩzı*kÊŒù[Âzõ7oÆ|Ì”~∫˜Ÿöúúj‘®ARRIII_XÛÈ5˛[ZZiiiﬂÏKí$Ií§ÍmœVò1ÊçÖXBI–ÈBË9≤ÚàDc¸Ì˝Ox`ÚR6ï p\£\Ü*†kÀZql^íÙMx@°®X,∆/~Ò^yÂ¶OüNÛÊÕ´ºﬁ©S'RRRò6mZÂﬁí%KXªv-]ªv†k◊Æ|Ù—GlŸ≤•≤f î)‰‰‰–æ}˚ öœ^„”öOØëööJßNù™‘D£Q¶MõVY#Ií$Iíé e≈0Û^¯MxÔA¯—f¸|6|Á¡ „ç•[Úõ7πÒ•±©®ÑFG’‡·v‡’üw3¸ê§√îOÄËÄ∫Ú +y˛˘Á˘˚ﬂˇNvvvÂÃé‹‹\j‘®Ann.ó\r	Cá%//èúúÆ∫Í*∫vÌ …'ü@ˇ˛˝iﬂæ=\p˜‹sõ6m‚÷[oÂ +Ø¨|B„g?˚è<Ú7ﬁx#_|1”ßOÁ≈_d‹∏qïΩ:î/ºêŒù;”•KzË!ˆÓ›ÀO~ÚìCˇÖë$Ií$IáV4æ ”G√Ó¡^Éé–ˇNh÷Ω≤l·Ü"∆LXƒõÀ∂êìûÃUΩ[Û„SöíñúèŒ%IH(ã≈‚›ÑG(˙¬˝ßü~öã.∫ÄííÆªÓ:^x·JKK0` è=ˆXï£©÷¨Y√W\¡å3»ÃÃ‰¬/‰ÓªÔ&9˘?ô›å3∏ˆ⁄kY∏p!ç5‚∂€n´º«ßy‰ÓΩ˜^6m⁄Dá¯Õo~√I'ù¥_Ô•®®à‹‹\
………˘z_Ií$Ií?Àß¡î∞yA∞Œm}G¬—gA88ec·>Óõ¥îó?¯ÑXRì¬¸∏kS~—ª53R„ÿºî8¸|MÒf "}	Éñ$Ií$È0≥iLπVL÷Èπ–„zËr9§§PTRŒ3Vá∑VQZ‡ª«7‡∆miúóØŒ•Ñ‰Ákä7è¿í$Ií$I“·≠p=º>Ê?ƒ úÑß^y îG¢<ˇŒZû∂å{À Ë“,è[Ü–°qÕ¯ı.I:h@$Ií$Iítx*)ÇY√ÏG°b_∞wÙô–g‰µ  ã1È„M¸z‚Vm€@ã:ô‹<∞˝⁄◊˝“„º%Iá?Ií$Ií$^"Â0o,Ã∏äÉ·Â4È8o‘π≤lﬁöùåøà˜÷Ï†vV*W˜m√OlLJR8çKí%Ií$Ií$b1X2¶åÑÌÀÇΩºñ–Ôvh7˛˝4«Ím{πg“b∆¥	ÄÙî0óıh¡OOkIVöáI“ë¬ﬂÒ%Ií$IíT˝}2&ﬂ
kﬂ÷µ†Á0Ët$• ∞coøô∂åÁﬁYCy$F(ﬂÔ‘à°˝⁄R/7=~ΩKí‚¬ Dí$Ií$I’◊Œ’0ÌvX∑`ùú]ØÑn◊@z %Âûûµö«f,gwI ßµ©√∞¡ÌhW/'>}Kí‚Œ Dí$Ií$I’OÒxÛ~ò˚;àî!8˛\Ë=rç∆¯˚áÎπw‚6ñ –æ~∑.†{Î⁄ql^íTÄHí$Ií$©˙®(Bèô˜A…Æ`ØEOËw‘?Æ≤ÏÌÂ€∏k¬"¨/†~n:◊˜oÀôá}ﬂí§j« Dí$Ií$IÒã«\Mªv≠	ˆÚ€¡G´>ïŒól⁄Õò	ãò±d+ Ÿi…\—´%wkNzJRº∫ó$UC í$Ií$IäØ’≥ÇÁﬁ÷Ÿı°◊pËpÑÉPcKQ	LY ãÔ≠#É‰pàù‹î´z∑¢VVZõó$UW í$Ií$IäèmÀ` HX2.XßfA∑´É!Á©ô Ï-≠‡…ô+˘˝ÃïÏ+è 0Ëòz‹8∞Õkg∆´sI“a¿ Dí$Ií$Iá÷û≠0cÃ±Ñí†”Ö–sdÂPâÚó˜÷Ò‡îel€S
¿	Mj2|HùöÊ≈±yI“·¬ Dí$Ií$IáFY1Ãyﬁz ˆ{mAøQPß- ±Xåiã∂p˜ƒ≈,ﬂ‘4´ï¡M€1òzÑB8ó$ÌIí$Ií$\—|¯Lª7{:Bˇ;°Y˜ ≤}≤ã—„ÒŒ™ ïë¬’}ZsﬁIMIM«£sI“aÃ Dí$Ií$IœÚi0el^¨sõ@ﬂëpÙYBçu;äπw“^˚0G“í√\‹Ω9WÙlINzJº:ó$Ê@$Ií$Iít‡mZ SnÉ”Éuz.Ù∏∫\)È óÛ»ÎÀxÊÌ5îE¢ÑBpf«Ü\◊ø-k÷àcÛí§D` "Ií$Ií§ßp=º>Ê?ƒ úÑß^¡Ú“äˇ7{øùæú¬}Â tkUãaÉ
8¶anõó$%Ií$Ií$}{%E0Î!ò˝TÏˆé>˙åÄº@0‡¸ˇ⁄»Ωì≥nGP”∂n67nGœ6up.I:†@$Ií$IíÙÕE aﬁXòq7oˆötú7Í\YˆŒ Ì‹5~~R@~v◊ıo√˜:5&)l!I:@$Ií$IíÙı≈b∞xL	€ó{y-°ﬂÌ–n¸˚iéÂ[ˆp˜Ñ≈L]¥ÄÃ‘$~vZK.È—úåT?öí$<˛_Fí$Ií$I_œ'Ô¡‰€`Ì€¡:£Ùù.Ç§ ∂Ó.Â°©K˘ÛªÎàDc$ÖC¸ƒ∆\”∑u≤”‚◊ª$Èàa "Ií$Ií§˝≥cLª>~9X'ßC◊+°€5êû@qYOΩπä'ﬂX¡ﬁ≤ }ÍrÛ†v¥ œäS„í§#ëà$Ií$Ií˛∑‚0Û>ò˚;àñ!8˛\Ë=râ∆xiﬁ:ò≤îÕE• ﬂ(ó[pRãZql^ít§2 ë$Ií$I“´(Bèô˜BI0ºú=°ﬂPˇ8 b±3ñnÂÓÒãY≤y7 çé™¡ç€ÒùcÎv¿π$)N@$Ií$IíTU4s5mÏZÏÂ∑ÇèV}*ú/X_»ò	ãòµ|; π5R∏™w+.Ë⁄î¥‰§xu/I` "Ií$Ií§œZ=&ﬂ
ﬁ÷Ÿı°◊pËpÑÉPc√Æ}‹7y	Ø|∞ûXRì¬\xJS~—´5π)ql^í§ˇ0 ë$Ií$Il]
SG¬íÒ¡:5∫]9OÕ†®§ú«g¨‡èo≠¢¥"
¿È«7‡ÜmiúóØŒ%I˙B í$Ií$IG≤=[`∆›0o,ƒ"JÇNBœaêï@YEîÁﬂY√o¶/g«ﬁ2 Njû«-É8æqÕ¯ı.I“ˇ` "Ií$Iít$*+ÜŸè¬¨á†lO∞◊fÙu⁄¡ÄÛ	6qœƒ≈¨ﬁ^@À:ôT@üÇ|B!úKí™/Ií$Ií§#I4æ ”ÔÑ›ÉΩ°ˇù–¨{eŸº5;=nÔØ›@Ì¨4ÆÌ◊ös:7&9)á∆%I˙z@$Ií$IíéÀß¬‰∞Â„`ù€˙éÑ£œÇpj¨⁄∂ó{&.f¬ÇM ‘HI‚≤S[p˘©-»JÛ£$I“·√ˇkIí$Ií$%∫M¡‰€`ÂÎ¡:=z\].áît vÏ-„7”ñÒÏú5TDcÑCÉŒçπ∂_ÍÊ§«±yIíæIí$Ií§DU∏^ÛübN	BèSØáå< J #¸q÷*}ªK+ Ë’∂7*†mΩÏ86/I“∑c "Ií$IíîhJäÇ·Ê≥Éä}¡ﬁ—gAüê◊Äh4∆+¨Á˛…KÿPXî4»·ñ¡tkU;NçKít‡ÄHí$Ií$%äH9Ã3ÓÜ‚m¡^ìÆ¡ÄÛFù+ÀﬁZ∂çª∆/b·∆" ÷¨¡ı⁄ˇéoH8äC„í$x í$Ií$IáªXèÉ©#a˚Ú`ØV+Ë;
⁄ÅPj,ﬁTƒòÒãycÈV ≤”ìπ≤W+.:•È)IÒÍ^í§É¬ Dí$Ií$Èpˆ…{¡ÄÛµoÎå⁄–ÛfËt$• ∞©∞Ñ¶,·•yüçAr8ƒ]õrUÔ÷‰e¶∆ØwIí"Ií$Ií§√—éU0Ìv¯¯Â`ùú]ØÑn◊@z {J+xÚç¸˛ÕïîîG|l=n–éfµ3„‘∏$IáÜà$Ií$I“·§xÃºÊ˛¢Â@:úΩÜCnC *"Q^xwO] ∂=e tjz∑.†S”£‚ÿº$Iáéà$Ií$I“·†¢4=fﬁ%Ö¡^ã^–ˇ®w, ±Xå)7s˜ƒ≈¨‹∫ÄÊµ3πi`[]èP»Áí§#áà$Ií$IRuç«\Mª÷{˘GCˇ€°Uﬂ ≤˘Îvq◊¯EÃ]µÄºÃTÆÓ”öÛNjBJR8ùKíW í$Ií$I’’ÍY0˘Vÿ~∞ŒÆu’·<'∞v{1˜LZÃ?ˇµÄ¥‰0ótoŒœz∂$'=%^ùKíw í$Ií$I’Õ÷•0u$,¨S≥Ç·Ê]©¡Ú]≈e¸v˙r˛4{5Âë°ú’±◊ıoCÉö5‚◊ª$I’Ñà$Ií$IRu±gÃ∏ÊçÖXBI–ÈBË9≤Ú()è≥◊€ÈÀ(*© †GÎ⁄‹<®G7»çcÛí$U/ í$Ií$IÒVV≥ÖYAŸû`ØÌ`Ë;
Í¥ çÒèm‡ﬁIK¯dÁ> ⁄’Àfÿ‡NkS'NçKíT}ÄHí$Ií$≈K4æ ”ÔÑ›¡ú ˝ÔÄf›+ÀÊ¨‹Œ]„ÒØO
®õì∆u˝€rˆ	çH
á‚—π$I’ûà$Ií$IR<,ü
ìG¿ñèÉuÕ&–g$}Ñ√A…ñ›‹=a1Sm 35â+z∂‰íÓ-®ëöØŒ%I:,ÄHí$Ií$Jõ>Ç…∑¡ ◊Éuz.úztπí” ÿ≤ªÑá¶.„/ÔÆ#çëq^ó&\›∑5µ≥“‚ÿº$IáIí$Ií§C°p=º>Ê?ƒ úÑß^y óU˚ô´xrÊ
äÀ" Ùo_óõµ£eù¨86/I“·« Dí$Ií$È`*)
Üõœ~*Ç·Â}ÙyÕàDc¸ıΩu<0e)[vóp|„ö\@óÊyqj\í§√õà$Ií$I“¡)áyca∆›Pº-ÿk“˙ﬂ	ç:ã≈ò±d+c&,bÈÊ=AI^7lÀêcÎ
9‡\í§o  Dí$Ií$È@ä≈`Ò8ò:∂/ˆjµÇæ£†›¯w®±`}!wç_ƒ€+∂P3#Ö´z∑ÊG'7!-ŸÁí$}[ í$Ií$I 'ÔŒ◊æ¨3jCœõ°”Eêî¿˙]˚∏o“^˘`= ©Ia~“≠?ÔŸä‹åî85.IR‚1 ë$Ií$I˙∂v¨Çi∑√«/Î‰tËz%tª“s (‹WŒc3ñÛÙ¨’îUD¯p}ˇ∂4ŒÀàS„í$%.Ií$Ií§o™xÃºÊ˛¢Â@:úΩÜCnC  *¢<;gøùæåù≈Â ú‹"è[p\£öÒÎ]í§g "Ií$IíÙuUî°«Ã{°§0ÿk—˙ﬂıéÇÁ„?⁄ƒ=ì≥f{1 ≠Ú≥∏ep;zµÕw¿π$Iôà$Ií$I“˛äFÉcÆ¶çÇ]kÉΩ¸£°ˇÌ–™oeŸ{´w0z¸">XªÄ⁄YiÌ◊ÜtnDrR8çKít‰1 ë$Ií$I⁄´g¡‰[a√˚¡:ª~p‘UáÛ ú¿ ≠{¯ıƒ≈L˙x3 5Rí∏¸‘\~j2”¸Fí§C…ˇÛJí$Ií$D#∞Êmÿ≥≤ÍB”SÇ`cÎRò:ñåÍR≥Ç·Ê]©ô lﬂS √”ñÒ¸;k©à∆á‡úsmﬂ6‰Á§«Ô=Iít3 ë$Ií$IZ¯Lº	ä6¸g/´‘=VŒÄXBI–ÈBË9≤ÚÿW·è≥VÒ¯åÏ)≠ †wª|n‘é6u≥„F$I“ß@$Ií$I“ëm·k‚èÅX’˝=õÇ mCﬂQPß ëhåóﬂˇÑ¶,eca	 «4Ã·ñ¡ú“≤ˆ!l^í$}Ií$Iít‰äFÇ'?˛;¸¯¨å⁄pŒ≥ïs>ﬁ\∂ïª∆/f—∆" ÷¨¡⁄r˙ÒáCá†iIí¥?@$Ií$I“ëkÕ€UèΩ˙"≈€`Õ€,J?û13sÈV ≤”ì˘EØV\xJ3“SíA≥í$ÈÎ0 ë$Ií$IGÆOﬁ›Ø≤Á¶ÕÂ÷Eƒbêí‚ÇìõqUÔVïôzêî$Iﬂîà$Ií$I:ÚÆá◊G√¸Áˆ´¸+£ƒb0‰∏˙‹8†-Mke‰%I“∑e "Ií$Iíé%E0Îaò˝(TÏ íîN®¢Ñ/ﬂç¡&jk|2Ø9ÜéMé:ƒKí§o*Ô$Ií$Ií∫H9Ã˝=¸¶#ºy_~4ÈJ‰‚©˝¬éœ˙t}¯'<wy7√Ií3 í$Ií$)q≈b∞x<÷∆_4œk	Á<?ô¿‹Ú¸yOÆ(øÜM‰U˘©õ®≈Â◊∑}'ÓÍùqzí$ÈõÚ,Ií$Iíîò÷œÉ…∑¡öY¡:£Ùù.Ç§ ñl.`R¥SJ;”%ºò|v±ÖöÃç∂#˙ÔÔ›≤ª$Ô@í$} í$Ií$)±Ï\”ná÷…ÈpÚœ°˚5êû¿Óírõ±Çﬂœ\Y˘”¢ÑômˇÖóÃœN?»MKí§Õ Dí$Ií$%Ü};aÊ}0˜w)Bp¸π–{8‰6†"ÂÖπkyhÍ2∂Ô- 5)DY$ˆÖóır”È“<Ô_ó$I’óà$Ií$I:ºUîŒgﬁ%ªÇΩÊßAˇ;°˛q ƒb1¶/ﬁ¬]„±bÎ^ Z‘…‰ñAîG¢¸¸π˜É∫œ\6ÙÔé¸n{í¬!$I“·≈ Dí$Ií$ûb1¯¯eò:
v≠	ˆÚ€Cø€°U_°≈ÇıÖå∑àŸ+∑êóô 5}[snó&§$3>ˇ—	å˙«B6˛g÷GΩ‹tF~∑=è©hﬂó$I: @$Ií$I“·gÕ€0˘÷`–9@VΩ‡®´ÁC8	ÄçÖ˚∏w“^˘`=±§&áπ∏[s~ﬁ´%9È)U.7ò˙Ùk_èπ´v∞ew	˘Ÿ¡±W>˘!I“·À Dí$Ií$>∂-á©#aÒ?ÉuJ&tªN˘§f∞ß¥Ç'f¨‡©∑VRR‡ˇuh¿ı˝€“8/„K/ù—µe≠É˛$I“°a "Ií$Ií™øΩ€`∆›0ÔiàV@('\=áAv] p˛‚{ü¿î•l€S
@ófyR¿Òçk∆±yIí í$Ií$©˙*+Ü9è¡[AŸÓ`ØÕ@Ë;
Ú€¡ÄÛK∑2f¸"ñnﬁ@≥Z‹<®ÄG◊%Ú+IíéD í$Ií$©˙âF‡_ÅÈwB—˙`Ø˛Ò–ˇNh~jeŸ¬E‹5~o-ﬂ@ÕåÆÓ”öÛOjJjr8ùKí§j¬ Dí$Ií$U/+^á…∑¡ÊèÇuncË3é˘ÑÉPcsQ	˜O^¬_Á}8O
sQ∑f\Ÿ≥π)ˇ„‚í$ÈHa "Ií$Ií™áÕ√î∞|j∞NÀÖC·§üAJ: ≈e<˘∆J~7s%˚ # |Á∏˙‹8†Mj}˘ÄsIít‰1 ë$Ií$IÒU¥^ÛüÉX¬…p‚epÍêYÄH4∆KÛ÷qˇ‰•lŸ8?°IMn˝N{NhrT<ªó$I’îà$Ií$Iäè“›0Î70˚(/ˆ⁄ˇ?Ë3jµ¨,{sŸVFè[ƒ‚M¡Ù&y‹<®Éé©ÁÄsIíÙ•@$Ií$I“°©Ä˛ØèÅΩ[ÇΩF]ÇÁMN™,[≤i7wç_ƒK∑êìûÃ/˚¥ÊÇÆMIKNäGÁí$È0b "Ií$IíçXñN
Ê|l[ÏÂµÄæøÇÇ”·ﬂOslŸ]¬ÉSñÚów◊çAJRàNn∆/˚¥¢fFj¸˙ó$IáIí$Iítm¯ &ﬂ´ﬂ÷5Ú‡¥õ†Û≈êÑ˚ "<ıÊJûxc{ÀÇÁÉé©«M€—¨vfº:ó$Iá)Ií$IítÏZ”ÓÄè^÷IipÚ–˝Z®QÄh4∆À¨ÁæIKÿTT¿ÒçkrÎêNlñß∆%I“·Œ Dí$Ií$x˚v¡õ˜√;OB§4ÿ;ÓË}+‘lRYˆˆÚm‹9n7–∞fn‘éÔWﬂÁí$È[1 ë$Ií$INEº˜x„◊∞og∞◊¨Ùøt¨,[æe7c∆/f⁄‚`zvz2øË’äOiFzäŒ%I“∑g "Ií$IíæΩXæ
SG¡ŒU¡^ùv–Ôvh›ør¿˘∂=•<4u)/Ã]G$#9‚¸ìöpuﬂ6‰e:‡\í$8 í$Ií$È€Y˚Læ>ô¨3Û°˜pË#H
>z()èá∑VÒ¯åÏ)≠ †_˚∫‹<®-Îd≈´sIíî¿@$Ií$I“7≥}L˝,z-Xßd¿)øÑSÆÇ¥ ‘àFc¸˝√ı‹;q	
ÉÁ«6Ãe¯êNnQ+NçKí§#Åà$Ií$I˙zˆnf|º˜àV@(=oÅú˙ïesVngÙ∏E|¥æÄπÈ‹0∞-ˇÔ¯ÜÑ√8ó$Ióà$Ií$I⁄?Â˚‡ù'‡Õ†¥(ÿk’/òÛQ∑}eŸ ≠{3a1Sn +-ô+z∂‰íÓÕp.IíIí$IíÙøE£—_a⁄ÌPÙI∞WÔXË'¥ËYY∂coO] sÔ¨•"#)‚‹.çπ¶ojg•≈ßwIítƒ2 ë$Ií$I_nÂ0Â6ÿ¯a∞ŒiΩoÉ„ŒÅpú?Ûˆjy}9ªKÇÁ}⁄Â3lp;ZÂg«´sIítÑ3 ë$Ií$Iü∑eLÀ&Î¥Ë~-ú|§‘  ãÒèm‰ûâã˘dÁ> ⁄◊œa¯ê∫µ™ØŒ%Ií Ií$IíÙYª7¡Îw¡ˇ±(Ñì°Û≈p⁄Mê˘üP„Ω’;∏c‹">\∑Äz9È\?†-gut¿π$I™@$Ií$IîÓÅŸè¿¨ﬂ@˘ﬁ`Ø›w†Ô(®›™≤lı∂Ω¸z‚b&,ÿ@FjWú÷íK{¥†F™Œ%IRıa "Ií$I“ë,RÛüû˙ÿ≥9ÿkÿ9pﬁ¥keŸÆ‚2~3m9ˇ7g5Âë·úsbcÆÌ◊Ü¸ÏÙ85/IíÙÂ@$Ií$I:≈b∞lJ0ÁcÎ¢`Ô®f–˜W–˛«XïVD¯øŸk¯Õ¥e˝{¿˘imÍpÀ‡⁄÷s¿π$I™æ@$Ií$I:“l¸&ﬂ´ﬁ÷È5É'^…i@0‡|¸Gõ¯ıƒ≈¨›Q@ªzŸ‹2∏ÄS€‘âS„í$I˚œ Dí$Ií§#≈Æu0˝N¯◊_Ä$•¬I?Ö◊Aç£*Àﬁ_ªì—„1oÕN Ídßq}ˇ6|ØScíp.Ií í$Ií$%∫íBxÎAò˝DJÉΩcøΩoÉ£öVñ≠€QÃ›3Ó_®ëíƒÂß∂‡ÚS[êôÊGí$È‚ü^$Ií$IJTërxÔè∆Ø°x{∞◊¥;ÙøûPYVX\Œ£3ñ3v÷j "QB!¯~ßFÌ◊ñzπ8ó$Iá'Ií$IíM,ã˛S;V{µ€@ﬂQ–vPÂÄÛ≤ä(œΩ≥Üáß-cWq9 ›[’Êñ¡¥oêßÊ%IíIí$Ií…∫waÚ≠∞nN∞Œ¨=á¡	BR1@,c“«õ˘ıƒ≈¨⁄∂Ä÷˘Y‹2§ÄûmÍ
9ÁCí$˛@$Ií$IJ;V¬‘Q∞’`ù\N˘tª“≤+À>\∑ã—„1wı jg•2¥_[~–π…I·84.IítpÄHí$Iít8+ﬁ3ÔÖπøáh9ÇéÁCØ·ê”†≤Ïìù≈‹;i	üøÄ¥‰0óıh¡œz∂$ÀÁí$)˘'Ií$IíGÂ%0˜Iòy?î{-˚@ø€°ﬁ1ïeE%Â<ˆ˙
˛8ke¡ÄÛ3;6‰Üm©ü[#NÕKí$| í$Ií$N¢QX7òv;ÆˆÍ≠˙TñïG¢º0w-M]∆éΩe tmQã·C
8¶an<:ó$I:§@$Ií$I:\¨z3pæq~∞Œn ΩoÖ„·$ p>u—∆LXƒ ≠¡ÄÛu2πeP}
Úp.Iíé í$Ií$Uw[ó¿îë∞tB∞NÕÇÓ◊¿…WBjFeŸÇıÖ‹9n!sVŒÛ2Sπ∂ok~ÿ•	)8ó$IGIí$Ií™´=[`∆ò˜ƒ"JÇŒ?Å”nÜ¨:ïevÌ„æIKx˘Éı §&áπ§{sÆËŸíúÙîxu/IíW í$Ií$U7e{aˆ£0Îa(€Ïµ}u⁄TñÌ)≠‡ÒÀyÍÕUîVD8£CÆ–ñFGe|¡Ö%Iíé í$Ií$U—Ã^ª7{NÄ˛wB≥nïeë(yoNY ∂=¡ÄÛ.ÕÚ>§Ä„◊åC„í$I’èà$Ií$I’¡Ú©0yl˘8X◊l}F¬—gA8òﬂã≈ò±d+wç_ƒ≤-¡ì!ÕkgrÛ†vÙo_◊Áí$Iüa "Ií$IR<m˙&ﬂ+_÷ÈπpÍ–ÂrHN´,[∏°àª∆/‚≠Â€ 8*#Ö´˚¥ÊºìöíöÏÄsIí§ˇf "Ií$IR<Æé∫öˇ<Ép
úÙSËqd‰Uñm.*·æIKxÈ˝Oà≈ 5)ÃE›öqeØV‰÷p¿π$I“ó1 ë$Ií$ÈP*)ÇY¡Ï«†b_∞wÙY–g‰5Ø,€[Z¡ì3WÚ˚ô+ŸW‡;«’Á¶ÅÌhúÁÄsIí§Øb "Ií$I“°)áyca∆›PcEìÆ¡ÄÛFùˇSçÒ◊˜÷qˇî•l›]
@ß¶G1|H'49*çKí$û@$Ií$I:òb1X<¶éÑÌÀÉΩZ≠†Ô(h7>3∏|Ê“`¿˘‚Mªhíó¡ÕÉ⁄1Ëòz8ó$I˙ö@$Ií$I:X>ôìoÖµoÎåZ–st∫í˛3øc…¶›åøàôK∑ê[#Ö´z∑‚ÇÆMIKNäC„í$Iá?Ií$Ií¥ù´a⁄Ì∞‡o¡:9∫^	›ÆÅÙú ≤-ªKxp R˛ÚÓ:¢1HI
Ò„ÆÕ∏™w+jf§∆•uIí§Da "Ií$I“ÅRºﬁºÊ˛"e@é?zá‹Fˇ)+´‡©7WÒƒ+(.ú:¶7lG≥⁄ôqj^í$)±ÄHí$IíÙmUî¬‹ﬂ√Ã{°dW∞◊¢'ÙªÍWYâ∆x˘˝O∏oÚ6Œ;4Æ…≠C
Ë‹,Ô–˜-Iíî¿@$Ií$I˙¶b1¯¯eò:
v≠	ˆÚ€¡G´>UúœZæç—„±pc çé™¡M€Òù„Í;‡\í$È 0 ë$Ií$ÈõXÛv0‡|˝º`ùU/8Í™√˘˛œ‡Úeõw3f¬b¶/ﬁ@vz2øË’äOiFzäŒ%IíñpºPbô9s&ﬂ˝Ówi–†°PàW_}µ Îõ7oÊ¢ã.¢AÉddd0p‡@ñ-[V•¶§§Ñ+ØºíZµjëïï≈ŸgüÕÊÕõ´‘¨]ªñ!CÜêëëA~~>7‹pUjfÃò¡	'ú@ZZ≠ZµbÏÿ±„-Kí$I:“l[/úO
¬èîLË5~˘>ú„ cÎÓRÜøÚ~ìÈã∑êq—)Õx„Ü^¸Ù¥ñÜí$IôOÄËÄ⁄ªw/«<_|1gùuVï◊b±gúq)))¸˝Ô'''áxÄæ}˚≤p·B23ÉA◊^{-„∆ç„Ø˝+πππ¸‚ø‡¨≥Œb÷¨Y D"ÜBΩzıx˚Ì∑Ÿ∏q#?˛ÒèIII·ÆªÓ`’™U2Ñü˝Ïg<˜‹sLõ6çK/Ωî˙ıÎ3`¿ÄC˚Eë$IíîˆlÖ7ÓÜ˜ûÜXBa8·BË9≤ÎVñïîG¯√[´x|∆
ˆîﬂ®’ø}]n‘éu≤‚’Ω$I“'ã≈bÒnBâ)
Ò +Øp∆g ∞tÈR⁄∂mÀÇ8˙Ë£àF£‘´WèªÓ∫ãK/Ωî¬¬BÍ‘©√Ûœ?œ˜æ˜= /^LAA≥gœÊ‰ìOf¬Ñ	|Á;ﬂa√Ü‘≠¸%„â'û‡¶õnbÎ÷≠§¶¶r”M71n‹8,XPŸœ¯CvÌ⁄≈ƒâ˜´ˇ¢¢"rss),,$''Á ~e$Ií$V äaŒc÷CP∂;ÿk3˙éÇ¸vïe—håWÁØÁæIKÿPX¿±s>§Äì[‘äC„í$≈óüØ)ﬁ<KáLii) ÈÈÈï{·pò¥¥4ﬁzÎ- ÊÕõGyy9}˚ˆ≠¨i◊ÆMö4aˆÏŸ Ãû=õcè=∂2¸ 0` EEE|¸Ò«ï5üΩ∆ß5ü^„À˙+**™ÚCí$I“,ÅûÉﬂvÇÈw·G˝p·?·ºøT	?Ê¨‹Œˇ{tC_¸êÖ%4»MÁ°s:˜+ª~Hí$≈âG`Èê˘4»6lO>˘$ôôô<¯‡É|Ú…'l‹∏ÄMõ6ëööJÕö5´¸‹∫uÎ≤i”¶ öœÜüæ˛Èkˇ´¶®®à}˚ˆQ£Fçœı7fÃFçu@ﬁ´$Ií§√‹äÈ0yl˛(XÁ6Ü>#·ò≥!¸üÔ%\±uc∆/fÍ¢`naVZ2?Ô’íãª5w∆á$IRúÄËêIII·Âó_ÊíK.!//è§§$˙ˆÌÀ†AÉ®'±6å°CáVÆãääh‹∏q;í$Iít»m˛¶åÄÂSÉuZ.úzt˘)§¸ÁiˆÌ{Jyx⁄2û{g-ëhå§pàÛ∫4·Íæ≠©ùïßÊ%IíÙY :§:uÍƒ¸˘Û),,§¨¨å:uÍp“I'—πsg Í’´GYYªvÌ™Ú»ÊÕõ©WØ^eÕ‹πs´\wÛÊÕïØ}˙œO˜>[ìììÛÖO §••ëñÊ_T$Ií§#R—x}4ÃbQß¿âó¬i7BF^eYIyÑ±oØÊ—ÈÀŸ˝ÔÁ}ÚπyP;ZÂg«´{Ií$}≈Enn. Àñ-„Ω˜ﬁ„é;Ó ÇÄ$%%Öi”¶qˆŸg∞d…÷Æ]K◊Æ]Ë⁄µ+£GèfÀñ-‰ÁÁ0e rrrhﬂæ}eÕ¯Ò„´‹s î)ï◊ê$Ií$ Jw√¨á·ÌG†b_∞◊˛Ë;ÚZTñ≈b1^˚p˜L\¬˙]A›—r>∏ÄSZ’éC„í$I˙* :†ˆÏŸ√ÚÂÀ+◊´V≠b˛¸˘‰ÂÂ—§I˛˙◊øRßNö4i¬G}ƒ’W_ÕgúAˇ˛˝Å π‰íK:t(yyy‰‰‰p’UW—µkWN>˘d ˙˜ÔO˚ˆÌπ‡Ç∏Áû{ÿ¥i∑ﬁz+W^yeÂ?˚Ÿœx‰ëG∏Ò∆π¯‚ãô>}:/æ¯"„∆ç;Ù_Ií$I’O§ﬁfåÅΩ[ÉΩ∆'Aˇ;°qó*•ÔÆﬁ¡ù„Ò·∫] ‘ÀIÁÜm9≥cC¬·–!n\í$I˚À D‘{ÔΩGØ^Ω*◊üŒ‘∏¬;v,7ndË–°lﬁºô˙ıÎÛ„ˇò€nª≠ 5|A¬·0gü}6•••0Ä«{¨Úı§§$˛˘œr≈W–µkW233π¬π˝ˆ€+kö7oŒ∏q„∏ˆ⁄ky¯·ái‘®O=ı8»_Ií$I’Z,K'¬îë∞mI∞ó◊˙˛

Ná–ç’€ˆr˜Ñ≈L¸x ©I\qZK.Ì—Ç©8ó$I™ÓB±Í0}Z™Üäää»ÕÕ•∞∞êúúúx∑#Ií$È€Zˇ>Læ÷º¨k‰Aœõ°”O 9µ≤lÁﬁ2~3}œŒYCy$F8ÁúÿÑk˚µ&?;˝K..Ií˛õüØ)ﬁ|Dí$IíîÿvÆÅÈw¿G÷IipÚ–c(§ÁVñïVD¯”€k¯ÌÙeïŒ{∂≠√-ÉhS◊Áí$IáIí$IRb⁄∑ﬁºﬁy"e¡ﬁq?Ñﬁ∑BÕ∆ïe±Xåqm‰◊≥nG0‡º]ΩlÜ)†GÎ:qh\í$IÇà$Ií$)±Tî¡ªO¡Ã{`ﬂŒ`Ø˘©–Ôh–°JÈº5;=n!ÔØ›@~v◊˜oÀŸùë‰ÄsIí§√öà$Ií$)1ƒb∞Uò˙+ÿπ:ÿ´”.>Z˜´2‡|Ìˆb~=q1„>⁄@çî$~zZ.Î—ÇÃ4ˇ™,Iíî¸Sù$Ií$È∑vLæ>y7Xg’Ö^∑@áA“˛Í[X\Œ#Ø/„ô∑◊Pâ
¡˜;5‚∫˛m©õ„ÄsIí§Db "Ií$I:|m_SG¬¢Îî8Âóp UêñUYVVÂŸ9k¯ÕÙeÏ*.†GÎ⁄‹2∏ÄÇ˙9ÒË\í$Iôà$Ií$È≥wºÒkxÔè≠ÄP:^<ıë]Ø≤,ã1È„M‹=a1´∑–¶n∑.‡¥6uÖúÛ!Iíî®@$Ií$IáèÚ}0ÁqxÎA(-
ˆZ˜á~∑C~Aï“˘Îv1z‹Bﬁ]BØùï∆–~m¯AÁF$'ÖuÁí$I:ƒ@$Ií$I’_4
Ω”ÓÄ¢OÇΩz«Bˇ;°Eœ*•ÎvsÔ§%ºˆ· “S¬\÷£?=≠%Y8ó$I:b¯'?Ií$IRı∂rLæ6˝+XÁ4Ç>∑¡±?Äû‰(*)Á—◊óÛÙ¨’îUŒœÍÿàÎ¥°~nç¯Ù.Ií§∏1 ë$Ií$UO[¡î∞lr∞NÀÅÓ◊¬…W@ çÚHîÁﬂYÀ√”ñ±co ][‘b¯êéiòèŒ%IíTÄHí$Ií™ó›õ‡ıª‡ÉˇÉX¬…–˘8ÌF»¨]Yã≈ò∫hc&,bÂ÷Ω ¥¨ì…-ÉË›.ﬂÁí$IG8ÒÃ3œPªvmÜ¿ç7ﬁ»Ô~˜;⁄∑oœ/º@”¶M„‹°$Ií§#BÈx˚∑¡èÚ –†‡ª–ÁWPªUï“è>)dÙ¯ÖÃYπÄZô©\”Ø?<±1)8ó$Iä≈b±x7°¯j€∂-è?˛8Ω{˜fˆÏŸÙÌ€ó|ê˛Ûü$''ÛÚÀ/«ª≈∏(**"77ó¬¬Brrr‚›é$Iíî∏"0ˇŸ‡©è=õÉΩF'Œõú\•t√Æ}‹;i	Ø|∞Ä‘‰0óvoŒœz∂$'=ÂPw.Ií˛?_Sº˘àX∑n≠ZﬂMıÍ´ØrˆŸgs˘Âó”≠[7zˆÏﬂÊ$Ií$%ÆX,òÔ1el]Ï’˙˛
⁄üü9¬jwI9Oº±Çßﬁ\EiEÄ3:4‡ÜÅÌhX”Áí$I˙<ëïï≈ˆÌ€i“§	ì'OfË–° §ßß≥oﬂæ8w'Ií$)!mòSnÉU3Éuç£‡¥õÇY…©ïeë(~wM] ∂=¡ÄÛ.ÕÛ∏uH«5™yË˚ñ$I“a√ DÙÎ◊èK/Ωîé;≤tÈR¿«L≥fÕ‚€ú$Ií§ƒ≤kLø˛ıó`ùî
'˝zBêã≈bºædwç_ÃÚ-{ h^;ìõµ£˚∫8ó$I“W2 è>˙(∑ﬁz+Î÷≠„o˚µj’`ﬁºyú{ÓπqÓNí$IRB()Ñ7Ä9èC§4ÿ;ˆ˚–˚68™iï“è7r◊¯EÃZæÄ£2R∏∫OkŒ?π©Œ%Ií¥ﬂÇÆ/µgœ6m⁄T9‰H„ê&Ií$È ®(ÉyO√åªaﬂé`ØiwË4<°JÈ¶¬ÓõºÑøΩˇ	±§&Ö˘I∑f¸ºW+rk8‡\í§√çüØ)ﬁ|DÃú9Û˜,X¿»ë#Ÿ∫uÎ!ÓHí$I“a/ÉEØ¡‘_¡éï¡^Ì6–Ôvh3∞ ÄÛΩ•<˘∆
~˜ÊJJ ÉÁﬂ=æ7hK„ºå84/Ií§D` "zˆÏ˘Ö˚°PàÔ~˜ªá∂Ií$IáøusaÚ≠∞Óù`ùYzÉ.Ñ§ˇ¸54çÒ‚{Î∏ÚR∂Ì	é≈Í‘Ù(nR@«&G}—ï%Ií§˝f "vÓ‹YeâDX±b◊_=›ªwèSWí$Ií;€W¿¥Q∞Ô¡:πúrt˚%§eW)}cÈVÓ∑à%õw–¥V7l«¿cÍ9‡\í$IÑ3@Ù•ÊœüOÔﬁΩŸ±cGº[âœ(î$IíˆSÒx„x˜)àñ!Ëx>Ù9™î.ﬁTƒËqãxsŸ6 rk§pUÔV¸∏k3Rìp.IR"ÒÛ5≈õOÄËKÖ√aRSS„›Ü$Ií§Í™ºÊ>	3Ôá“¬`Øeü`ŒGΩc™în)*·Å)KyÒΩuDcêí‚«]õqUÔV‘ÃÔí$I:@ƒø˛ıØœÌmﬁºô€oøùã/æ∏ Î«w‹°lMí$IRuç¬Çó`⁄P∏6ÿ´{,ÙøZˆÆRZ\V¡ÔgÆ‚…ô+(.ã 0¯ÿz‹4∞MkeÍŒ%IítÒ,á	ÖB|Ÿ/ÖO_ÖBD"ëC‹]¸¯àû$IíÙVÕÑ…∑¡∆˘¡:ªÙπé;¬IïeëhåøΩˇ	˜O^¬Ê¢`¿y«&5πuHùöÊ≈°qIít®˘˘ö‚Õ'@ƒ™U´‚›Ç$Ií§ÍnÎò2ñN÷©Ÿ–˝8˘ÁêöQ•Ù≠e€=~ã6–Ë®‹4∞ﬂ9ÆæŒ%Iít»Äà¶Mõ∆ªIí$I’’ÓÕ0cºˇ'àE îùß›Yu™î.›ºõ1„Ò˙í≠ dß'sUÔV\xJ3“íìæËÍí$I“Ac "Ií$I˙º≤Ωˆ#0Îa(ﬂÏµ˚Ù˝‘n]•tÎÓRú∫î?œ]K4…·?:π)øÏ”öºLúKí$)>@$Ií$Iˇç¿¸Á`˙hÿ≥)ÿkpMO©R∫Ø,¬ﬁZ…„3V∞˜ﬂŒ]óõ∂£Eù¨C›π$IíTÖà$Ií$	b1X>-òÛ±Â„`ØfË3é>¬· “h4∆´Û◊sÔ§%l,,‡∏Fπ\¿I-j≈£{Ií$Ès@$Ií$ÈH∑Ò_0Â6X9#Xß◊ÑSoÄ.óArZï“Ÿ+∂3z¸B¨ú7¨YÉ∂Âª«5 v¿π$Ií™çFYæ|9[∂l!çVyÌ‘SOçSWí$Ií™¬ı0˝N¯ I©–ÂrËqd‰U)]æewOXƒ‘E[ »NKÊÁΩZÒìnÕHOq¿π$Ií™1gŒŒ;Ô<÷¨YC,´ÚZ("âƒ©3Ií$IEIÃzf?
¡Vs6ÙG5´R∫}O)O[∆sÔ¨%çëq^ó&\”∑5µ≤“>wiIí$©∫0 ?˚ŸœË‹π3„∆ç£~˝˙ÑB>∂.Ií$%§H9Ã3ÓÜ‚m¡^ìS†ˇù–®Sï“íÚOœZÕcØ/gwi }ÚπyP≠Úp.Ií§Íœ D,[∂åó^zâV≠Z≈ªIí$IC,ã«¡‘ë∞}y∞W´Ùª⁄Üœ|T4„ˇ⁄¿=ó∞~◊> énê√!ú“≤v<∫ó$Iíæq“I'±|˘rIí$)}ÚLæ÷Œ÷µ°ÁÕ–È"HJ©R:w’Fè[»áüP/'ù¥ÂÃép.Ií§√éà∏Í™´∏Ó∫Îÿ¥i«{,))Uˇt‹q«≈©3Ií$IﬂÿéU0Ìv¯¯Â`ùú]ØÑn◊@zNï“U€ˆr˜ÑEL˙x3 ô©I\—≥%ótoAçTúKí$Èä˝˜‘kq¬·ÁˆB°±XÏàÇ^TTDnn.ÖÖÖ‰‰‰|ıOê$Ií™É‚0Û>ò˚;àñ!ËpÙπ´îÓ‹[∆√”ñÒÏú5TDcÑC√8œœNèOˇí$)a¯˘ö‚Õ'@ƒ™U´‚›Ç$Ií§o´¢4=fﬁ%¡V¥Ë˝ÔÄz«V)-≠àÃ€´˘ÌÙÂÏ.	ú˜l[á[–¶nˆ°Ó\í$I:(@D”¶M„›Ç$Ií§o*ÉÉi£`◊⁄`/ø}|¥Í˚_•1∆}¥ë_O\Ã∫¡ÄÛvı≤>§Ä≠ÎÍŒ%Ií§É  ‰ı⁄kØ1h– RRRxÌµ◊˛gÌÈßü~à∫í$IíÙµ¨û8ﬂ~∞ŒÆu’·<Wù›1oÕÓ∑à÷Ó ?;çÎ¥ÂÏë‰ÄsIí$% gÄ°¬·0õ6m"??ˇgÄ|  ûQ(Ií§jh€2ò2ñå÷©Y–ÌÍ`»yjfï“5€˜rœƒ%å˚h# 5Rí¯Èi-∏¸‘d§˙=qí$È‡ÒÛ5≈õ⁄=BE£—/¸wIí$I’ÿû≠∆›ﬁ”ã@(	:]=áAV~ï“¬‚r~;}œÃ^My$F(?Ë‘òÎ˙∑!?«Áí$IJ| í$IíT›ï√úG·≠á°lw∞◊fÙu⁄V-≠àÚs÷õiÀ(‹W@è÷µπepı˝ŒKIí$9@$Ií$©∫äF‡√?√Ù;a˜Ü`Ø~Ë'4ÔQ•4ã1q¡&Óû∏ò5€ãhS7ã[–≥m>í$I“ë∆ Dí$Ií™£Â”` ÿº XÁ6Å>#‡ò≥·øÊ¯}∞v'£«-‚Ω5;®ùï∆u˝€˝NçHN˙Úôí$IR"3 ë$Ií§Íd”Çˇœﬁ}«WUﬂ›L¬HòIÿ ¢Ï·`»PôÓ—j]≠∂˛¥ÿ
(‚∂∂*ä´u¢∂é÷Z+∂Ze£,E¶Ï° $ +ag‹Û˚„j4Ç
ö‰fºûè˝~œ˜ûÛ9<√}˚9ﬂH±Ê›»81zﬁùÆÜ¯¬{wlÿæóëWˆ¬HwH•¯ÆÓqWü‹å™â˛uOí$Iõ?Kí$IRiêΩ	¶‹˛	ù~=áAÂöÖñfÌÀÂ©©´y·˝O……
¡˘«5‡Ü>«P7%):ıKí$I•åHïùù}ÿkìì›(Qí$I*6v¡˚ÅYO@ﬁæ»\´s†˜]PÛ®BKsÛ√¸ÛÉœ¯Àª´ÿ±7≤¡˘IÕjqÎÄñ¥©üR¬ÖKí$I•õHUΩzuB°–a≠Õœœ/Êj$Ií§
(?>~	¶çÄ=_DÊvélpﬁ∞S°•A0yÈfÓøúµ[˜ ptjUn–Ç^«¶ˆœˆí$IREb RAMù:µ‡ﬂ?˝ÙSnæ˘f~˘À_“µkW fœûÕK/Ωƒà#¢U¢$IíT>¨Ô‹[WFÊjΩÔÜñg¬∑¬åEüÔ‰ﬁ±Àò≥n; µ™$0¯Ùc∏¯ƒÜnp.Ií$}èPA¥ãPtùv⁄i¸˙◊øÊ‚ã/.4ˇ +ØÏ≥œ2m⁄¥ËeŸŸŸ§§§êïïÂk¿$IíT46~ìÓÄœfF∆I5·îõ·¯_A\B·•;˜Ò‡ÑÂºπ ≤¡yb\Wuo µß4£Z•¯íÆ\í$Èà˘˝ö¢Õ DTÆ\ôÖ“ºyÛBÛ+WÆ§CáÏ›ª7JïEó@Kí$©»Ï¯ﬁ˝#,y=2é´]ÆÖÓC†R·Ω;vÌœÂÈik¯€Ãu»pn«˙‹ÿ˜XÍWwÉsIíTv¯˝ö¢ÕW`âÜÚ‹sœ1r‰»BÛ˝Î_iÿ∞aî™í$Ií Å};‡ΩáaŒ3êüôkwúz;T/¸≥v^~ò}∏Å?O^…∂=ëµùö÷‰ˆÅ-i◊†z	.Ií$ï} ‚—GÂ¸Ûœg¸¯ÒtÓ‹ÄπsÁ≤j’*˛ÛüˇDπ:Ií$© ÀÅˇ
3FFBÄ¶=·Ù?AΩÖñA¿îÂ[∏o‹2÷|Ÿ‡¸®⁄U∏πNoïÊÁí$I“è‰+∞¿Üx˙ÈßYæ|9 -[∂‰ökÆ©– ∂ËIí$Èà|Úº{7Ï¯42Wß%ú˛Gh~˙Aú/Ÿò≈}„ñ1kÕ6 jTégpÔc¯EÁFƒª¡π$I*„¸~M—f "}ˇÄñ$I“˘l6L∫6~WMÉ^∑AáK ∂pÛ}F÷>ö∏íˇŒˇú ÄÑÿ~’Ω	ø=ÂhRí‹‡\í$ï~ø¶hÛX‡Ω˜ﬁ„ôgûaÌ⁄µå=ö˙ıÎÛè¸É¶Mõ“Ω{˜hó'Ií$ï^[W√;w¡Ú1ëq|eËv=tΩ´Z∫˚@œL_√sÔ≠endÉÛ3€◊„¶æ«“∞fÂíÆ\í$I*◊@ƒ˛Û.ªÏ2.π‰>˛¯c8 @VV˜›w„∆çãrÖí$IR)¥g+L >z¬yäÅéóAØ[°Zz°•y˘aFœ˚úá'≠dÎÓ»œ€'4Æ¡m[“±QçhT/Ií$ï{ ‚û{Óa‘®Q\~˘Âº˙Í´Û›∫u„û{Óâbeí$IR)îª>x
f˛dGÊö˜Ö”ÔÜ‘ñ-ü∂"≤¡˘ Õªh\´2∑ÙoAﬂ÷Ènp.Ií$#±b≈
zˆÏy–|JJ
;wÓ,˘Ç$Ií§“(ÜEˇÜ)˜@ˆÁëπÙv–Á8Í‰Éñ/À»ÊæqÀxo’V Rí‚˘˝iÕπ¨Kc‚‹‡\í$I*n "==ù’´W”§IìBÛ3gŒ‰®£éäNQí$IRi≤vL∫2E∆…‡¥;†Ìœ ¶pò±9{?èLZ…kÛ6‚äÆM¯›©ÕI©ÏÁí$IRI1 ø˘Õo∏˛˙Îy˛˘Á	ÖBl⁄¥âŸ≥gs„ç7r«wDª<Ií$)z6/Ö…w¬Í…ëqb2Ù
ùØÅ¯§BK˜Ê‰ÒÏåµ<3}-˚rÛÿ∂.7ı;ñ∆µ™îtÂí$IRÖg "næ˘f¬·0ßùv{˜Ó•gœû$&&r„ç7Úªﬂ˝.⁄ÂIí$I%oW&LΩÊøAb‚‡Ñ´‡‰·P•V°•˘·ÄˇÃ˚úá&≠`ÀÆ»ÁUÁˆÅ-9æqÕhT/Ií$	ADªï999¨^Ωö›ªw”™U+™V≠Ìí¢*;;õîî≤≤≤HNNév9í$I*	v√¨«a÷cêª72◊Ú,Ë˝®’Ï†ÂÔ≠˙Ç{«.cyÊ. ÷Lbxøl[◊Œ%IRÖÁ˜kä6;@T !!ÅV≠ZEªIí$©‰ÂÁ¡¸¿¥∞{sdÆ¡âëŒu9h˘ Õª∏o‹2¶≠¯Äjï‚¯˝©Õπ¸§∆$∆≈ñdÂí$IíæÉàÿø?è?˛8SßNeÀñ-Ñ√·B«?˛¯„(U&Ií$≥ ÄUì"˚||±<2W£i§„£’Ÿ≠.é/v‡ë…+˘˜áÎ	‚≤Æç˘˝©Õ©Q%°‰Îó$IíÙù@ƒUW]≈§Iì∏‡ÇË‘©ì≠˙í$I™6-ÄI∑√ßÔE∆I5"{|úpƒ3ˆÂ‰Û◊˜÷2j˙ˆ‰D68Ô€:çõ˚∑§im78ó$IíJ#1fÃ∆çG∑n›¢]ä$IíT¸vnÄ)ÇEˇéåc°ÛˇAè ©z°•·p¿Áo‰°â+»Ãﬁ@˚)‹6∞ùö∫¡π$IíTöÄà˙ıÎS≠Zµhó!Ií$Ø};aÊ#¡(»?ôk˚38Ì®ﬁË†Â≥÷lÂﬁ±À¯dS6 ı´'qSøc9≥]=bbÏöñ$IíJ;Ò√3|¯pFçE„∆ç£]é$IíT¥Úr‡£Áa˙∞o{dÆI8˝èPˇ∏ÉñØﬁ≤õ„ñÒÓÚ- TKå„∑ΩéÊW›öP)ﬁŒ%Ií§≤¬ Dúp¬	Ïﬂøü£é:ä ï+_Ë¯ˆÌ€£Tô$IíÙ,{ﬁ˘l_ô´}ú˛'8¶ÔAúo›}Äøº≥äWÊÆ'?‚íŒç∏˛¥Ê‘™öXÚıKí$I˙I@ƒ≈_Ã∆çπÔæ˚HKKstIí$ï}ÊF68ﬂ0'2Æí
ΩnÅéóCl·øÌœÕÁ˘˜◊Ò‘‘5Ï>ê@Ôñi‹‹øGßV-È %Ií$1k÷,fœûM˚ˆÌ£]ä$IíÙ”l[ÔﬁKˇ«WÜÆ◊A∑ﬂCb·}Ô¬·Ä∑n‚¡â+ÿ∏s mÍ'sÎÄñú‘¨vIW.Ií$©àÄà-Z∞oﬂæhó!Ií$˝x{∑√Ùë·_!úÑ†„•–Î6HÆ{–Ú9k∑qÔ∏e,˙<Ä∫)ï÷˜XŒÈPﬂŒ%Ií§r¬ D‹ˇ˝‹p√‹{ÔΩ¥m€ˆ†=@íìì£Tô$IíÙr˜√úQﬁ#p fptÔ»Ái≠Zæˆã›‹?~9ìñn†JB,◊û“å´∫ERÇúKí$IÂI(Ç ⁄E(∫bbb ⁄˚#B°˘˘˘—(+Í≤≥≥III!++ÀHí$)Z¬˘Ÿ,ÿΩ™¶A„ì &¬aXÚ:º˚G»⁄Yõ÷˙¸öùz–i∂Ô…·±wWÒÚüëà	¡Eù1§˜1‘©ÊÁí$I≈¡Ô◊mvÄà©SßFªIí$È`KﬂÇ	√!{”◊s…ı‡∏+`≈8»X¯Â\}8ıvh˜ÛH8Ú˚sÛ˘˚ÏOy| jvÌèlpﬁÎÿ:‹:†%Õ”
Ô	"Ií$©|±D˙&‘í$IQ¥Ù-xÌr‡{˛∫íPzÅ.øÖ¯§BáÇ `Ã¢ò∞úœwDˆªkë^ç€∂¢{s78ó$I*	~ø¶h≥DÃò1„{è˜ÏŸ≥Ñ*ë$Iíàºˆj¬pæ?¸®◊}…È˙Ë”Ì‹3v6Ï µZ"7ˆ=ñÛèk@¨úKí$IÜà8ÂîSö˚Ê~ uIí$E…g≥
øˆÍPrˆ¿∂UÖêœ∂Ì·˛ÒÀø$Ä 	±¸_œf¸¶gS*'¯WIí$©¢Òob«éÖ∆πππÃü?ü;Ó∏É{ÔΩ7JUIí$©¬⁄Ω˘à÷Ì‹õ√„SVÛ˜ŸüíõŸ‡¸g'4dËÈ«êö\©ï$IíTöÄàîîîÉÊN?˝t:t(ÛÊÕãBUí$I™êÏÇ•o÷“ú§:¸˝Ωµ<>e5Y˚rË—º6∑lIãtﬂ1-Ií$Ut ˙Niii¨X±"⁄eHí$©"X>∆áÏçë)‡P;vÑÿüîFˇˇ‰ÚÈée õVç[∂‰‰cÍî\Õí$IíJ5±h—¢B„ »»»‡˛˚ÔßCá—)Jí$I«éœ`¸M∞rBd\Ω1´”˚s‘≤Q¿7˜- É≥.‚”ÍTK‰Ü”è·¬∫¡π$Ií§B@DáÖBAPhæKó.<ˇ¸ÛQ™Jí$IÂ^~.Ã~¶= y˚ &∫]O~˜∏ÏëŸ¥À≠ƒ]Òß€>íI-ÓŒΩåâ·N\wÍ—\{r3™$˙◊Ií$IÛo
b›∫uÖ∆111‘©SáJï‹0Rí$I≈‰≥Ÿ0f|yÖçª√è@ùcôªfY˚…†ìú@ßòÂ§≤ì-Tgn∏ab Ë÷¨∂·á$Ií§Ô‰ﬂD„∆çö€πsßà$IíäﬁﬁÌ0˘Nòˇè»∏r-Ës¥øBëWXmŸµø`yò>∑:‰©æπNí$Iíæ-&⁄(˙x‡˛˝Ôåˆ≥üQ≥fMÍ◊Øœ¬Ö£Xô$Ií ç ÄØ¿'|~w9\˜t¯EA¯P≥r¬aù2µöˇ√é$Ií§Ôf "FçE√Üò<y2ì'Of¬Ñ	ÙÔﬂüa√ÜEπ:Ií$ïy_¨ÄœÄ7ØÖΩ€ µ\9Œz*◊,¥t…∆,ÓªÙ{OÍ¶T¢S”öﬂªNí$IR≈Ê+∞DfffA 2fÃ~ˆ≥ü—ßOö4iBÁŒù£\ù$Ií ¨úΩﬁC˛cŒÖ∏$8ÂfË:b„/ÕÛ¯îU<5m˘·Ä™âqÏ>êGæ±Ó´>ëªŒlElLIí$I˙.vÄà5j∞a√ &Lò@ÔﬁΩÇÄ¸¸¸hñ&Ií§≤j’;TxÔ·H¯qL?4∫>(¸X≤1ã≥ûò…„SVì–6ùi√Na‘•«ëûR¯5WÈ)ïx˙“„Ë◊¶n	ﬁå$Ií§≤»qﬁyÁÒã_¸ÇÊÕõ≥m€6˙˜Ô¿¸˘Û9˙Ë££\ù$Ií îÏòp3,}32NÆ˝Äg⁄Á"]OLY≈ì_v}‘¨í¿üŒn√¿vëp£_õ∫úﬁ*ùπÎ∂≥e◊~R´E^{eÁá$Ií§√a "}ÙQö4i¬Ü9r$U´V ##Éﬂ˛ˆ∑QÆNí$IeB8Ê>SÓÅú]äÖ.◊F^yïXÌ†ÂK6fq„ËÖ,œ‹¿Ä∂È¸ÒÏ6‘ÆöXh]lLàÆÕjï»-Hí$I*_BA?ºL™x≤≥≥III!++ã‰‰‰hó#IíTzm¸∆ÜåÖëq˝‡åG°nªÉñ™Î„èg∑ÊåvıJ∂fIí$;ø_S¥Ÿ" V≠Z≈‘©SŸ≤e·p∏–±;Ôº3JUIí$©T€üÈ¯ò˚@b
Ùæéˇƒº›‡∑ª>˙∑IÁOÁ‹ı!Ií$IE¡ D<˜‹s\{Ìµ‘Æ]õÙÙtBﬂx7s(2 ë$IRaA ü¸&‹ª7GÊ⁄˛˙ﬁUSZûìÊâ©´yjÍjÚ¬5*«Ûßs⁄ÿı!Ií$©XÄà{Óπá{ÔΩó·√áGªIí$ïv€◊¬ÿaÕªëqÕfp∆#p‘)á\n◊á$Ií§h1 ;vÏ‡¬/åví$I*ÕÚ¿˚è¡{Aﬁ~àMÑ7@∑Î!æ“AÀ’ıÒ«≥€pFª∫Ö:é%Ií$©∏Äà/ºêIì&qÕ5◊DªIí$ïFÎf¿ò°∞mUd|‘)0®’ÏêÀ?Ÿî≈ç£±,#∞ÎCí$IRtÄà£è>ö;Ó∏É>¯Ä∂m€_Ë¯Ôˇ˚(U&Ií§®⁄˝Læ˛+2Æí
˝F@õÛ·]v}Hí$I*MBA—.B—’¥i”Ô<
ÖXªvm	VSzdggìííBVV………—.Gí$©‰Ñ√0ˇÔ0˘.ÿø¡	W¬iwBRıC~‰€]˝ZG∫>ÍT≥ÎCí$©¢Ú˚5Eõ b›∫u—.Aí$I•EÊ3>üß∑Ö3˛N8‰Úúº0ON]Õìv}Hí$I*e@T»WA˛eUí$©Ç…Ÿ”F¿Ïß »áÑ™–Î6Ët5ƒ˙Øv}Hí$I*Õb¢]ÄJáøˇ˝Ô¥m€ñ§§$íííh◊Æˇ¯«?¢]ñ$IíJ¬Úqdgòıx$¸hy&ö]{»#'/Ã£ìWrˆÔ≥,#õï„yÏ‚é<}ÈqÜí$IíJ;@ƒ#è<¬w‹¡u◊]G∑n› ò9s&◊\s[∑ne»ê!QÆPí$I≈bÁ?VåçåS¡Ä·ÿ~ﬂ˘ëow}Ùmù∆=Á¥5¯ê$IíTÍ∏	∫h⁄¥)wﬂ}7ó_~y°˘ó^zâ?¸·vè7ií$IÂV~.ÃSG@ÓàâÉì~=áABïC~$'/ÃS”VÛƒîØ˜˙∏˚Ï6úÈ^í$I˙~ø¶h≥Ddddp“I'4“I'ëëëÖä$IíTl6ÃçlræyId‹®+úÒ(§∂¸Œèÿı!Ií$©,2 G}4ØΩˆ∑ﬁzk°˘ˇ˚ﬂ4oﬁ<JUIí$©HÌ€Ô¸ÊΩ'’Ä”ˇ.ÅòCoòõÊ…©_w}TØœ›gµÊ¨ˆıÏ˙ê$IíTÍÄàªÔæõüˇ¸ÁÃò1£`ê˜ﬂüwﬂ}ó◊^{- ’Ií$È'	XÙLºˆnçÃu∏$~T©ıù[∫)õG/d©]í$Ií (q˛˘Á3gŒ}ÙQﬁ|ÛM Z∂l…‹πsÈÿ±ctãì$I“è∑uU‰uWüæ◊>ŒxötˇŒèÿı!Ií$©ºptÈ;∏Iì$I*≥r˜√ÃG`Ê£êüqï‡‰õ†ÎÔ .·;?f◊á$IíäíﬂØ)⁄Ï „∆ç#66ñæ}˚öü8q"·pò˛˝˚G©2Ií$±’Ô¬ÿ`«∫»¯Ë”a¿ÉP≥Èw~$7?ÃSS◊¯îUv}Hí$I*7Ω€°*îõoæô¸¸¸ÉÊÉ ‡ÊõoéBEí$I:bª2·ı+·ÂÛ"·Gµ∫p·Kp…ËÔ?ñn ÊÏ'ﬁÁ—wVíË”*çICzrvá˙Üí$Ií 4;@ƒ™U´h’™’AÛ-Z¥`ıÍ’Q®Hí$Iá-ú=Ô˛dC(:˝Ù∫*}˜kÏ˙ê$IíTﬁÄàîî÷Æ]Kì&M
ÕØ^Ωö*U™Dß(Ií$˝∞M"õúo˙82Æ◊Œ¯3‘ÎΩ[ñŸÎ„ìMëΩ>Noï∆ΩÁ∂!µZ•b-Wí$IíJíà8˚Ï≥<x0oºÒÕö5"·«7‹¿YgùÂÍ$Iítê˝Ÿ0ı>ò˚aHLÜ”ÓÑÆÑòÿÔ¸Xn~òßßE∫>rÛÌ˙ê$IíTæÄàë#G“Ø_?Z¥hAÉ ¯¸ÛœÈ—£=ÙPî´ì$IRÅ Ä•ˇÉ	7√Æå»\õÛ°Ô}P-˝{?j◊á$Ií§ä∆ D§§§0k÷,&OûÃ¬ÖIJJ¢]ªvÙÏŸ3⁄•Ií$È+;>Öq√`’§»∏FS¯›˚{?ˆÌÆèî§x˛x∂]í$Ií øPA¥ãêJ£ÏÏlRRR»  "9˘ª7ï$I*Vy90˚qò˛ ‰ÌÉòxË>zÖ¯§Ô˝Ë≤ålÜΩæê%Ì˙ê$IR…Û˚5Eõ í$IRiıÈ˚0v(|±<2n“>ué˘ﬁè™Î„Ó≥Zsvª>$Ií$U í$IRi≥gLæºWÆŸÁ£›œ‡ª>$Ií$)¬ Dí$I*-¬aXOò|Ï€ô;˛óp⁄]PπÊ˜~‘ÆIí$I*Ã Dí$I*∂,É1Ca˝¨»8µ5úÒ(4Í¸É]ûôÕç£øÓ˙Ë›2ç˚ŒmCj≤]í$Ií*.∞fÕ^x·÷¨Y√_˛ÚRSS?~<ç5¢uÎ÷—.Oí$©¸ Ÿ3F¬¨«!úÒï·î[†ÀµˇΩÕÕ3j⁄≥ÎCí$IíÌ}”ßOßm€∂Ãô3áˇ˛˜øÏﬁΩÄÖr◊]wEπ:Ií§rlÂDx™3Ã|4~;ÕÖnøˇ¡cyf6Á>ı>O^In~@ÔñiL“ìs:÷7¸ê$Ií$@‹|ÛÕ‹sœ=Lû<ôÑÑÑÇ˘SO=ï>¯‡àŒ5c∆Œ<ÛLÍ’ã¸_áoæ˘f°„ªwÔÊ∫ÎÆ£AÉ$%%—™U+FçUhÕ˛˝˚4hµj’¢j’™ú˛˘lﬁºπ–öıÎ◊3p‡@*WÆLjj*√Ü#//Ø–öi”¶q‹q«ëòò»—GÕã/æxD˜"IíTl≤6¬ø/ÖW~;◊Cr∏Ë∏¯®ﬁ{?öõÊâ)´8ÛÒô,ŸòMJR<è˛º=œ]~ºØºí$Ií§o0 ã/Ê‹sœ=h>55ï≠[∑—πˆÏŸC˚ˆÌyÚ…'y|Ë–°Lò0Åó_~ôeÀñ1x`ÆªÓ:ﬁzÎ≠Ç5CÜ·Ì∑ﬂfÙË—Lü>ùMõ6qﬁyÁœœœg‡¿Å‰‰‰0k÷,^zÈ%^|ÒEÓºÛŒÇ5Î÷≠c‡¿ÅÙÍ’ã0x`~˝Î_3q‚ƒ#∫Ií§"ïü≥üÇ';¡≤∑!'˝ÕÅ„_u}<4È´ÆèT&È…πÿı!Ií$Iﬂ‚ ¢zıÍddd–¥i”BÛÛÁœß~˝˙GtÆ˛˝˚”øˇÔ<>k÷,Æ∏‚
N9Â Ææ˙jûyÊÊŒùÀYgùEVV˚€ﬂxÂïW8ı‘Sx·ÖhŸ≤%|]∫ta“§I,]∫îwﬁyá¥¥4:tË¿ü˛Ù'ÜŒ˛5jMõ6Â·á†eÀñÃú9ìG}îæ}˚—=Ií$âœÁ¡ò¡êπ(2n–)≤…yzõ¸hn~òg¶Ø·/Ô~Ω◊«Œj≈9|›ï$Ií$};@ƒE]ƒ·√…ÃÃ$
áyˇ˝˜πÒ∆π¸ÚÀãÙZ'ùtoΩı7n$¶Nù  ï+È”ß ÛÊÕ#77óﬁΩ{|¶Eã4j‘àŸ≥g0{ˆl⁄∂mKZZZ¡öæ}˚íùùÕ'ü|R∞ÊõÁ¯jÕWÁ8îêùù]Ëó$I“O∂o'åΩ˛zZ$¸®TŒ¸\9Ò∞¬èôªÏ˙ê$Ií§¡qﬂ}˜1h– 6lH~~>≠Zµ"??ü_¸‚‹~˚ÌEz≠«ú´ØæöGLLœ=˜={ˆ 33ìÑÑ™WØ^Ësiiidff¨˘f¯Ò’ÒØé}ﬂöÏÏlˆÌ€GRR“Aµç1ÇªÔæªHÓSí$â Ä%ˇÅ	∑¿û-ëπvAü{†jù¸x^~òQﬂË˙HÆ«ŒjÕπnr.Ií$Iá≈ D$$$‹sœq«w∞d…vÔﬁM«éiﬁºyë_ÎÒ«ÁÉ>‡≠∑ﬁ¢q„∆Ãò1ÉAÉQØ^ΩÉ:6J⁄-∑‹¬–°C∆ŸŸŸ4l¯˝õêJí$“∂5ëÆèµS#„ZÕ·åG†iœ√˙¯äÃ]‹8z!ã7f–ªe*˜ù€÷MŒ%Ií$ÈÄ®@£Fçh‘®Q±ùﬂæ}‹zÎ≠ºÒ∆Ÿ‰≥]ªv,X∞ÄázàﬁΩ{ìûûNNN;wÓ,‘≤yÛf“””HOOgÓ‹πÖŒΩyÛÊÇc_˝Û´πoÆINN>d˜@bb"âââErØí$©Ç ; 3ˇÔ=˘ 6zﬁ›Æá∏˛9√ÆIí$I*: "^˝u¶Nù ñ-[á√Öéˇ˜øˇ-íÎ‰ÊÊíõõKLL·≠gbccÆy¸Ò«œªÔæÀ˘Áü¿ä+Xø~=]ªv†k◊Æ‹{ÔΩlŸ≤Ö‘‘T &OûLrr2≠Zµ*X3n‹∏B◊ô<yr¡9$Iíä‹⁄iëÆèm´#„fß¬Äá†V≥√˙¯∑ª>Nkë }Áµ%ÕÆIí$I˙Q@ƒ‡¡ÉyÊôgË’´iii?Èˇ.‹Ω{7´WØ.Ø[∑éP≥fM5jƒ…'üÃ∞a√HJJ¢q„∆Lü>ùøˇ˝Ô<Ú»# §§§p’UW1tËPj÷¨Irr2ø˚›ÔË⁄µ+]∫t†Oü>¥j’äÀ.ªåë#Gíôô…Ì∑ﬂŒ†AÉ
:8ÆπÊûx‚	n∫È&ÆºÚJ¶Lô¬kØΩ∆ÿ±c¬Ôî$I“!ÏﬁoÉ≈ØE∆U”†ﬂh}∆œUy˘aûô±ñøº≥äú¸∞]í$IíTDBA—.B—U≥fM^~˘eìœ5m⁄4zıÍu–¸W\¡ã/æHff&∑‹rì&Mb˚ˆÌ4n‹ò´Øæö!CÜ¸ˇ˛˝‹p√¸Î_ˇ‚¿ÅÙÌ€óßûz™‡ıV ü}ˆ◊^{-”¶M£Jï*\q≈‹ˇ˝ƒ≈≈™e»ê!,]∫îp«wÀ_˛Ú∞Ô%;;õîî≤≤≤HNN˛Òø)í$©|
á·„·ù?¿˛, ù~ßﬁïRÎ+7G∫>}n◊á$Ií ø_S¥Äà¶Mõ2~¸xZ¥hÌRJˇÄñ$Iﬂ)s1åüß∑É3ˇıè?¨è™Î„Æ3[sﬁqv}Hí$©¸˚5EõØ¿¯√∏˚Óªy˛˘ÁøsÉpIí$v√¥¡”‰CBµH««âøÜÿ√˚—˙€]ß∂HeÑ]í$IíT‰@ƒœ~ˆ3˛ıØëööJì&Màèè/t¸„è?éReí$I•D¿Ú±0˛&»ﬁôkuNdØè‰záu
ª>$Ií$©dÄà+Æ∏ÇyÛÊqÈ•ó˛‰M–%Ií ùùÎa‹M∞r|d\Ω1xéÈsÿß∞ÎCí$IíJûà;v,'N§{˜Ó—.Eí$©Ù»œÖŸO¬Ù w/ƒƒC∑ﬂCè!°Úaù‚€]’æÏ˙8ﬂÆIí$I*v ¢a√ÜnB$IíÙMÎ?àlræeid‹Ë$8„QHmqÿßXπy√F/d·7∫>Ó;∑-È)v}Hí$IRI0 ?¸07›t£Fç¢Iì&—.Gí$)zˆnáwÓÇèˇ'’Ñ>˜@á_¿avlÿı!Ií$I•Éà∏Ù“KŸªw/Õö5£rÂ mÇæ}˚ˆ(U&IíTBÇ ˛&›{∑EÊ:^ßˇ*◊<Ï”¨˙rØª>$Ií$)˙@ƒüˇ¸Áhó Ií=_¨Ä1C·≥ôëqùñë◊]5Ózÿß»ÀÛÏ{k˘Ûdª>$Ií$©¥0 W\qE¥Kê$I*yπ˚`∆C˛_ úqIp pË2‚˚4ﬂÓ˙ËulFú◊ŒÆIí$Iä2ê
*;;ª`„ÛÏÏÏÔ]ÎÈí$©‹Y˝åΩv|7ÔÑç˚áÍ˙∏ÛåV\p|ª>$Ií$©0 ©†j‘®AFF©©©TØ^˝êIÇÄP(D~~~*î$I*Ÿ0Ò¯‰ç»∏Z=0Zúqÿõú√ó]Ø/b·ÜùÄ]í$IíTÄTPS¶L°fÕ»ÜûSßNçr5í$I≈,ú˛ﬁ˝‰ÏÇPtæz›â’˚4y˘aû{oèN^i◊á$Ií$ïr ‘…'ü\ÔMõ6•a√Ü˝•=6lÿP“•Ií$≠MÛ·Ì¡ê± 2Æ|dìÛ∫ÌèË4v}Hí$IRŸb "ö6mZ:¨o⁄æ};Mõ6ıXí$©l⁄üSÓÖüÉ â)–˚N8˛W{ÿß)Ë˙xg%9yv}Hí$IRYa ¢ÇΩ>æm˜Ó›T™‰ˇ—(Ií ò àÏÒ1·ÿùôk{!Ùπ™•—©VoŸ≈£øÓ˙8Âÿ:å8Ø-uSíä∏hIí$IRQ3 ©¿Ü
@(‚é;Ó†rÂ «ÚÛÛô3g:tàRuí$I?¬ˆµ0n¨~'2ÆŸ>Õz—i’ıq«≠∏–ÆIí$I*3@*∞˘ÛÁëê≈ãìêêPp,!!ÅˆÌ€s„ç7F´<Ií§√ów f=3Çº˝õ ›áB˜!d≠v}Hí$IR˘` RÅMù:Ä_˝ÍW¸Â/!999 Ií$˝üŒÑ1C`Î »∏È…0®}Ùù&?‹{kydÚó]âq‹q¶]í$IíTVÄà^x!⁄%Hí$π=[a“∞ï»∏JË;⁄^ GX¨ﬁ≤ãG/b¡ó]'Sá˚œ∑ÎCí$Ií 2Ií$ï-·0ÃˇLæˆÔBp¬Ø‡¥;!©∆ù ÆIí$I*ø@$IíTvl˛$Ú∫´s"„¥∂p∆£–ƒ#>’Í-ªπqÙBª>$Ií$©ú2 ë$IRÈó≥¶? ≥üÑpƒWÅSoÉNˇ±Gˆ#m~8‡ØÔ≠Â·ov}ú—äO∞ÎCí$Ií Ií$ïn+∆√∏aêµ!2nqÙ RÒ©’ı1‚º∂‘´n◊á$Ií$ï7 í$I*ù≤>áÒ√a˘ò»8•	«ˆ?‚SŸı!Ií$Ièà$IíJó¸<ò3
¶ﬁπ{ &∫^'ﬂ	Ué¯t´∑ÏfÿÎôø~' =è©√˝v}Hí$IRπg "Ií§“c√áëMŒ7/éåvÅ3Å¥÷G|™Cu}‹~FK~vBCª>$Ií$©0 ë$IRÙÌ€Ô‹Û^H™ßˇ:\
11G|:ª>$Ií$I í$Iäû Ä≈£a‚≠∞Áã»\áK"·Gï⁄G|∫¸p¿ﬂfÆÂ°Iv}Hí$IREg "Ií§Ëÿ∫
∆Öu3"„⁄«F^w’§˚è:ù]í$Ií§o2 ë$IR… ›3ÅôèB~ƒUÇû√‡§ﬂC\¬üŒÆIí$I“°ÄHí$©‰¨ôcoÄÌk#„£{√Äá†f”w∫/v3lÙB>˛≤Î£GÛ⁄<p~;ª>$Ií$I í$I*ª6Gˆ˘XÚzd\5˙ﬂ≠ŒÅ—•ëx~Ê:ö¥Çya™&∆q˚¿ñ¸¸Dª>$Ií$I í$I*>·|ò˜ºÛG8ê°Ët5Ù∫*%ˇ®S™Î„˛Û€QﬂÆIí$I“7ÄHí$©xd,Ñ1C`„º»∏^G8„—»?ª>$Ií$IG¬ Dí$IEÎ¿.òzÃA™¡iw¬âWALÏè:Âö/vs”Îãò˜Ÿ¿ÆIí$I“3 ë$IR—Xˆ6åª6EÊZü}ÔÉ‰∫?ÍîáÍ˙∏m`K.≤ÎCí$IíÙ@$IíÙ”Ì¯∆›´&F∆5ö¿¿á·Ëﬁ?˙îkøÿÕ0ª>$Ií$I?íà$Ií~ººò˝L	y˚ &∫Ü7@¸è*Ú√/ºøé'⁄ı!Ií$I˙Ò@$IíÙ„|6∆Ö/ñE∆Mz¿¿G†Œ1?˙îv}Hí$Iíääà$IíéÃûmŒù0ˇÂ»∏r-Ës/¥ø~dáÜ]í$Ií§¢f "Ií§√∞‡òt;Ï€ô;Ó
Ë˝®\ÛGüvÌªπÈıE|d◊á$Ií$©ÄHí$ÈámYcá¬gÔG∆©≠·åG°QÁ} ow}TIàÂ∂Å≠∏∏ì]í$Ií§üŒ Dí$Iﬂ-g/Ãxf=·<àØß‹]~±Ò?˙¥ﬂÓ˙Ë~tmÓ?ø-jT.™ %Ií$Iúà$IímÂ$wÏ\”åÑÍç~Ù)Ì˙ê$Ií$ïIí$ñΩ	&‹Kˇ'7à-˛§”Æ€∫áa£⁄ı!Ií$I* í$Iä»œÉüÉ)˜@Œn≈Bók·î[ ±Íè?≠]í$Ií§(0 ë$I|>∆ÜÃEëqÉ#õúß∑˝IßµÎCí$Ií- í$IŸ˛,x˜O·_Å *•@Ôª·∏+ &ÊGü6xa÷ß<8q9˚s#]∑l…/:5≤ÎCí$IíT"@$Ií*¢ Ä%ˇÅâ∑¬ÓÕëπv?á>˜@’‘ütÍu[˜p”Î˘”H◊G∑£kÒ¿˘ÌÏ˙ê$Ií$ï(Ií§äf€w#¨ô◊:>Gù¸ìNk◊á$Ií$©41 ë$I™(Ú¿˚ÅA˛àMÑû7B∑Î!.Ò'ù˙”≠{ˆ≠Æè˚œkG√öv}Hí$Ií¢√ Dí$©"X;∆Öm´#„£z¡¿á°V≥üt⁄p8‡≈Yü2“ÆIí$IR)c "IíTûÌ˛&›ã˛WIÖ~#†Õ˘
ª>$Ií$I•ôà$IRy√«/¡;w¡˛, '^ßﬁI’‚©Ó˙∏e@K.Èl◊á$Ií$©Ù0 ë$I*o2√ò°˘‹»8ΩúÒghp¸O>ıß[˜p”Îãò˚Èv NjVãŒ∑ÎCí$IíT˙ÄHí$ïv√¥¡”‰CBU8ıv8Ò7˚”~Ï˚v◊GÂÑXnµÎCí$IíTäÄHí$ïÀ«¬∏õ ˚Û»∏ÂY–ˇHÆ˜ìOm◊á$Ií$©,2 ë$I*ÀvÆáÒ√a≈∏»∏z#”˜'ü˙P]∑h…%ùc◊á$Ií$©t3 ë$I*ãÚs·Éß`⁄˝êªb‚‡§ﬂCœaê”;3Ï˙ê$Ií$ïu í$IeÕ˙90fl˘$2ntúÒ§∂¸…ßá^ö˝)L∞ÎCí$IíT∂ÄHí$ï{∑√;Äè_äåìjBü?AáK†6"ˇl€ÜΩæàπÎ"]]è™≈»Ï˙ê$Ií$ïM í$I•]¿¢√ƒ€`Ô÷»\«K°˜°J≠ü|˙p8‡Ô≥?ÂÅ	+ÿóõo◊á$Ií$©\0 ë$I*ÕæX	cá¬ßÔE∆uZ¿¿G†I∑"9Ω]í$Ií§Ú  Dí$©4 ›Ô=3ˇ·\àKÇìoÇÆ◊A\¬O>˝!ª>˙∑‡íŒçÌ˙ê$Ií$ï í$I•ÕÍw`Ï∞„”»∏y ‘hR$ßˇl€nz}sæÏ˙ËrTMº†Ω]í$Ií§r≈ Dí$©¥ÿï	nÅO˛W´˝Äñg…&Áv}Hí$Ií*Ií§hÁ√áÉ)ÇŸäÅŒ◊@Ø[!±Zë\¬ÆIí$IREc "IíMõÊ√ò!ë‘;Œ¸3‘m_$ß?T◊«Õ˝[p©]í$Ií§rŒ Dí$)ˆg√‘{aÓ≥Ñ!1zﬂ	«ˇ
bbã‰Î∑ÌeÿÎu}å<ø=çjŸı!Ií$I*ˇ@$IíJR¿“7a¸Õ∞;32◊ÊË{TK+íKÑ√ˇ¯‡3Óø‹ÆIí$IRÖe "IíTR∂ØÉq√`ı‰»∏ÊQ0ahvjë]¬ÆIí$Ií"@$Iíä[^Ãzf<y˚!6∫ÅÓC!æRë\"xyN§ÎcoN>IÒ±‹2¿ÆIí$IR≈e "IíTú>ù	cÜ¬÷ëq”û0®›º».±~€^n˙œB>XÈ˙Ë‹¥&^`◊á$Ií$©b3 ë$I*{∂¬§;`·+ëqï:ë}>⁄^°¢È»8T◊«Õ˝[pYª>$Ií$I2 ë$I*J·0,x&ﬂ	˚vDÊéˇÙæíjŸe’ı1ÚÇv4ÆU•»Æ!Ií$IRYf "IíTT6/Ö±Ca˝Ï»8≠úÒ(4ÏTdó∞ÎCí$Ií§√c "IíÙSÂÏÅÈ#aˆŒÉ¯*–ÎVË|ƒ›è[∂ÔeÿÎv}Hí$Iít8@$Ií~ä`‹0»Z∑8˙? )äÏv}Hí$Iít‰@$Ií~å¨ç0˛&X>&2Ni˝GBãEzô€˜r”ÎãòΩv ùö÷‰Aª>$Ií$I˙A í$IG"?Ê>SÔÉú›äÖÆÉ‡îõ!°ËBâp8‡üs>cƒ7∫>Ü˜;ñÀª6±ÎCí$Ií§√` "Iít∏>ˇﬁõG∆;G69Ok]§ó±ÎCí$Ií§üŒ Dí$ÈáÏ€	Ô˛>z†Ru8˝è–Ò2àâ)≤Àÿı!Ií$IR—1 ë$I˙.A ã_áâ∑¿û/"sÌ}˛UjÈ•Ï˙ê$Ií$©hÄHí$ ÷’0v(¨õ◊jy›U”Ezôp8‡üs◊3b‹2ª>$Ií$I*B í$Iﬂîªﬁˇ3º˜0‰Á@\%Ëy#úÙ{àK,“K‘ı—§&^h◊á$Ií$IE¡ Dí$È+k¶¬ÿ`˚ö»∏Ÿi0!®yTë^Ê€]ï‚cﬁØWÿı!Ií$IRë1 ë$I⁄µ&›ãGG∆U”°ﬂh}.Ñä6êÿ∞}/√ˇ≥àYkæÓ˙yA;ö‘∂ÎCí$Ií§¢d "Ií*ÆpÊ=Ô¸d!Ët5úzTJ)‚KŸı!Ií$IRI2 ë$IS∆"36~◊mg¸ÍW‰ó≤ÎCí$Ií§íg "Ií*ñª`ÍòÛ4aH®ß›'˛bbãÙRAœ9ëÆè=_v}‹‘∑ø<…ÆIí$Iíäõà$I™Ç ñèÅÒ√!{cdÆıπ–w$◊-ÚÀŸı!Ií$IRtÄHí§Úo«g0˛&X9!2Æ—<Õ{˘•Ï˙ê$Ií$©t0 ë$IÂW~.Ã~¶= y˚ &∫]=oÑ¯§"ø‹Á;"]ÔØét}úÿ§#/hOSª>$Ií$I*q í$©|˙lvdìÛ/ñE∆çª√è@ùcã¸RA ‹ı‹7÷ÆIí$IíJIíTæÏ›ìÔÑ˘ˇàå+◊Ç>˜@˚ã!TÙaÑ]í$Ií$ïN í$©|X
L∫ˆmèÃw9Ùæ*◊,ÜÀ‹ı1ÏÀÆèXª>$Ií$Iä:IíTˆ}±"Ú∫´œﬁèåS[¡èB£.≈rπœwÏÂÊˇ,fÊÍ≠ ú–∏^h◊á$Ií$I•âà$I*ªrˆ¬{¡˚èA8‚í‡îõ°Î àç/ÚÀŸı!Ií$IRŸa "Ií ¶UìaÏ∞Û≥»¯ò~–$‘h\,ó≥ÎCí$Ií§≤≈ Dí$ï-Ÿõ`¬Õ∞Ùëqr˝H—b`±lrˇöªÅ˚∆-c˜Å<„b÷˜X~’≠©]í$Ií$ïb í$©lÁ√‹Á` =ê≥B±–ÂZ8ÂH¨Z,ó¥ÎCí$Ií§≤À Dí$ï~?Ü1É!cad\ˇÑ»&Áu€ÀÂÏ˙ê$Ií$©Ï3 ë$I•◊˛¨H««‹ÁÄ S†˜]p¸Ø &¶X.πqÁ>n˛œ"ﬁ[È˙8æqº†G’)û.Ií$IíT<@$IRÈ…a¬-∞{sdÆÌœ†ÔΩP5µò.Íá∏w¨]í$Ií$ï í$©tŸ∂∆›k¶D∆5õ¡è¿Qß€%Ì˙ê$Ií$©¸1 ë$I•Cﬁxˇ1òÒ ‰ÄÿDËqtª‚+À%Ì˙ê$Ií$©¸2 ë$I—∑nå
€VE∆GùÅZÕäÌíáÍ˙yA;öŸı!Ií$IRπ` "Ií¢g˜0ÈvXÙjd\%˙çÄ6ÁC®x:0Ï˙ê$Ií$©b0 ë$I%/Ü˘á…w¡˛ù@Nº
NΩí™€eÌ˙ê$Ií$©‚0 ë$I%+s	åüœçå”€¬Ü'€%É ‡ﬂn‡ª>$Ií$I™0@$IR…»Ÿ”F¿Ïß »áÑ™–Î6Ët5ƒﬂè$ﬂÓ˙8ÆQuº∞Ω]í$Ií$ïs í$©¯-„oÇ¨ëqÀ3°ﬂêRøÿ.y®Æè˚Àï›Ì˙ê$Ií$©"0 ë$I≈gÁ?VåçåS¡Ä·ÿ~≈zŸM;˜qÛ3cÂÄ]í$Ií$UD í$©ËÂÁ¬OG^yïªb‚‡§ﬂAœõ °r±]6^˚h˜åY∆.ª>$Ií$I™–@$IR—⁄07≤…˘Ê%ëq£Æp∆£ê⁄≤X/k◊á$Ií$I˙&Iít‰¬˘Ÿ,ÿΩ™¶A„ì‡@6ºÛò˜bdMR8˝O–·àâ)∂RÏ˙ê$Ií$Iáb "IíéÃ“∑`¬p»ﬁÙı\•ŒÉú]ëqáK·Ù?BïZ≈Z ¶ù˚∏Âøãô˛e◊G«F’y»ÆIí$IíÑà$I:KﬂÇ◊.Ç¬Û˚wD˛Y≠úˇWh“≠XÀ¯v◊GB\7ˆ9Ü´∫e◊á$Ií$I@$I“·
ÁG:?æ~|S(ç∫kY˚∏˘?Öª>º†=Gß⁄ı!Ií$Iíæf "Iíœg≥
øˆÍP≤7F÷5ÌQ‰óÇÄ—}Œü∆,µÎCí$Ií$˝ IíÙ√ve¬¨«oÌÓÕE~yª>$Ií$I“ë2 ë$Iﬂm«ß˛_`˛Àêüsxü©öVdó?T◊«ß√Ø{ÿı!Ií$Iíæüà$I:ÿñÂ0ÛQX<Ç¸»\ÉN∞}Ï›Œ°˜	Ar=h|Rëî`◊á$Ií$I˙)@$I“◊6~Ô=À«|=◊Ï4ËqC$ÿXˆ6ºv9¢pÚe7Fø˚!&ˆ'ï£Á}Ÿı±ﬂÆIí$IíÙ„ÄHíT—|ˆ~$¯X3ÂÎ˘ñgB˜°Pˇ∏ØÁZù?˚;L^xCÙ‰zë£’Y?©îå¨}‹Úﬂ≈L[È˙Ë–∞:]ÿé£S´˝§ÛJí$Ií§ä« Dí§ä*`’‰H±·É»\(⁄^›á@jãCÆ’Y–b |6+≤·y’¥Hw»OË¸∞ÎCí$Ií$5Ií*öp>,{+|d.éÃ≈&@«K°€ıP£…ü#&öˆ(ír2≥ˆsÀ1’ÆIí$IíTÑb¢]Ä ó3fpÊôgRØ^=B°oæ˘f°„°PËêø|¡Ç5€∑oÁíK.!99ôÍ’´s’UW±{˜ÓBÁY¥h=zÙ†R•J4lÿêë#GTÀË—£i—¢ï*U¢m€∂å7ÆXÓYí å¸\òˇ2<Ÿ	Fˇ2~ƒWÅì~É√è^¯QDÇ ‡µè6p˙£”ô∫‚‚b∏π^ø¶´·á$Ií$I˙…Ï Që⁄≥gÌ€∑Á +Ø‰ºÛŒ;ËxFFF°Ò¯Ò„πÍ™´8ˇ¸ÛÊ.π‰222ò<y2πππ¸ÍWø‚Í´ØÊïW^ ;;õ>}˙–ªwoFç≈‚≈ãπÚ +©^Ω:W_}5 ≥fÕ‚‚ã/fƒàúq∆ºÚ +úsŒ9|¸Ò«¥i”¶$© ›ˇf=Y"sï™CÁk†ÛˇAÂö%^“∑ª>⁄7¨Œ√v}Hí$Ií§"
Ç àv*üB°oºÒÁúsŒwÆ9ÁúsÿµkÔæ˚. Àñ-£U´V|¯·áúp¬	 Lò0Å˘ÁüSØ^=û~˙inªÌ6233IHH ‡ÊõoÊÕ7ﬂd˘ÚÂ ¸¸Á?gœû=å3¶‡Z]∫t°Cáå5Í∞ÍœŒŒ&%%Ö¨¨,íììÃoÅ$E◊˛l¯Ëo0˚Iÿ	®í
']'\	â%6A¿ÎÛ>ÁèﬂÿÎcËÈ«ÎÓMâãµ1Uí$Ií ø_S¥Ÿ¢®Ÿºy3c«éÂ•ó^*òõ={6’´W/? z˜ÓMLLsÊÃ·‹sœeˆÏŸÙÏŸ≥ ¸ Ë€∑/< ;vÏ†FçÃû=õ°Cá∫^ﬂæ}z%ó$ïK{∂¡úßaÓ≥∞?+2ó“∫_.Ö¯JQ)ÀÆIí$IíTí@5/ΩÙ’™U+Ù™¨ÃÃLRSS≠ããã£fÕödff¨i⁄¥i°5iii«j‘®Afff¡‹7◊|uéC9p‡ (gggˇ∏ì§h…ﬁ≥ûÄy/@Óﬁ»\Ìc†˚Ph{ƒ∆G•¨É∫>bcr˙1¸¶á]í$Ií$©¯Ä(jû˛y.π‰*UäŒˇâ¸m#Få‡ÓªÔévít‰∂ØÖ˜ˇ^Å¸ú»\›ˆ–„FhqƒD/d8T◊«C¥£yö]í$Ií$©xÄ(*ﬁ{Ô=V¨X¡øˇ˝ÔBÛÈÈÈlŸ≤•–\^^€∑o'==Ω`ÕÊÕõ≠˘j¸Ckæ:~(∑‹rK°◊fegg”∞a√#º3I*Aõó¬ÃG`… GÊù=oÄfßA(µ“Ç ‡?o‰Ó∑?±ÎCí$Ií$EÖà¢‚o˚«<Ì€∑/4ﬂµkWvÓ‹…ºyÛ8˛¯„ò2e
·pòŒù;¨πÌ∂€»ÕÕ%>>Ú:ó…ì'sÏ±«R£FçÇ5Ôæ˚.É.8˜‰…ìÈ⁄µÎw÷îòòHbbbQﬁ¶$èœÁ¡{√ä±_œ}:Ù
çOä^]_ Ã⁄œ≠o,f ÚH†›æA
]ÿﬁÆIí$IíT¢@T§vÔﬁÕÍ’´∆Î÷≠c¡Ç‘¨YìFçëŒä—£GÛ√Ù˘ñ-[“Ø_?~Ûõﬂ0j‘(rssπÓ∫Î∏Ë¢ã®WØ ø¯≈/∏˚ÓªπÍ™´>|8Kñ,·/˘è>˙h¡yÆø˛zN>˘d~¯a»´Øæ G}ƒ≥œ>[ÃøíTLÇ >}/|¨ùˆÂdZù=nàºÚ™ÂáÊÆ€Œñ]˚I≠VâNMk¬ÆIí$IíTjÑÇ ¢]Ñ èi”¶—´WØÉÊØ∏‚
^|ÒE û}ˆYLFF)))≠›æ};◊]woø˝6111ú˛˘<ˆÿcT≠Zµ`Õ¢Eã4h~¯!µk◊Êwø˚√á/tû—£Gs˚Ì∑ÛÈßü“ºysFé…Ä˚^≤≥≥III!++ã‰‰‰√˛ú$© Äï"¡«ÁFÊb‚†›œ°€`®sLâó4aIwøΩîå¨˝s©’IMNd…∆l¿ÆIí$IíﬂØ)˙@§Ô‡–í¢*úüº3ÖÕK"s±âp‹Â–Ì˜PΩQT ö∞$Ék_˛òÔ˙·!.&ƒ–>«puè£Ï˙ê$Ií§
ŒÔ◊mæKí§“$/Ω	>∂ØçÃ%TÖØÇ.É†ZZ‘JÀ‹˝ˆ“Ô? jTN‡ˇz6#6&z∞Kí$Ií$Åà$I•CŒ^¯¯Ô0Î1»ﬁôK™]~ù~˘˜(õªn{°◊^ ª0w›v∫6´UBUIí$Ií$öà$I—¥?Ê><{∑EÊ™¶√IøÉ„	âUø˜„%·@^>ÔØﬁ ®Èkk˝ñ]ﬂíHí$Ií$ïIí¢aœ÷HË1˜98Ÿ8úÍç°˚`Ëp	ƒ%Fµº˝π˘L[ÒñdÓ≤-Ï:êwÿüM≠V©+ì$Ií$I:< í$ï§¨œa÷0ÔE»€ô´”z‹ ≠œÉÿË˝ßyœÅ<¶Æÿ¬¯≈ôL]±ÖΩ9˘«“ì+—ßuce∞cOŒ!˜	È)ïË‘¥fâ’,Ií$IíÙ]@$I*	€÷D66_¯*Ñs#sı:Bè·ÿï≤≤˜Á2eŸ∆-Œ`˙ /8ê.8Vøz⁄¶”ØM]:6¨NLLàìö’‚⁄ó?&ÖBêØ∂<øÎÃVnÄ.Ií$IíJIíäSÊò˘|Ú_ÜMzD:>é:B%Ï‹õ√§•õô∞$ìô´∂íìˇuË—§Ve˙∑≠Kˇ6È¥≠üBË[ııkSóß/=éªﬂ^ZhCÙÙîJ‹uf+˙µ©[b˜!Ií$IíÙ}@$I*>Ñ˜Üï„øûkﬁ7|4Í\‚Âl›}ÄIülf¸ífØŸF^¯Î˛çÊ©UÈﬂ&ù˛mÎ“"Ω⁄A°«∑ıkSó”[•3w›v∂Ï⁄Ojµ»kØÏ¸ê$Ií$I•âà$IE%`›tòÒ|˙ﬁóì!h}.tu€ïh9õ≥˜3ÒìL∆-Œ`Ó∫Ì|#Û†e›d¥Iß€téN≠vƒÁéç	—µY≠"¨Ví$Ií$©hÄHíÙSÖ√ëNè˜ÜçÛ"s1q–˛"Ë6j]b•l‹πèÒã3ò∞$ìyÎw|#Ùh◊ Ö˛m"Ø∑jRªJâ’$Ií$Ií í$˝X˘yëΩ=f>[ñFÊ‚í‡¯+†ÎuPΩaâîÒŸ∂=å_í…¯≈,¸<´–±„◊†õt˙∂NßaÕ %Rè$Ií$IRi` "I“ë ; ˇ3ˇ;÷EÊì·ƒ_CóﬂB’:≈^¬Í-ªô∞$Éqã3Yöë]0
Aß&5–∂.}[ßìûR©ÿkë$Ií$I*ç@$I:\9{`ﬁã0Îqÿïô´\∫\'˛í™€•É `≈Ê]å[ú…Ñ%¨‹ºª‡XlLàÆG’¢€t˙¥JßNµƒb´Cí$Ií$©¨0 ë$ÈáÏ€sˇ
<˚∂GÊ™’Énøá„.áÑ‚ŸO#>ŸîÕ∏≈å_í…∫≠{
é≈«ÜË~tm˙∑©ÀÈ≠“®Q%°Xjê$Ií$I*´@$I˙.ª∑¿Ï'·√øAŒÆ»\ç¶–}HdÉÛ∏¢Ô¥á|æì	K2∑8ÉœwÏ+8ñ√…«‘a@€tNmëFJR|ë__í$Ií$©º0 ë$È€vnÄYè¡«áº˝ëπ‘V–„huƒÌ>Û√Û>€¡∏≈L¸$ìå¨˝«í‚cÈ’¢˝€‘•WãT™&˙ünIí$Ií§√·∑(í$}eÎ™»∆Êã^Öp^dÆ˛	–ÛFhﬁbbäÏRy˘aÊÆ€Œ∏%LX≤ô≠ª´ö«©-R–6ùìèI%)!∂»Æ+Ií$IíTQÄHíî±ﬁ{ñ˛"sMOét|4Ì	°Pë\&'/Ã¨5[ô∞$ìIK7≥}ON¡±‰Jqúﬁ*ù˛m“Èﬁº6ï‚=$Ií$Ií~
IR≈µ˛ÉH±j“◊s«ÄÓC°·âErâ˝π˘Ã\µïqK2xgÈf≤˜Á´Y%Å>≠“Ëﬂ∂.]è™EB\—uòHí$Ií$Ut í§ä%`ÕxÔ¯lfd.≠œãlnûﬁÊ'_b_N>”Wna‹‚L¶,ﬂ¬Ó_áu™%“∑u⁄‘•S”öƒ≈zHí$Ií$IR≈√ä±ëéèMÛ#s1Ò–·–Ìz®’Ï'ù~˜Å<¶,ﬂ¬Ñ%L]˛˚rÛé’M©Dø6ÈÙoSó„◊ 6¶h^©%Ií$Ií§Ôf "I*ﬂÚsa…"[WDÊ‚í‡Ñ_A◊Î •˛è>u÷æ\ﬁ]∂ôÒK2ôæÚrÚ¬«÷L¢õ∫ÙkìNá’â1Ùê$Ií$I*Q í§Ú)w?,¯'ºˇgÿπ>2óòù~]ÆÖ*µ‘iwÏ…aÚ“Õå[í¡˚´∑íõkZª
˝€§3†m]Z◊K&TDõßKí$Ií$È»ÄHí óªaﬁ0Î	ÿùô´\∫ÇØÇJ)G| /v`‚'ôLXí…Ïµ€»zìVï˛mÍ“øm:«¶U3Ùê$Ií$I*%@$IÂ√ﬁÌ0˜Yò3
ˆÌàÃ%7ÄnøáéóABÂ#:]f÷~&,…`¸íLÊ~∫ù‡ÎÃÉVuì–6ù~mÍrtj’"º	Ií$Ií$IRŸ∂+f?	=9ª#s5õA˜!–ÓÁópÿß˙|«^&,…d‹‚>^ø≥–±ˆ´”øM:˝€§”∏Vï"ºIí$Ií$IRŸ¥„3xˇ/0ˇe»?ôKk=ÜB´≥!&ˆ∞NÛÈ÷=å[í¡Ñ%ô,˙<´–±◊†€»FÊı´'ıHí$Ií$©ÄHí ñ/V¿ÃGa—k‰GÊtÇû7BÛ>p{p¨ﬁ≤ãqã3ø$ìeŸÛ1!Ë‘¥&⁄÷•oÎt“í+◊]Hí$Ií$©òÄHí ÜMÛ·ΩG`Ÿ€¿ór’z‹ M∫oÀ3w1~q„ñd≤zÀÓÇc±1!NjVã˛mÍ“ßuµ´&ÛçHí$Ií$©$ÄHíJ∑œf¡åá`Õª_œµ8#Ú™´˙«Á«Ç `Ò∆,∆/…d¸‚>›∂∑‡X|làÕÎ–øM:ß∑J£zÂ√ﬂ'Dí$Ií$IeÉà$©Ù	X˝.º˜¨üô≈B€"õõß∂<‰«¬·Ä˘v2~q„ód≤qÁæÇcâq1ú|L¥≠À©-SIÆ_w"Ií$Ií§(1 ë$ï·0,{ﬁ{2EÊb†√%–Ìz®ŸÙ†è‰á>˙t;„ód2aI&ôŸ˚é%≈«rjãT˙∑Mß◊±©TIÙ?{í$Ií$IÖﬂIí¢/?èélnæued.æ2úp%tΩíÎZûóÊÉµ€ø$Éâüd≤uwN¡±™âqÙnôJø6u9˘ò:$%ƒñ‰ùHí$Ií$©î0 ë$EOÓ>òˇ2ºˇd≠èÃUJÅŒ◊D~UÆY∞4'/Ã˚k∂2~qìónf«ﬁ‹Çc)IÒúﬁ*çm”Èvtm„=$Ií$Ií*:IR…;∞>¸Ã~ˆlâÃUIÖÆÉ"]ïíÿüõœ{´æ=ñmf◊˛ºÇS‘™í@ü÷iÙoSóÆÕjç;ë$Ií$IR)e "I*9{∑√úQë_˚≥"s)#˚{tº‚ìÿõì«¥/71ü≤l3{rÚ>ûZ-ë~m“È◊&ùNMjgË!Ií$Ií§Ô` "I*~Ÿ0˚	¯Ë»›ô´’zÖ∂≤+¶|≤ÖÒã3ô∂r˚s√≠óRâ~mÍ2†m:«5™ALL(J7!Ií$Ií§≤ƒ DíT|∂ØÉ˜ˇ˛	˘_nTûﬁz‹@V„~º≥b+„_^¿åï[……ˇ:ÙhT≥2˝€§”øm]⁄7H!2Ùê$Ií$I“ë1 ë$Ω-À`Ê£∞¯uæ|ÖU£ÆÏÍt=c˜¥b¸úÕºˇœ)‰ÖÉÇèUß
⁄‘•_õtZ◊K6Ùê$Ií$I“Ob "I*:Á¡{è¿Ú1SöÙbZÍÂº¥±s^ŸN~xI¡±È’Ë◊&ùmÎ“<µ™°á$Ií$Iíäåà$Èß	¯t&º˜0¨ùô"ƒg©ßÒt˛Ÿº∂¢¡rÄm ¥©üLˇ/;=ö’©Ω∫%Ií$IíTÆÄHí~ú ÄUì"¡«Ü9 ÑC±LO<Ö{≤˙±f}˝Ç•Vg@€t˙µÆK£Zï£U±$Ií$Ií*I“ë	Á√“ˇE^uµy1 9ƒÛÔºìy&ˇL>ﬂWáPNlR£†”£^ı§(-Ií$Ií§ä∆ DítxÚrΩJÓÙGH»Z¿Ó†/Á˜Êoy˝Ÿ™Aó£jÒm“È€:ù‘‰JQ.Xí$Ií$Iôà$È{9{»úˆU>zä‰úÕ$ ;É*ºê◊èóÉ~¥>∫	7¥IÁÙVi‘™öÌr%Ií$Ií$¿ DítA∞dÌ∂N{ö˛I]≤ ÿTÁ˘lh˙3zµo∆îñi§Téèrµí$Ií$I“¡@$I Ñ√Øﬂ¡¥˘À©Ω‰yŒÀK€–^ >Í0ΩŒ%$wΩÇA≠R≠í°á$Ií$IíJ7I™¿Ú√s◊mg¸í>^¸	ÁÓÉﬂ∆N°rË Ñ #°1õ€˝ñÊß^¡%ï›»\í$Ií$Ieáà$U0π˘a>Xªçqã3ôº4ì*{÷Û±os{Ï‚Ú»™—ö§SáS∑ıô‘çââr≈í$Ií$I“ë3 ë§
‡@^>≥Voc‹‚&/€ÃŒΩπZœqoqF‚lb	 7ÍFLœHiv*ÑBQÆZí$Ií$I˙Ò@$©ú⁄üõœÙï_0aI&Ô,›ÃÆy t≠fH“[ú|Ùı‚Ê}†«ƒ4Í•j%Ií$Ií§¢e "IÂ»ûyL[Ò„ñd0u˘ˆÊ‰y$`@’U‹PiÕvD§·#≠ŒÜC°n˚(V-Ií$Ií$=I*„vÌœe Ú-å[ú¡¥_p /\p¨AJ"øk∏ÜÅYØPıã∞àâÉvA˜¡Pªy¥ ñ$Ií$Iíäïà$ï"˘·ÄπÎ∂≥e◊~R´U¢S”öƒ∆º«ŒΩ9L^∫ô	K2yo’VrÚø=◊™ÃÄ÷©\T˘#-Ehı“»Å∏Jp‹Âp“Ô°z√í∫%Ií$Ií$)*@$©îò∞$Éªﬂ^JF÷˛Çπ∫)ï∏ÎÃVÙkSómª0iÈf∆-Œ`ˆöm‰ÖÉÇuÕÍTa@€∫hYì[∆z(l_9òPNº
∫Ç™©%}[í$Ií$IRTÄHR)0aI◊æ¸1¡∑Ê3≤ˆsÕÀsLZUVoŸÕ72Z§Wc@€∫ÙoìNÛ1Òﬂ·µ«`◊¶»Ç§ö–Â∑–È◊êT£ƒÓEí$Ií$I*@$) Ú√wøΩÙ†„õVnﬁ@€˙)ÙoõNˇ6uiZª
Ï€	éÇûÜΩ€"ã´’Öì~«]âUãΩ~Ií$Ií$©42 ë§(õªn{°◊^}ó«.Í¿YÍGªøÄwÇˇ
≤#s5ö@˜!–˛bàK,æÇ%Ií$Ií§2¿ Dí¢lÀÆØ√è¬täYN*;ŸBuÊÜ[& “!íı9ÃzÊΩy˚"™”z‹ ≠œÖXˇXó$Ií$Ií¿ Dí¢Æjb‰è‚æ1sπ+˛Ô‘m/8∂)®…›πó≥2hH◊≈o¿[oB87r∞ﬁq–ÛF8¶?ƒƒD°rIí$Ií$©Ù2 ë§(Z∑u˜é]Jﬂòπ<ˇÁÉéß≥ùQÒ&
ªÊÀ]BöÙàMOÜP®dñ$Ií$Ií Iäíô´∂2ËïèŸµÔ ØT˙Û≠<„´q,4Ô=oÄÜùJæXIí$Ií$©å1 ë§/Õ˙î?ç]F~8‡“ÙœIﬂπ~®ô„§Î?$Ií$Ií§√d "I%('/Ã]o-·_s7 pﬁqıπÛò=Êa|x˜Êb≠Mí$Ií$I*O@$©Ñl€}Äkˇ˘1s◊m'Ç[˚∑‰◊=öZ≥ÌNP5≠xî$Ií$Ií I*À2≤˘Õﬂ?‚Û˚®ñ«cw§WãTÿ∫
&›˘üAr=h|Râ‘*Ií$Ií$ï íTÃ&}í…‡/`oN>MjUÊØWú¿—©’`¡ø`Ïêª™AŒ."Åﬂ¯ÙóÉÙªbb£PΩ$Ií$IíT6ÄHR1	ÇÄ'ßÆÊ°I+Ëvt-û¸≈qTèÕÅ7ÆÅÖˇä,l“Œ{>ˇ&áÏM_ü$π^$¸huVÓ@í$Ií$I*ª@$©ÏœÕgÿÎãx{a$Ã¯ÂIM∏m`K‚ø¯Fˇ
∂≠ÇPúrÙ∏!“›—Í,h1>õŸºjZ‰µWv~Hí$Ií$IGÃ DíäXf÷~~Û˜èXº1ã∏ò<ªøË‘>¸+LºÚ@µzp˛_°I∑¬éâÖ¶=¢S∏$Ií$IíTéÄHRöø~Wˇc_Ï:@ç Ò<}ÈÒt©Ø]Àﬁä,:¶ú˝T©›b%Ií$Ií§rÃ Díä»Û?g¯ììÊÿ¥j¸ıäh∏Áu%d≠áòx8˝nËÚ[Ö¢]Æ$Ií$IíTÆÄH“Oî9q9œL_¿È≠“xÙgÌ®:Ôix˜èŒÉM‡ÇÁ°˛Ò—-Ví$Ií$I™ @$È'ÿµ?óÎ_]¿îÂ[ ‘´7úTìò◊/Ü’ÔDµ>Œ¸3TJâ^°í$Ií$IRc "I?“g€ˆÎó>b’ñ›$∆≈0ÚÇvúù≤û9vgB\%Ëˇ wÖØºí$Ií$IíJòà$˝≥÷lÂ∑ˇ¸òù{sIKN‰ŸK:–~Ì≥ÊH Ä⁄«¬Ö/@ZÎhó*Ií$Ií$UH ítÑ˛Ò¡g‹˝÷'‰Ö⁄7¨Œ_œ©GùIó√gÔGtº˙èÑÑ*—-Tí$Ií$I™¿@$È0ÂÊá˘√[üœ9Î8ßC=F∂À$·ÂKaﬂvH®
g¸⁄]›B%Ií$Ií$ÄH“·ÿ±'ákˇ9è÷n'ÇõOo∆’9'Ù⁄ìëu€√/@≠f—-Tí$Ií$I` "I?hÂÊ]\ı“álÿæè*	±<{F-∫-∏6}Y–˘8˝èó›B%Ií$Ií$0 ë§ÔÒŒ“Õ\ˇÍ|ˆ‰‰”®fe^ÌñAΩw≤°Ru8Á)h10⁄eJí$Ií$I˙I:Ñ 5}-#'.'†G”*¸5ıø$N~)≤†ag8ˇoPΩatï$Ií$IítH íÙ-˚sÛπ˘?ãxs¡& ÜtÛ˚Ì∑Z∏Aè°p -›B%Ií$Ií$}'I˙ÜÕŸ˚π˙ÛX∏a'±1è„Vq“ä w/TIÖÛûÅfßFªLIí$Ií$I?¿ Díæ¥p√NÆ˛«GlŒ>@Ω§<˛◊‰?‘YÚø»¡£NÅsüÖjiQ≠Qí$Ií$I“·1 ë$‡6r”Îã8ê¶_≠Õ<ˇ8ÒÎ÷B(z›
›áBLL¥Àî$Ií$Iítò@$Uh·p¿√ìW‰‘5@¿ΩıfÒã¨ÁÌ…Å‰p¡ﬂ†Qóhó)Ií$Ií$ÈÄH™∞v»c»ø0yÈfRÿÕkuˇ…±€ßG; Œ~*◊ånëí$Ií$Ií~I“ÜÌ{˘ıK±bÛ.:«≠‚Öj£®º#b‡Ù?AÁˇÉP(⁄eJí$Ií$I˙ë@$U8¨›∆µ/œcÁﬁ´<ûﬂØ⁄ó5èÇ^Äz¢]¢$Ií$Ií§ü» DRÖÚ úı‹˘ø%TÔ‰ø’û•cÓ¸»Å∂¬¿G†Rrtî$Ií$IíT$@$Uπ˘aÓ≥îófF∑ò≈<]e…π; .	</ıïWí$Ií$IR9b "©‹€π7áAØ|Ã´∑pC‹∏.ÓÑÚHmyÂUjãhó(Ií$Ií$©àÄH*◊VoŸ≈Ø_˙à€6Z‚Z9p¸/°ÔH®’˙$Ií$Ií$IÂ÷‘Â[¯˝øÊ”9wWzÜvCB58Î/–Ê¸hó'Ií$Ií$©ÄH*wÇ ‡π˜÷Ú¯≈è˝W&Là®◊.xj›%Ií$Ií$;IÂ ˛‹|n}c1ÛÊœ„ı¯«hÛi‰@óA–˚óÕÚ$Ií$Ií$ïIÂ∆ñ]˚˘øÃ£·Á„ì7™Öˆ$’ tŒ(8∂_¥Àì$Ií$IíTÇ@$ïK6fq›KÔsÕﬁg∏(aZd≤—IÑŒˇ+§‘èjmí$Ií$IíJûà§2oÃ¢Må=ÜgCÊò∏çÑı'áXˇòì$Ií$Ií*"øîTf‰ÁÂ±|ŒDˆÌÿHRç˙sbü∫Ü-3ûct‹ﬂI
ÂÆíJÃ˘Ö£Névπí$Ií$Ií¢» DRô0‚K‘õ}7≠ŸV0ó9©=¬u81~% A≥”à9˜®Z'ZeJí$Ií$I*%@$ïzÛ'æD˚YøèB_œß±ÉÙÿ‰ClÔªùÙ{àââNëí$Ií$IíJø)îT™ÂÁÂQoˆ› ƒÑ
Ö  ãj‰wπŒCí$Ií$IRø-îT™-ü3ë4∂~|%Çöd±|Œƒí-Lí$Ií$IR©Ê+∞$ïJrÛ¯É˜œxÍ∞÷Ô€±±ò+í$Ií$IíTñÄH*5ÇúΩ¨û;ûÌÛﬂ¢Ò∂˜Ë˛çœHRç˙≈Xô$Ií$Ií§≤∆ DRteob˚Ç∑Ÿπ‡mÍmüCsr
Ì'Åı)'íûµÄ™¡ûCæ+¿ñP-ZtÓ[ÇEKí$Ií$I*Ì@$ï¨p2Ês‡ì±ÏY2éöŸÀ®	‘¸ÚpFPãµ5ªS£√ô€e «$Vf˛ƒóh?Î˜ÑÉ¬°áÉ/?”ı.“„¸„Lí$Ií$I“◊¸∆PRÒ;∞÷N#ºbπÀ'ê∏+â@"BÃéfMıÓ‘Ïx&]ªˆ§[•¯BÔÿ˜
ÊıfﬂM⁄7^ãµ%TãåÆw—±Ô%z;í$Ií$IíJøPA¥ãêJ£ÏÏlRRR»  "999⁄Âî=;>Öï	VN X7ìò◊Ø∂⁄$1#‹ñO™t%ı¯3È€©uSí~î˘yy,ü3ë};6íT£>-:˜%÷ŒIí$Ií§R…Ô◊m~s(©h‰Á¡Á¬ 	ë__, ÙÂØO√iº>éN§~˚”8˜Ñ¶®óL(tàç=æCl\≠ª,û˙%Ií$Ií$ï+ í~º};`ıª∞r"¨û)/à·£‡XﬁÕÔ»å–	›≤ÁﬂÄÀõ◊!>6&äEKí$Ií$I™@$æ Ä≠´æÏÚòÎgCê_p8+®¬îp¶‰wdz∏«6i»y«5‡∫∂uIIäˇûKí$Ií$IR—2 ë*¢p>|6voÜ™i–¯$àâ=Ù⁄ºX?+x¨ú €◊:º&‘êIπx7ø#ÛÉÊ4®UçÛ:6`X«˙4™UπnFí$Ií$Iíf "U4KﬂÇ	√!{”◊s…ı†ﬂ–Í¨»x˜ëWZ≠ú ´ß@ŒÆÇ•˘°x∆µÂ{€2%‹ÅA…ï‚8„¯z‹r\}ékT„àˆıê$Ií$Ií§‚` "U$KﬂÇ◊.Ç¬ÛŸ⁄e–Êÿ˘|˛Q°5k37˛^Ÿ—ä˘≠ŸCq1!Nië ≠«’ßWãT*≈Gâ$Ií$Ií$EÅàTQÑÛ#ùﬂ?‡Îπ%ØÃÏ©Ÿö‚;Ò◊ÕÕ˘ ´ëçÀ€5H·ºéı9≥}=jUM,˛∫%Ií$Ií$ÈG0 ë*äœf~Ì’wòWÔ‹∑„4ÊmJ*ò´õRâs;÷Áº„Ístjµ‚¨Rí$Ií$IíäÑàTQÏﬁ|XÀ^˙¥&Û¬ITNà•õ∫ú\}∫Uãò˜ıê$Ií$IíTvÄHD~ïTgóé¥zçx¥[{˙∂NßrÇDHí$Ií$I*õ¸vS™ ÊÊ∑†qPìt∂s®fép ô‘‚‘æÁ“µyj…(Ií$Ií$IE(&⁄H*[ˆ‰rwÓÂ@$Ï¯¶Ø∆wÁ^∆ñ=π%\ô$Ií$Ií$=©ÇH≠Vââ·N\õ;òLj:ñI-ÆÕÃƒp'R´UäRÖí$Ií$IíTt|ñTAtjZì∫)ïòî’â…N†SÃrRŸ…™37‹ÇÄÍ¶T¢S”ö?|2Ií$Ií$I*ÂÏ ë*àÿòwùŸ
ÄÄ>∑‚≠I|nEÂwùŸäÿCm"Ií$Ií$IeåàTÅÙkSóß/=éÙî¬ØπJO©ƒ”óGø6u£Tô$Ií$Ií$-©3fpÊôgRØ^=B°oæ˘ÊAkñ-[∆YgùEJJ
U™T·ƒOd˝˙ı«˜Ôﬂœ†AÉ®U´U´VÂ¸ÛœgÛÊÕÖŒ±~˝zHÂ ïIMMeÿ∞a‰ÂÂZ3m⁄4é;Ó89˙Ë£yÒ≈ã„ñÀú~mÍ2s¯©¸Î7]¯ÀE¯◊o∫0s¯©Üí$Ií$Ií ©={ˆ–æ}{û|Ú…C_≥f›ªwßEãLõ6çEãq«wP©“◊	CÜ·Ì∑ﬂfÙË—Lü>ùMõ6qﬁyÁœœœg‡¿Å‰‰‰0k÷,^zÈ%^|ÒEÓºÛŒÇ5Î÷≠c‡¿ÅÙÍ’ã0x`~˝Î_3q‚ƒ‚ª˘2$6&D◊fµ8ªC}∫6´ÂkØ$Ií$Ií$ï;° Çh°Ú)
Ò∆opŒ9ÁÃ]t—Eƒ««Ûè¸„êü…  ¢Nù:ºÚ +\p¡ ,_æúñ-[2{ˆl∫tÈ¬¯Ò„9„å3ÿ¥iiii å5ä·√áÛ≈_êêê¿·√;v,Kñ,)tÌù;w2a¬Ñ√™?;;õîî≤≤≤HNN˛ëøí$Ií$IR≈‰˜kä6;@Tb¬·0c«éÂòcé°oﬂæ§¶¶“πsÁBØ…ö7oπππÙÓ›ª`ÆEã4j‘àŸ≥g0{ˆl⁄∂m[~ ÙÌ€óÏÏl>˘‰ìÇ5ﬂ<«Wkæ:á$Ií$Ií$©|3 QâŸ≤eªwÔÊ˛˚Ôß_ø~Lö4âsœ=óÛŒ;èÈ”ßêôôIBB’´W/ÙŸ¥¥4233÷|3¸¯Í¯W«æoMvv6˚ˆÌ;d} ;;ª–/Ií$Ií$IRŸÌTqÑ√a Œ>˚lÜ@áò5k£Fç‚‰ìOéfyå1ÇªÔæ;™5Hí$Ií$IíäÜ *1µk◊&..éV≠ZöoŸ≤%Î◊Ø ==ùúúvÓ‹YhÕÊÕõIOO/X≥yÛÊÉéuÏ˚÷$''ìîît»˙nπÂ≤≤≤
~mÿ∞·«›®$Ií$Ií$)Í@Tb8ÒƒY±bE°˘ï+W“∏qc é?˛x‚„„y˜›wéØX±ÇıÎ◊”µkW ∫vÌ ‚≈ãŸ≤eK¡ö…ì'ìúú\ÆtÌ⁄µ–9æZÛ’9%11ë‰‰‰Bø$Ií$Ií$IeìØ¿Rë⁄Ω{7´WØ.Ø[∑éP≥fM5jƒ∞a√¯˘œNœû=È’´&L‡Ì∑ﬂf⁄¥i §§§p’UW1tËPj÷¨Irr2ø˚›ÔË⁄µ+]∫t†Oü>¥j’äÀ.ªåë#Gíôô…Ì∑ﬂŒ†AÉHLL‡ökÆ·â'û‡¶õn‚ +Ød î)ºˆ⁄kå;∂ƒO$Ií$Ií$I%/AÌ"T~Lõ6ç^Ωz4≈W‚ã/¸Ûœ3bƒ>ˇ¸sé=ˆXÓæ˚nŒ>˚ÏÇµ˚˜ÔÁÜn‡_ˇ˙†oﬂæ<ı‘SØ∑¯Ï≥œ∏ˆ⁄kô6mU™T·ä+Æ‡˛˚Ô'.ÓÎLo⁄¥i2Ñ•Kó“†AÓ∏„~˘À_ˆΩdggìííBVVñ› í$Ií$I“Ú˚5EõàÙ¸Zí$Ií$I˙Ò¸~M—Ê í$Ií$Ií$©‹1 ë$Ií$Ií$IÂéà$Ií$Ií$I*w@$Ií$Ií$IRπc "Ií$Ií$Ií Ií$Ií$IíTÓÄHí$Ií$Ií§r« Dí$Ií$Ií$ï; í$Ií$Ií$©‹1 ë$Ií$Ií$IÂéà$Ií$Ií$I*w@$Ií$Ií$IRπc "Ií$Ií$Ií Ií$Ií$IíTÓƒEª ©¥
Ç ÄÏÏÏ(W"Ií$Ií$ï=_}Øˆ’˜lRI3 ëæ√Æ]ª hÿ∞aî+ë$Ií$Ií Æ]ªvëííÌ2TÖ„7Èê¬·0õ6m¢ZµjÑB°hósX≤≥≥iÿ∞!6l 999⁄ÂHöœ£T:¯,J•áœ£Tz¯<J•GyÉ `◊Æ]‘´WèòwcP…≥D˙1114h– ⁄e¸(………ÂÚ?öRY‰Û(ï>ãRÈ·Û(ï>èRÈQûüG;?M∆ní$Ií$Ií$©‹1 ë$Ií$Ií$IÂéàTé$&&r◊]wëòòÌR§
œÁQ*|•“√ÁQ*=|•“√ÁQ*^nÇ.Ií$Ií$Ií ;@$Ií$Ií$IRπc "Ií$Ií$Ií Ií$Ií$IíTÓÄHí$Ií$Ií§r« D*'û|ÚIö4iB•JïË‹π3sÁŒçvIRô6bƒN<ÒD™U´Fjj*Áús+V¨(¥fˇ˛˝4àZµjQµjUŒ?ˇ|6oﬁ\hÕ˙ıÎ8p ï+W&55ïa√ÜëóóWhÕ¥i”8Ó∏„HLL‰Ë£èÊ≈_,Ó€ì ¥˚ÔøüP(ƒ‡¡ÉÊ|•í≥q„F.ΩÙRj’™ERRm€∂Â£è>*8wﬁy'uÎ÷%))âﬁΩ{≥j’™BÁÿæ};ó\r	………TØ^ù´Æ∫ä›ªwZ≥h—"zÙËA•Jïhÿ∞!#Gé,ë˚ì Ç¸¸|Ó∏„ö6mJRRÕö5„O˙A¨ÒYîä«å38ÛÃ3©WØ°Pà7ﬂ|≥–Òí|ˆFèMã-®T©m€∂e‹∏qE~øRYg "ïˇ˛˜ø:t(w›u¸1Ì€∑ßoﬂælŸ≤%⁄•Ie÷ÙÈ”4h|ì'O&77ó>}˙∞gœûÇ5CÜ·Ì∑ﬂfÙË—Lü>ùMõ6qﬁyÁœœœg‡¿Å‰‰‰0k÷,^zÈ%^|ÒEÓºÛŒÇ5Î÷≠c‡¿ÅÙÍ’ã0x`~˝Î_3q‚ƒΩ_©¨¯√yÊôgh◊Æ]°yüG©dÏÿ±Én›∫œ¯Ò„Y∫t)?¸05j‘(X3r‰H{Ï1Fç≈ú9s®R•
}˚ˆeˇ˛˝k.π‰>˘‰&OûÃò1cò1cW_}u¡ÒÏÏl˙ÙÈC„∆çô7o>¯ ¯√xˆŸgKÙ~•“ÍÅ‡ÈßüÊâ'û`Ÿ≤e<¿å9í«º`çœ¢T<ˆÏŸC˚ˆÌyÚ…'yº§ûΩY≥fqÒ≈s’UW1˛|Œ9ÁŒ9Áñ,YR|7/ïEÅ§2ØSßN¡†AÉ
∆˘˘˘AΩzıÇ#FD±*©|Ÿ≤eK ”ßOÇ vÓ‹ƒ««£Gè.X≥lŸ≤ fœûAå7.àââ	233÷<˝Ù”Arrrp‡¿Å Ç‡¶õn
Z∑n]ËZ?ˇ˘œÉæ}˚˜-IeŒÆ]ªÇÊÕõì'ON>˘‰‡˙ÎØÇ¿ÁQ*I√á∫wÔ˛ù«√·pêûû<¯‡És;wÓÉ˝Î_A¡“•K ¯√÷å?>ÖB¡∆çÉ Çßûz*®Q£F¡Û˘’µè=ˆÿ¢æ%©L8p`pÂïWö;ÔºÛÇK.π$üE©§ ¡oºQ0.…gÔg?˚Y0p‡¿BıtÓ‹9¯øˇ˚ø"ΩG©¨≥D*„rrrò7oΩ{˜.òãââ°wÔﬁÃû=;äïIÂKVV 5k÷`ﬁºy‰ÊÊzˆZ¥hA£Fç
ûΩŸ≥g”∂m[“““
÷ÙÌ€óÏÏl>˘‰ìÇ5ﬂ<«Wk|~•É4àÅÙÃ¯<J%Á≠∑ﬁ‚ÑN‡¬/$55ïé;Ú‹sœ_∑nôôôÖû•îî:wÓ\Ëy¨^Ω:'úpB¡öﬁΩ{√ú9s
÷ÙÏŸìÑÑÑÇ5}˚ˆe≈äÏÿ±£∏oS*ıN:È$ﬁ}˜]VÆ\	¿¬Öô9s&˝˚˜|•h)…gœü]•√c "ïq[∑n%??ø–: iiidffF©*©|	á√<òn›∫—¶M 233IHH†zıÍÖ÷~ÛŸÀÃÃ<‰≥˘’±Ô[ìùùÕæ}˚ä„v§2È’W_Â„è?fƒàÛyîJŒ⁄µky˙Èßiﬁº9'N‰⁄kØÂ˜øˇ=/ΩÙıÛÙ}?õfffíööZËx\\5k÷<¢gV™»næ˘f.∫Ë"Z¥hA||<;vd‡¡\r…%Äœ¢-%˘Ï}◊üM©∞∏h IRi7h– ñ,Y¬Ãô3£]äT!mÿ∞ÅÎØøû…ì'S©R•hó#Uh·pòN8Å˚ÓªÄé;≤d…Fç≈W\ÂÍ§ä„µ◊^„üˇ¸'ØºÚ
≠[∑.ÿª™^Ωz>ãí$}É RWªvmbccŸºys°˘Õõ7ìûû•™§Ú„∫ÎÆcÃò1Lù:ïÃßßßììì√Œù;≠ˇÊ≥óûû~»gÛ´cﬂ∑&99ô§§§¢æ©Lö7o[∂l·∏„é#..é∏∏8¶OüŒcè=F\\iii>èR	©[∑.≠Zµ*4◊≤eK÷Ø_|˝<}ﬂœ¶ÈÈÈlŸ≤•–Òºº<∂oﬂ~Dœ¨Të6¨†§m€∂\vŸe2§†S“gQäéí|ˆækçœ¶TòàT∆%$$p¸Ò«ÛÓªÔÃÖ√aﬁ}˜]∫vÌ≈ §≤-ÆªÓ:ﬁx„¶LôB”¶M?˛¯„âèè/ÙÏ≠X±ÇıÎ◊<{]ªveÒ‚≈Ö~∏ù<y2………_uÌ⁄µ–9æZ„Û+}Ì¥”NcÒ‚≈,X∞†‡◊	'ú¿%ó\RÔ>èR…Ë÷≠+V¨(4∑rÂJ7n@”¶MIOO/Ù,egg3gŒúBœ„Œù;ô7o^¡ö)S¶áÈ‹πs¡ö3fêõõ[∞fÚ‰…{Ï±‘®Q£ÿÓO*+ˆÓ›KLL·Øtbcc	á√Äœ¢-%˘Ï˘≥´tò¢Ωª§üÓ’W_É_|1X∫tipı’W’´W233£]öTf]{ÌµAJJJ0m⁄¥ ##£‡◊ﬁΩ{÷\sÕ5A£FçÇ)S¶}ÙQ–µk◊†k◊Æ«ÛÚÚÇ6m⁄}˙Ù	,XLò0!®SßNpÀ-∑¨YªvmPπrÂ`ÿ∞a¡≤eÀÇ'ü|2àçç&LòP¢˜+ï5'ü|rp˝ı◊å}•í1wÓ‹ ...∏˜ﬁ{ÉU´Vˇ¸Á?É ï+/ø¸r¡ö˚Ôø?®^Ωzøˇ˝/X¥hQpˆŸgMõ6ˆÌ€W∞¶_ø~A«éÉ9sÊ3gŒö7o\|Ò≈«wÓ‹§••ó]vY∞d…í‡’W_*WÆ<ÛÃ3%zøRiu≈WıÎ◊∆å¨[∑.¯Ôˇ‘Æ];∏È¶õ
÷¯,J≈c◊Æ]¡¸˘ÛÉ˘ÛÁ@»#èÛÁœ>˚Ï≥ JÓŸ{ˇ˝˜É∏∏∏‡°á
ñ-[‹u◊]A|||∞xÒ‚í˚Õê  ©úx¸Ò«ÉFç			AßNùÇ>¯ ⁄%Iep»_/ºB¡ö}˚ˆø˝ÌoÉ5jï+WŒ=˜‹ ##£–y>˝Ù”†ˇ˛ARRRPªvÌ‡Ünrss≠ô:uj–°Cá !!!8Í®£
]C“°}; ÒyîJŒ€oø¥i”&HLLZ¥h<˚Ï≥Öéá√·‡é;Ó“““Çƒƒƒ‡¥”NV¨XQhÕ∂m€Çã/æ8®Zµjêúú¸ÍWø
vÌ⁄UhÕ¬ÖÉÓ›ªâââA˝˙ıÉ˚ÔøøÿÔM*+≤≥≥ÉÎØø>h‘®QP©R•‡®£é
nªÌ∂‡¿Åk|•‚1uÍ‘C˛]Òä+ÆÇ†düΩ◊^{-8ÊòcÇÑÑÑ†uÎ÷¡ÿ±cãÌæ•≤*AùﬁIí$Ií$Ií§‚· í$Ií$Ií$©‹1 ë$Ií$Ií$IÂéà$Ií$Ií$I*w@$Ií$Ií$IRπc "Ií$Ií$Ií ùˇoÔ^cª,>éˇ˛ïÇ‘™•&Dà•äZ#0ÇQ¶¶±ûàö®≈h’†é√‚ Ü≥L#õŸﬁ({10ô—DÅ7õ™4*ZAA©<—†õU•v/à›”¡”Éﬁ~>		ˇ∂˜u_◊’7ÑoÆ˚@     Ä¬@     Ä¬@  ÄüçŒŒŒîJ•º¸ÚÀáz*IíÊÊÊ455}´kÊœüü3œ<ÛGô  _  ¿¸ê·ÂŒ;ÔÃ”O?˝Ω∆X¥hQJ•Rﬂüäääå7.Kñ,˘ﬁÛ Ä¢@   ˛UTT§™™Í{è3d»êtuu•´´+ÌÌÌô>}zfÃòë≠[∑˛ ≥ Äü?  ~&Möî€nª-≥gœNeee™´´Û◊ø˛5ü~˙ifŒúô¡Éß∂∂6O=ıTøÎ^}ı’\p¡©®®HuuuÆπÊö|¯·á}ﬂ‚â'R__üÚÚÚTUU•°°!ü~˙ií§≠≠-gü}vî°Cáf‚ƒâŸæ}{í§££#_|q™´´SQQë≥Œ:+≠≠≠˝Ó›’’ïã.∫(ÂÂÂ9rd}Ù—å1">¯`ﬂœ|¸Ò«π·Ür‹q«e»ê!ô<yr6m⁄Ù≠ˆÊ@kú4iRnø˝ˆÃô3'«sLÜñ˘ÛÁ˜cÀñ-9˜‹ss‰ëGÊ‘SOMkkkJ•Rñ-[ñ$9rdídÃò1)ïJô4iRøÎx‡Å‘‘‘§™™*≥fÕ _|ÒŒ˜?Î´«h}õ1í§T*eÿ∞a6lXFçï{ÔΩ7»ÊÕõºi   Ä  ¿œƒ‚≈ãsÏ±«f˝˙ıπÌ∂€rÀ-∑‰ä+Æ»Ñ	Ú“K/e⁄¥iπÊökÚŸgü%Ÿ&Oûú1c∆d„∆çYæ|yﬁˇ˝Ãò1#…æ@q’UWÂ˙ÎØœkØΩñ∂∂∂\zÈ•ÈÌÌÕﬁΩ{”‘‘îÛœ??õ7oŒ⁄µk”““íR©î$ÈÓÓŒÖ^òßü~:ÌÌÌ˘ıØù∆∆∆Ïÿ±£oæ◊^{mﬁ{ÔΩ¥µµÂ…'üÃ¬Ö≥k◊Æ~k∫‚ä+≤k◊Æ<ı‘SyÒ≈3vÏÿLô2%ªwÔ>®=9–ˇÁﬁ4(Î÷≠À˝˜ﬂü{Óπ'´V≠JíÙÙÙ§©©)GuT÷≠[óÖfÓ‹π˝Æ_ø~}í§µµ5]]]˝5µzıÍtttdıÍ’Yºxq-ZîEã‘¸®1zzz≤xÒ‚$…ÿ±cø’Ω †®JΩΩΩΩáz  ¿7õ4iRzzzÚ‹sœ%Ÿ˜ﬁG}t.ΩÙ“<Ú»#Iíù;w¶¶¶&k◊ÆÕ¯Ò„sÔΩ˜ÊπÁûÀä+˙∆yÁùw2|¯l›∫5›››7n\:;;s‚â'ˆªﬂÓ›ªSUUï∂∂∂ú˛˘5«”O?=7ﬂ|snΩı÷lŸ≤%£GèŒÜÚ´_˝*I≤m€∂å5*˙”ü2{ˆÏ<ˇ¸ÛπË¢ã≤k◊Æqƒ}„‘÷÷fŒú9iiiŸÔùùù9rd⁄€€sÊôgpçuuu˚Ì]íú}ˆŸô<yr˛á?d˘ÚÂillÃ€oøùa√Ü%Ÿ:¶Nùö•Kó¶©©iø˚~•ππ9mmmÈËËHYYYíd∆å0`@{Ï±Ø›ß˘ÛÁgŸ≤e}Ô˘.c,Z¥(3gŒÃ†AÉí${ˆÏ…aáñáz(ÕÕÕﬂÙk Ä_åÅáz  ¿¡9„å3˙˛^VVñ™™™‘◊◊˜}≠∫∫:I˙NYl⁄¥)´WØNEE≈~cuttd⁄¥iô2eJÍÎÎ3}˙ÙLõ6-ó_~y*++sÃ1«§ππ9”ßOœ‘©S”––ê3f§¶¶&…æ ÛÁœœ?˛ÒètuueÔﬁΩŸ≥gOﬂ	ê≠[∑f‡¿Å˝N#‘÷÷¶≤≤≤ÔÛ¶Mõ“››Ωﬂ˚0ˆÏŸìéééÉ⁄ì≠±ÆÆnøΩKíöööæ}⁄∫ukÜﬁ?í}Å‰`ùv⁄i}·‚´±_yÂïÉæ˛ªé1x‡ºÙ“KIíœ>˚,≠≠≠π˘ÊõSUUï∆∆∆ou  ("  ~&;Ï∞~üK•RøØ}ıx™/ø¸2…æH—ÿÿò˚Óªoø±jjjRVVñU´VÂÖ^» ï+Ûóø¸%sÁŒÕ∫uÎ2r‰»¸ÌoÀÌ∑ﬂûÂÀóÁÒ«œºyÛ≤j’™å?>wﬁygV≠Zïx µµµ)//œÂó_ûœ?ˇ¸†◊”››ùööö¥µµÌ˜Ω°CáÙﬂ¥∆Ø|›ﬁ}µOﬂ◊1ˆwc¿Ä©≠≠Ì˚|∆gdÂ ïπÔæ˚  à   Ö5vÏÿ<˘‰ì1bD¸˙˙óJ•Lú81'NÃ›wﬂùO<1Kó.Õw‹ëdﬂKø«åìªÓ∫+ÁúsN}Ù—å?>k÷¨Isss.π‰í$˚BDgggﬂ∏'ü|rˆÓ›õˆˆˆå7.…æG`}Ù—G˝Ê∑sÁŒ80#Få¯—÷x 'ü|rﬁ~˚Ìºˇ˛˚}ßh6lÿ–Ôg?¸$˚=ˆSVVVñ={ˆÍi  ¿OÇó† @AÕö5+ªwÔŒUW]ï6§££#+V¨»Ãô3”””ìuÎ÷Â˜øˇ}6n‹ò;vd…í%˘‡É2zÙËºı÷[πÎÆª≤vÌ⁄lﬂæ=+WÆÃoºë—£G'IFçï%Kñ‰Âó_Œ¶Mõrı’W˜;±p )ß§°°!---Yø~}⁄€€”““íÚÚÚæì*9Áús“‘‘îï+W¶≥≥3/ºBÊŒùõç7˛ k<SßNÕI'ùîÎÆª.õ7oŒö5k2oﬁº$ˇ=Us¸Ò«ßºººÔ%Îˇ˙◊ø˙˜cÈÌÌÕŒù;≥sÁŒºı÷[Y∏paV¨Xëã/æ¯PO  ~  (®N8!k÷¨IOOO¶Mõñ˙˙˙Ãû=;CáÕÄ2d»ê<˚Ï≥π¬SWWóyÛÊe¡Çπ‡Çr‘QGeÀñ-πÏ≤ÀRWWóñññÃö5+7›tSí‰è¸c*++3a¬Ñ466f˙ÙÈ˝ﬁ˜ë$è<ÚH™´´sﬁyÁÂíK.…ç7ﬁò¡ÉÁ»#èL≤/.¸ÛüˇÃyÁùóô3g¶ÆÆ.W^ye∂oﬂﬁw„˚ÆÒ`îïïeŸ≤eÈÓÓŒYgùïn∏!sÁŒMíæπ80˛ÛüÛ√ÁÑN¯IDÜˇ˚ﬂ©©©IMMMFèù‰û{ÓÈõ;  ¸“ïz{{{ı$  Ä‚{Áùw2|¯¥∂∂f î)áz:ﬂhÕö59˜‹s≥m€∂út“Iáz:  ¿w Ä   ?ägûy&›››©ØØOWWWÊÃôìwﬂ}7Øø˛˙~/˝>‘ñ.]öäääå5*€∂mÀo~ÛõTVVÊ˘Áü?‘S  æ#/A  ~_|ÒE~˜ªﬂÂÕ7ﬂÃ‡¡É3a¬Ñ¸˝Ôˇ…≈è$˘‰ìOÚ€ﬂ˛6;vÏ»±«õÜÜÜ,X∞‡PO  ¯ú      
«K–    Ä¬@     Ä¬@     Ä¬@     Ä¬@     Ä¬@     Ä¬@     Ä¬@     Ä¬@     Ä¬@     Ä¬@     Ä¬@     Ä¬@     Ä¬@     Ä¬@     Ä¬@     Ä¬@     Ä¬@     Ä¬@     Ä¬@     Ä¬@     Ä¬@     Ä¬@     Ä¬@     Ä¬@     Ä¬@     Ä¬@     Ä¬@     Ä¬@     Ä¬@     Ä¬@     Ä¬@     Ä¬@     Ä¬@     Ä¬@     Ä¬@     Ä¬@     Ä¬@     Ä¬@     Ä¬@     Ä¬@     Ä¬@     Ä¬@     Ä¬@     Ä¬@     Ä¬@     Ä¬@     Ä¬@     Ä¬@     Ä¬@     Ä¬@     Ä¬@     Ä¬@     Ä¬@     Ä¬@     Ä¬˘˛KÒHm1    IENDÆB`Ç
```

## Key Encapsulation Mechanism

As for the signature we can divide the KEM in four main parts: the generation of the *private key*, the generation of the *public key*, the *encapsulation/encryption* and the *decapsulation/decryption*. Looking at the table below you can see that **kyber512 is even faster than ECDH in the computation of private and public keys**, while Stremlined NTRU Prime takes a lot more time to compute the private keys, but it is faster than Kyber512 in the generation of the public key. As before time is measured in Œºs (microsecond) and the memory in KiB (Kibibyte)

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
  Zenroom js bindings üß∞</br>
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


## üíæ Install

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

## üéÆ Usage

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

## üìñ Tutorials

Here we wrote some tutorials on how to use Zenroom in the JS world
  * [Node.js](/pages/zenroom-javascript1b)
  * [Browser](/pages/zenroom-javascript2b)
  * [React](/pages/zenroom-javascript3)

For more information also see the [üåêJavascript NPM package](https://www.npmjs.com/package/zenroom).
<p align="center">
  <br/>
  <a href="https://dev.zenroom.org/">
    <img src="https://dev.zenroom.org/_media/images/zenroom_logo.png" height="140" alt="Zenroom">
  </a>
  <h2 align="center">
    zenroom.py üêç
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
## üíæ Installation

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

Open PowerShell (press **ü™ü + r**, type **powershell** and press enter), then: 

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
## üéÆ Usage

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
## üìã Testing

Tests are made with pytests, just run 

`python setup.py test`

in [`zenroom_test.py`](https://github.com/dyne/Zenroom/blob/master/bindings/python3/tests/test_all.py) file you'll find more usage examples of the wrapper

***
## üåê Links

https://decodeproject.eu/

https://zenroom.org/

https://dev.zenroom.org/

## üòç Acknowledgements

Copyright (C) 2018-2025 by [Dyne.org](https://www.dyne.org) foundation, Amsterdam

Originally designed and written by Sam Mulube.

Designed, written and maintained by Puria Nafisi Azizi 

Rewritten by Danilo Spinella and David Dashyan

<img src="https://upload.wikimedia.org/wikipedia/commons/8/84/European_Commission.svg" width="310" alt="Project funded by the European Commission">

This project is receiving funding from the European Union‚Äôs Horizon 2020 research and innovation programme under grant agreement nr. 732546 (DECODE).

***

## üë• Contributing
Please first take a look at the [Dyne.org - Contributor License Agreement](https://github.com/dyne/Zenroom/blob/master/Agreement.md) then

1.  üîÄ [FORK IT](https://github.com/dyne/Zenroom//fork)
2.  Create your feature branch `git checkout -b feature/branch`
3.  Commit your changes `git commit -am 'Add some fooBar'`
4.  Push to the branch `git push origin feature/branch`
5.  Create a new Pull Request `gh pr create -f`
6.  üôè Thank you

***

## üíº License

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
# Make üíè with Zencode and Javascript: use Zenroom in node.js

This article is part of a series of tutorials about interacting with Zenroom VM inside the Javascript/Typescript messy world. This is the first entry and at the end of the article you should be able to implement your own encryption library with Elliptic-curve Diffie‚ÄìHellman.

The code used in this article is available on [Github](https://github.com/dyne/blog-code-samples).

## üìë Some RTFM and resources

So first things first, let‚Äôs start by where to look for good information about Zenroom (docs that are continuously under enhancement and update).

- [https://dev.zenroom.org](https://dev.zenroom.org) this is the main source of technical documentation
- [https://zenroom.org](https://zenroom.org) here you find more informative documentation and all the products related to the main project
- [https://apiroom.net](https://apiroom.net) a very useful playground to try online your scripts

## üåê How a VM could live in a browser?

So basically Zenroom is a virtual machine that is mostly written in C and high-level languages and has no access to I/O and no access to networking, this is the reason that makes it so portable.


In the past years we got a huge effort from nice projects to transpile native code to Javascript, we are talking about projects like [emscripten](https://emscripten.org/), [WebAssembly](https://webassembly.org/) and [asm.js](http://asmjs.org/)


This is exactly what we used to create a WASM (WebAssembly) build by using the Emscripten toolkit, that behaves in a good manner with the JS world.

## üíª Let‚Äôs get our hands dirty

So let‚Äôs start by our first hello world example in node.js I‚Äôm familiar with yarn so I‚Äôll use that but if you prefer you can use `npm `


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

Yay, ü•≥ we just run our hello world in node.js

Let's go through lines; In first line we import the zencode_exec function from the zenroom package. Two major functions are exposed:

 - **zencode_exec** to execute Zencode (DSL for smart contracts that reads like English).
 - **zenroom_exec** to execute our special flavor of Lua enhanced with Zenroom‚Äôs [special effects](./lua).

Before you ü§¨ on me for the underscore casing, this was a though decision but is on purpose to keep the naming consistent across all of our bindings.

**zencode_exec** is an asynchronous function, means return a Promise (more on promises [here](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Using_promises)) and accepts two parameters:

- the smart contract, mandatory, in form of string
- an optional object literal that can contain {data, keys, conf} in brief data and keys is how you pass data to your smart contract, and conf is a configuration string that changes the Zenroom VM behaviour. All of them should be passed in form of string‚Ä¶ this means that even if you need to pass a JSON you need to JSON.stringify it before, as we did on line 5 of the previous snippet

**zencode_exec** resolves the promise with an object that contains two attributes:

- result this is the output of the execution of the smart contract in form of string
- logs the logs of the virtual machine‚Ä¶ if there are some errors ‚Äî warning they are printed here

In the previous snippet we just passed the *result* by using [Object destructuring](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/Destructuring_assignment#object_destructuring) on line 8


## üîè Let‚Äôs complicate it a bit! Let‚Äôs encrypt!
Now that we saw how the basics works, let‚Äôs proceed with some sophistication: let's encrypt a message with a password/secret with ECDH **(Elliptic-curve Diffie‚ÄìHellman)** on the elliptic curve SECP256K1 sounds complicated, isn't it?


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

Et voila ü§Ø as easy as the hello the world‚Ä¶ if you run it you'll get something like:

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

## üîè Next step: decryption

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
    console.log("üéâ üéâ üéâ ");
    console.log("Yeah! It works");
    console.log("üéâ üéâ üéâ ");
  }
})();
```

There you go encryption ‚Äî decryption with password ‚Äî secret over Elliptic-curve Diffie‚ÄìHellman on curve SECP256K1 in 30 super easy lines of code.

The code used in this article is available on [Github](https://github.com/dyne/blog-code-samples).
# Make üíè with Zencode and Javascript: use Zenroom in the browser

This article is part of a series of tutorials about interacting with Zenroom VM inside the messy world of JavaScript/Typescript.
By the end of the article you should be able to launch a new encryption service with Elliptic-curve Diffie‚ÄìHellman within your browser (Plain JS and HTML).

The code used in this article is available on [Github](https://github.com/dyne/blog-code-samples).


## üèπ Let's create a encrypt/decrypt service
So you have just experimented how to encrypt and decrypt a message with a password/secret with ECDH (Elliptic-curve Diffie‚ÄìHellman) on the elliptic curve SECP256K1 (Did you? No? Then, jump back to [Zenroom in node.js](/pages/zenroom-javascript1b)).
Now say you love simple things and you just need some basic functions inside your HTML page (no npm, no nodejs, no fancy hipster new shiny stuff) with the good ol' Plain JavaScript.
NO PROBLEM. You bet we love it.

## üíª Let‚Äôs get our hands dirty: üîè encryption

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
     <button onClick="encrypt()">üîê Encrypt</button>
     <br/>
     <textarea id="encrypted" readonly></textarea>
  </body>
</html>
```

The expected result is something like:

![javascript-2a](../_media/images/javascript-2a.png)

It's ugly, almost unusable, but It works! ü•≥
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
                  onClick="encrypt()">üîê Encrypt</button>
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

Yeah this is much better üíÖüèº

## üîè Next step: decryption


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
                <button class="button is-primary" onClick="encrypt()">üîê Encrypt</button>
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
                <button class="button is-primary" onClick="decrypt()">üîì Decrypt</button>
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

What if the password is wrong? Validation is demanded just in the ZenroomVM so I've just added a *catch* to the *zencode_exec* promise (see line 51‚Äì71) that will show the logs in the result element if something goes wrong!

The code used in this article is available on [Github](https://github.com/dyne/blog-code-samples).
# Make üíè with Zencode and Javascript: use Zenroom in React



## üèπ Let‚Äôs create a encrypt/decrypt service
So you have just experimented how to encrypt and decrypt a message with a password/secret with ECDH (Elliptic-curve Diffie‚ÄìHellman) on the elliptic curve SECP256K1 in Plain Javascript (Did you? No? Then, jump back to [Zenroom in the browser](zenroom-javascript2b)).

Now let's add some interactivity and see how we can play and interact with Zencode smart contracts within React.


## üíª Let‚Äôs get our hands dirty

Let‚Äôs start by creating a standard React project with the [CRA](https://reactjs.org/docs/create-a-new-react-app.html) tool, and add Zenroom as a dependency

```bash
npx create-react-app zenroom-react-test
```

Using npm you should now have into `zenroom-react-test` a file structure like this

```bash
.
‚îú‚îÄ‚îÄ package.json
‚îú‚îÄ‚îÄ package-lock.json
‚îú‚îÄ‚îÄ public
‚îÇ   ‚îú‚îÄ‚îÄ favicon.ico
‚îÇ   ‚îú‚îÄ‚îÄ index.html
‚îÇ   ‚îú‚îÄ‚îÄ logo192.png
‚îÇ   ‚îú‚îÄ‚îÄ logo512.png
‚îÇ   ‚îú‚îÄ‚îÄ manifest.json
‚îÇ   ‚îî‚îÄ‚îÄ robots.txt
‚îú‚îÄ‚îÄ README.md
‚îî‚îÄ‚îÄ src
‚îÇ   ‚îú‚îÄ‚îÄ App.css
‚îÇ   ‚îú‚îÄ‚îÄ App.js
‚îÇ   ‚îú‚îÄ‚îÄ App.test.js
‚îÇ   ‚îú‚îÄ‚îÄ index.css
‚îÇ   ‚îú‚îÄ‚îÄ index.js
‚îÇ   ‚îú‚îÄ‚îÄ logo.svg
‚îÇ   ‚îú‚îÄ‚îÄ reportWebVitals.js
‚îÇ   ‚îî‚îÄ‚îÄ setupTests.js
‚îî‚îÄ‚îÄ node_modules
‚îÇ   ‚îú‚îÄ‚îÄ ...
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

Hoorayyy!!!  You just run a Zencode smart contract in React with no fuss. ü•≥ü•≥ü•≥ And with this now you are able to maybe create your `<Zencode>` or `<Zenroom>` components and endless creative and secure possibilities.


## üîè Let‚Äôs complicate it a bit! Let‚Äôs encrypt!

Now that we saw how the basics works, let‚Äôs proceed with some sophistication: let‚Äôs encrypt a message with a password/secret with **ECDH (Elliptic-curve Diffie‚ÄìHellman)** on the elliptic curve SECP256K1 sounds complicated, isn‚Äôt it?

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

Et voila ü§Ø as easy as the hello the world! We added an encryption function, and some component to give some styling. If you run it you‚Äôll get something like:


<img src="../_media/images/zenroom-react2.gif" alt="drawing" width="1200"/>




It's embarrassing fast, encryption with password over Elliptic-curve Diffie‚ÄìHellman on curve SECP256K1 in react! Now hold tight until next week for the part 4‚Ä¶ in the meantime clap this post and spread it all over the socials.

One last thing, you‚Äôll find the working code project on [Github](https://github.com/dyne/blog-code-samples/tree/master/zencode-javascript-series/part3-react)
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

       const keys = {‚Äúkey‚Äù: ‚Äúvalue‚Äù}; //Insert here "keys" parameter to pass
       const data = {‚Äúkey‚Äù: ‚Äúvalue‚Äù}; //Insert here "data" parameter to pass

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

		// Important: if the parameters ‚Äúkeys‚Äù or ‚Äúdata‚Äù are empty, 
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
pod install ‚Äì-repo-update
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
# Make ‚ù§ with Zenroom in ClojureScript

This article shows how to use Zenroom from ClojureScript using shadow-cljs, by [transducer](https://github.com/transducer/zenroom-cljs-demo/blob/master/blogpost.md).



### üíª npm

Install [shadow-cljs](https://github.com/thheller/shadow-cljs) and the zenroom bindings using `npm` or `yarn`:

```sh
# npm
npm install -g shadow-cljs --save-dev
npm install zenroom

# yarn
yarn global add shadow-cljs --dev
yarn add zenroom
```

### üíª shadow-cljs

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

### ‚úç Build hook to be browser ready

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

### ‚òØ  ClojureScript interop

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

### ‚òï More code

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
‚îî‚îÄ‚îÄ android
    ‚îî‚îÄ‚îÄ jniLibs
        ‚îú‚îÄ‚îÄ arm64-v8a
        ‚îÇ   ‚îî‚îÄ‚îÄ libzenroom.so
        ‚îú‚îÄ‚îÄ armeabi-v7a
        ‚îÇ   ‚îî‚îÄ‚îÄ libzenroom.so
        ‚îî‚îÄ‚îÄ x86
            ‚îî‚îÄ‚îÄ libzenroom.so
```

To use it in your project just drop `src/Zenroom.java` inside your codebase and the put `jniLibs` and its contents directly into your Android project under `src/main`

```
src/main/jniLibs/
‚îú‚îÄ‚îÄ arm64-v8a
‚îÇ   ‚îî‚îÄ‚îÄ libzenroom.so
‚îú‚îÄ‚îÄ armeabi-v7a
‚îÇ   ‚îî‚îÄ‚îÄ libzenroom.so
‚îî‚îÄ‚îÄ x86
    ‚îî‚îÄ‚îÄ libzenroom.so
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
