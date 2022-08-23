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

[](../_media/examples/zencode_cookbook/cookbook_when/myLargeNestedObjectWhen.json ':include :type=code json')

 

### Loading the content of the JSON 

Since the *When* phase contains many statements, we did split the scripts in four parts. The part of script that loads the JSON can be used for all the scripts below.


[](../_media/examples/zencode_cookbook/cookbook_when/whenCompleteScriptGiven.zen ':include :type=code gherkin')



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
 

[](../_media/examples/zencode_cookbook/cookbook_when/whenCompleteScriptPart1.zen ':include :type=code gherkin')


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

And an exotic version of the statement is the one used to transform the formatting of an object to CBOR (if originally in JSON) or to JSON (if originally in CBOR): 

```gherkin
When I create the cbor of 'myJsonObject'
When I create the json of 'myCborObject'
``` 

We're sparing you the full list of **schemas** that you can create, but the best place to see a full and updated list is <a href="https://apiroom.net">https://apiroom.net</a>. 


## Create regular or random objects and render them

In the second group we gathered the *When* statements that can create new objects and assign values to them.


 The "create" statements can ***generate random numbers*** (or arrays thereof), with different parameters.

 The "set" statements allow you to ***create an object and assign a value to it***. 
 
 The "create the cbor of" statement allows you ***render an object to CBOR***. The statement also has a counterpart to render to JSON: "create the json of".
 
 A special case is the stament "create key", which we see in two flavours, one ***creates a key from a random seed***, one ***from a known seed***.
 

 See our example script below: 
 

[](../_media/examples/zencode_cookbook/cookbook_when/whenCompleteScriptPart2.zen ':include :type=code gherkin')



The output should look like <a href="../_media/examples/zencode_cookbook/cookbook_when/whenCompleteOutputPart2.json" download>whenCompleteOutputPart2.json</a>.



## Basic cryptography: hashing

Here we have grouped together the statements that perform: 


 ***Basic hashing***
 
 ***Hashing a number to a point on a curve***
 
 ***Key derivation function (KDF)***
 
 ***Password-Based Key Derivation Function (pbKDF)***
 
 ***Hash-based message authentication code (HMAC)***
 
 ***Aggregation of ECP or ECP2 points***

Hashing works for any data type, so you can hash simple objects (strings, numbers etc.) as well as hashes and dictionaries.

Keep in mind that in order to use more advanced cryptography like encryption, zero knowledge proof, zk-SNARKS, attributed based credential or the [Coconut](https://arxiv.org/pdf/1802.07344.pdf)  flow you will need to select a *scenario* in the beginning of the scripts. We'll write more about scenarios later, for now we're using the "ecdh" scenario as we're loading an ecdh key from the JSON. See our example below:




[](../_media/examples/zencode_cookbook/cookbook_when/whenCompleteScriptPart3.zen ':include :type=code gherkin')



The output should look like this: <a href="../_media/examples/zencode_cookbook/cookbook_When/whenCompleteOutputPart3.json" download>whenCompleteOutputPart3.json</a>.




## Comparing strings, numbers, arrays 

This group includes all the statements to compare objects, you can:


 ***Compare*** if objects (strings, numbers or arrays) are equal
 
 See if a ***number is more, less or equal*** to another 
 
 See ***if an array contains an element*** of a given value.


See our script below:


[](../_media/examples/zencode_cookbook/cookbook_when/whenCompleteScriptPart4.zen ':include :type=code gherkin')



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


[](../_media/examples/zencode_cookbook/cookbook_when/whenCompleteScriptPart5.zen ':include :type=code gherkin')



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

[](../_media/examples/zencode_cookbook/cookbook_dictionaries/dictionariesBlockchain.json ':include :type=code json')

Moreover we will also upload an ecdh public key:

[](../_media/examples/zencode_cookbook/cookbook_dictionaries/dictionariesIssuer_keyring.json ':include :type=code json')

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

[](../_media/examples/zencode_cookbook/cookbook_dictionaries/dictionariesComputation.zen ':include :type=code gherkin')


The output should look like this: 

[](../_media/examples/zencode_cookbook/cookbook_dictionaries/dictionariesComputationOutput.json ':include :type=code json')




# The script used to create the material in this page

All the smart contracts and the data you see in this page are generated by the scripts [cookbook_when.bats](https://github.com/dyne/Zenroom/blob/master/test/zencode/cookbook_when.bats) and [cookbook_dictionaries.bats](https://github.com/dyne/Zenroom/blob/master/test/zencode/cookbook_dictionaries.bats). If you want to run the scripts (on Linux) you should: 
 - *git clone https://github.com/dyne/Zenroom.git*
 - install **zsh** and **jq**
 - download a [zenroom binary](https://zenroom.org/#downloads) and place it */bin* or */usr/bin* or in *./Zenroom/src*









<!-- Temp removed, 


-->
### 
