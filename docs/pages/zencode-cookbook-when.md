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
 
## First, let's load a JSON file
 
We've done this already: let's start with create a file named *myLargeNestedObjectWhen.json*. This file contains everything we need for every part of this chapter and - along  with the *Given* part of the script, you can use this JSON to later make your own experiments with Zencode.

[](../_media/examples/zencode_cookbook/myLargeNestedObjectWhen.json ':include :type=code json')

 

## Loading the content of the JSON 

Since the *When* phase contains many statements, we did split the scripts in four parts. The part of script that loads the JSON can be used for all the scripts below.


[](../_media/examples/zencode_cookbook/whenCompleteScriptGiven.zen ':include :type=code gherkin')



## Manipulation: sum/subtract, rename, remove, append... 

We grouped together all the statements that perform object manipulation, so: 

 - ***sum and subtract*** two numbers
 - ***append*** a simple object to another
 - ***rename*** an object
 - ***insert*** a simple object into an array
 - ***remove*** an element from an array
 - ***split*** a string
 - ***randomize*** the elements of an array
 - ***Create string/number*** (statement "write in")
 - ***pick a random element*** from an array
 - ***flatten*** an array into a string
 
In the script below, we've put together a list of this statement and explained in the comments how each statement works: 
 

[](../_media/examples/zencode_cookbook/whenCompleteScriptPart1.zen ':include :type=code gherkin')


To play with the script, first save it into the file *whenCompleteScriptPart1.zen*. Then run it while loading the data, using the command line:

```bash
zenroom -a myLargeNestedObjectWhen.json -z whenCompleteScriptPart1.zen | jq | tee whenCompleteOutputPart1.json
``` 

The output should look like <a href="../_media/examples/zencode_cookbook/whenCompleteOutputPart1.json" download>whenCompleteOutputPart1.json</a>. Remember that the output gets sorted alphabetically, because in Zenroom *determinism is King*.

## Create regular or random objects 

In the second group we gathered the *When* statements that can create new objects and assign values to them.
 - The "create" statements can generate random numbers (or arrays thereof), with different parameters.
 - The "set" statements allow you to create an object and assign a value to it. 
 
 See our example script below: 
 

[](../_media/examples/zencode_cookbook/whenCompleteScriptPart2.zen ':include :type=code gherkin')



The output should look like <a href="../_media/examples/zencode_cookbook/whenCompleteOutputPart2.json" download>whenCompleteOutputPart2.json</a>.


## Basic cryptography: hashing

Here we have grouped together the statements that perform: 
 - Basic hashing
 - Hashing a number to a point on a curve
 - Key derivation function (KDF)
 - Password-Based Key Derivation Function (pbKDF)
 - hash-based message authentication code (HMAC)
 - Aggregation of ECP or ECP2 points

Keep in mind that in order to use more advanced cryptography like encryption, zero knowledge proof, zk-SNARKS, attributed based credential or the [Coconut](https://arxiv.org/pdf/1802.07344.pdf)  flow you will need to select a *scenario* in the beginning of the scripts. We'll write more about scenarios later, for now we're using the "ecdh" scenario as we're loading an asymetric keypair from the JSON. See our example below:




[](../_media/examples/zencode_cookbook/whenCompleteScriptPart3.zen ':include :type=code gherkin')



The output should look like this: <a href="../_media/examples/zencode_cookbook/whenCompleteOutputPart3.json" download>whenCompleteOutputPart3.json</a>.




## Comparing strings, numbers, arrays 

This group includes all the statements to compare objects, you can:

 - Compare if objects (strings, numbers or arrays) are equal.
 - See if a number is more, less or equal to another. 
 - See if an array contains an element of a given value.

See our script below:


[](../_media/examples/zencode_cookbook/whenCompleteScriptPart4.zen ':include :type=code gherkin')



The output should look like 
<a href="../_media/examples/zencode_cookbook/whenCompleteOutputPart4.json" download>whenCompleteOutputPart4.json</a>. 


## Operations with dictionaries

The last group includes all the statements that are exclusive to ***dictionary*** objects 

 - Compare if objects (strings, numbers or arrays) are equal.
 - See if a number is more, less or equal to another. 
 - See if an array contains an element of a given value.

See our script below:


[](../_media/examples/zencode_cookbook/whenCompleteScriptPart4.zen ':include :type=code gherkin')



The output should look like 
<a href="../_media/examples/zencode_cookbook/whenCompleteOutputPart4.json" download>whenCompleteOutputPart4.json</a>. 


<!--  
[](../_media/examples/zencode_cookbook/whenCompleteOutputPart4.json ':include :type=code json')  

-->









<!-- Temp removed, 


-->
### 
