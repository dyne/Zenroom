<!-- Unused files
 
givenDebugOutputVerbose.json
givenLongOutput.json
 

Link file with relative path: <a href="./_media/examples/zencode_cookbook/givenArraysLoadInput.json">givenArraysLoadInput.json</a>
 
-->




# The *When* statements: all operations with data

The *When* keyword introduces the phase of Zencode execution, where data can be manipulated. The statemens executed in this phase allow you to: 
 - Manipulate objects: rename, append, cut, insert, remove, etc.
 - Create objects: different schemas can be created in different ways (including random objects), and values assigned to them.
 - Execute cryptography: this is where all the crypto-magic happens: creating keypairs, hashing points...
 - Comparisons: compare value of numbers, strings and complex objects.
 
## First, let's get a nice JSON 
 
We've done this already: let's start with create a file named *myLargeNestedObjectWhen.json*. This file contains everything we need for every part of this chapter and - along  with the *Given* part of the script, you can use this JSON to later make your own experiments with Zencode.

[](../_media/examples/zencode_cookbook/myLargeNestedObjectWhen.json ':include :type=code json')

 

### Loading the content of the JSON 

Since the *When* phase contains many statements, we did split the scripts in four parts. The part of script that loads the JSON can be used for all the scripts below.


[](../_media/examples/zencode_cookbook/whenCompleteScriptGiven.zen ':include :type=code gherkin')



## Manipulation: sum/subtract, rename, remove, append... 

We grouped together all the statements that perform object manipulation, so: 


 ***Sum and subtract*** two numbers
 
 ***Append*** a simple object to another
 
 ***Rename*** an object
 
 ***Insert*** a simple object into an array
 
 ***Remove*** an element from an array
 
 ***Split*** a string
 
 ***Randomize*** the elements of an array
 
 ***Create string/number*** (statement "write in")
 
 ***Pick a random element*** from an array
 
 ***flatten*** an array into a string
 
 
In the script below, we've put together a list of this statement and explained in the comments how each statement works: 
 

[](../_media/examples/zencode_cookbook/whenCompleteScriptPart1.zen ':include :type=code gherkin')


To play with the script, first save it into the file *whenCompleteScriptPart1.zen*. Then run it while loading the data, using the command line:

```bash
zenroom -a myLargeNestedObjectWhen.json -z whenCompleteScriptPart1.zen | jq | tee whenCompleteOutputPart1.json
``` 

The output should look like <a href="../_media/examples/zencode_cookbook/whenCompleteOutputPart1.json" download>whenCompleteOutputPart1.json</a>. Remember that the output gets sorted alphabetically, because in Zenroom *determinism is King*.

## Create regular or random objects 

In the second group we gathered the *When* statements that can create new objects and assign values to them.


 The "create" statements can ***generate random numbers*** (or arrays thereof), with different parameters.

 The "set" statements allow you to ***create an object and assign a value to it***. 
 

 See our example script below: 
 

[](../_media/examples/zencode_cookbook/whenCompleteScriptPart2.zen ':include :type=code gherkin')



The output should look like <a href="../_media/examples/zencode_cookbook/whenCompleteOutputPart2.json" download>whenCompleteOutputPart2.json</a>.

## The statement "Create the (name of schema)"

By now we have been using the statement "Create" a bit, let's get a better look at it. 

The statement *Create the* works only to create **schemas**, which are particular objects, whose names and structures are predefined.

in *Zencode*, *the* is a keyword indicating that a **schema** is about to be created. The structure of the **schema** created by the statement, matches the word(s) following the keyword "the", and the name of object created will also be the same.

A general version of the statement looks like this: 

```gherkin
When I create the <name of the schema>
``` 

Some schemas need no **scenario** to work, and those are all listed on this page. Other schemas are typically described in the manual pages of the scenarios they belong to. Some examples are: 

A statement we have use extensively already from the scenario 'ecdh'
```gherkin
When I create the keypair
``` 

As you probably know by now, this statement outputs something looking like this: 

```json
{    "keypair": {
      "private_key": "AxLMXkey00i2BD675vpMQ8WhP/CwEfmdRr+BtpuJ2rM=",
      "public_key": "BDDuiMyAjIu8tE3pGSccJcwLYFGWvo3zUAyazLgTlZyEYOePoj+/UnpMwV8liM8mDobgd/2ydKhS5kLiuOOW6xw="
    }
  }
``` 


Another examples of the statement, from the scenario 'credential':

```gherkin
When I create the credential keypair
``` 

An example, from the scenario 'petition':

```gherkin
When I create the petition signature 'nameOfThePetitionIWantToSign'
``` 

And an exotic version of the statement is the one used to transform the formatting of an object to CBOR (if originally in JSON) or to JSON (if originally in CBOR): 

```gherkin
When I create the cbor of 'myJsonObject'
When I create the json of 'myCborObject'
``` 

We're sparing you the full list of **schemas** that you can create, but the best place to see a full and updated list is <a href="https://apiroom.net">https://apiroom.net</a>. 


## Basic cryptography: hashing

Here we have grouped together the statements that perform: 


 ***Basic hashing***
 
 ***Hashing a number to a point on a curve***
 
 ***Key derivation function (KDF)***
 
 ***Password-Based Key Derivation Function (pbKDF)***
 
 ***Hash-based message authentication code (HMAC)***
 
 ***Aggregation of ECP or ECP2 points***

Keep in mind that in order to use more advanced cryptography like encryption, zero knowledge proof, zk-SNARKS, attributed based credential or the [Coconut](https://arxiv.org/pdf/1802.07344.pdf)  flow you will need to select a *scenario* in the beginning of the scripts. We'll write more about scenarios later, for now we're using the "ecdh" scenario as we're loading an asymetric keypair from the JSON. See our example below:




[](../_media/examples/zencode_cookbook/whenCompleteScriptPart3.zen ':include :type=code gherkin')



The output should look like this: <a href="../_media/examples/zencode_cookbook/whenCompleteOutputPart3.json" download>whenCompleteOutputPart3.json</a>.




## Comparing strings, numbers, arrays 

This group includes all the statements to compare objects, you can:


 ***Compare*** if objects (strings, numbers or arrays) are equal
 
 See if a ***number is more, less or equal*** to another 
 
 See ***if an array contains an element*** of a given value.


See our script below:


[](../_media/examples/zencode_cookbook/whenCompleteScriptPart4.zen ':include :type=code gherkin')



The output should look like 
<a href="../_media/examples/zencode_cookbook/whenCompleteOutputPart4.json" download>whenCompleteOutputPart4.json</a>. 




## Operations with dictionaries

The last group includes all the statements that are exclusive to ***dictionary*** objects. A dictionary is a complex object made of an array of complex objects, where all the objects in the array have the same structure. You can use dictionaries for examples with a list of transactions, a list of accounts, a list of data entries.

***Compare if objects*** (strings, numbers or arrays) are equal.

***Find maximum and minimum values*** among an array different 

***See if a number is more, less or equal*** to another. 

***See if an array contains*** an element of a given value.

Load this dataset:

[](../_media/examples/zencode_cookbook/dictionariesBlockchain.json ':include :type=code json')


with this script

[](../_media/examples/zencode_cookbook/dictionariesGiven.zen ':include :type=code gherkin')

and do this computation:

[](../_media/examples/zencode_cookbook/dictionariesWhen.zen ':include :type=code gherkin')



The output should look like this: 

[](../_media/examples/zencode_cookbook/dictionariesComputationOutput.json ':include :type=code json')




# The script used to create the material in this page

All the smart contracts and the data you see in this page are generated by the scripts [run-when.sh](https://github.com/dyne/Zenroom/blob/master/test/zencode_cookbook/run-when.sh) and [run-dictionaries.sh](https://github.com/dyne/Zenroom/blob/master/test/zencode_cookbook/run-dictionaries.sh). If you want to run the scripts (on Linux) you should: 
 - *git clone https://github.com/dyne/Zenroom.git*
 - install **zsh** and **jq**
 - download a [zenroom binary](https://zenroom.org/#downloads) and place it */bin* or */usr/bin* or in *./Zenroom/src*









<!-- Temp removed, 


-->
### 
