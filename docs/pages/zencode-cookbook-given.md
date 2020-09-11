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

***Schemas*** are mostly used in cryptography, when complex cryptographic objects are used. The internal structures of the ***schemas*** will typically not be intuitive to non crypto-developers and can therefore be transparent to the user. A simple example of ***schema*** is the **<a href="./_media/examples/zencode_cookbook/alice_keypair.json" download>keypair</a>** (from the *ecdh* scenario), a more complex example is the ***credential*** (from the *credential* scenario). We'll look at schemas in detail when looking at each individual scenario.


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

[](../_media/examples/zencode_cookbook/myFlatObject.json ':include :type=code json')




### *Given I have* to load a flat JSON 

The most important thing to know about loading data in Zencode, is that ***each object must be loaded individually***, and one statement is needed to load each object. In this JSON we have one ***string***, one ***number*** and one ***array***, so we'd need three to load our whole JSON file, but we'll leave alone the array for now, so two statements will be enough.

Following is a script that loads (and validates) all the data in myNestedObject.json and (extra bonus!) it randomizes the array and prints the output:

[](../_media/examples/zencode_cookbook/givenLoadFlatObject.zen ':include :type=code gherkin')

Let's now the script, loading the data, using the command line:

```bash
zenroom -a myFlatObject.json -z givenLoadFlatObject.zen | tee givenLoadFlatObjectOutput.json
``` 

The output should look like this:

[](../_media/examples/zencode_cookbook/givenLoadFlatObjectOutput.json ':include :type=code json')

Remember that the output gets sorted alphabetically, because in Zenroom *determinism is King*, no matter in what order you loaded them.


Once again, alla data needs to be explicitly loaded, else Zenroom will ignore them. Using the same JSON file, try now this script:

[](../_media/examples/zencode_cookbook/givenLoadNumber.zen ':include :type=code gherkin')

Which should return this output:

[](../_media/examples/zencode_cookbook/givenLoadNumberOutput.json ':include :type=code json')
 
 
  
<!-- Temp removed, -->



## *Given I am*

By using the ***Given I am*** statement, you are declaring the identity of the one who is executing the current script. This means that, when loading nested JSON files (as in the next example), the name of one of the nested JSON objects has to match the name following the ***Given I am*** statement.

This statement is typically used when: 
- Executing cryptographic operations that will need a key or keypair: the keys are passed to Zenroom (via *-a* and *-k* parameters) as JSON or CBOR files, using a format that includes the owner of the keys. In the next example we'll indeed a *keypair*.
- In scripts where the identity is a condition for the execution of the script.


## *Given I have* to load nested JSON file (part 2)

So let's go one step further and create a JSON file that containing two nested objects, we'll call it named *myNestedObject.json*:

[](../_media/examples/zencode_cookbook/myNestedObject.json ':include :type=code json')
 
The JSON objects contain each a ***string***, a ***number*** and an ***array*** (we'll leave the arrays alone for now) and one also contains a cryptographic ***keypair***. 
We'll load a ***string***, a ***number*** and an ***keypair*** from the first object and  a ***string***, a ***number*** from the second one. 

Things you should focus on:
- In order to load the crypto keypair you'll need to use a *scenario*, in this case we'll use the *scenario 'simple'*, don't worry about this for now. 
- We're using the ***Given I am*** and the ***my*** operator to load data from the first JSON object, whose name matches the one declared in the ***Given I am*** statement.
- We're loading the second ***string*** and ***number*** from a second JSON object, whose name we need to state.

Time to look at the script and run it: 
 
[](../_media/examples/zencode_cookbook/givenLoadNestedObject.zen ':include :type=code gherkin')
 
The output should look like this: 

[](../_media/examples/zencode_cookbook/givenLoadNestedObjectOutput.json ':include :type=code json')

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

If you want to experiment with loading different types of ***array*** you can experiment by loading the JSON file <a href="./_media/examples/zencode_cookbook/givenArraysLoadInput.json" download>givenArraysLoadInput.json</a> using the script <a href="../_media/examples/zencode_cookbook/givenArraysLoad.zen" download>givenArraysLoad.zen</a> with the line: 

```bash
zenroom -a givenArraysLoadInput.json -z givenArraysLoad.zen | tee myArraysOutput.json
``` 

The output should looke like this: <a href="../_media/examples/zencode_cookbook/givenArraysLoadOutput.json" download>givenArraysLoadOutput.json</a>.

## Variations on *Given I have* using a nested JSON file (part 3)

Let's now load some real arrays, from a more complex JSON like this one: 

[](../_media/examples/zencode_cookbook/myTripleNestedObject.json ':include :type=code json')

Let's try with this script: 

[](../_media/examples/zencode_cookbook/givenLoadTripleNestedObject.zen ':include :type=code gherkin')
 

The output should look like this: 

[](../_media/examples/zencode_cookbook/givenTripleNestedObjectOutput.json ':include :type=code json')

 
## Corner case: homonymy

Now let's look at corner cases: what would happen if I load two differently named objects, that contain objects with the same name? Something like this: 

[](../_media/examples/zencode_cookbook/myNestedRepetitveObject.json ':include :type=code json')

We could try using the following script:


[](../_media/examples/zencode_cookbook/givenLoadRepetitveObject.zen ':include :type=code gherkin')

After uncommenting the statemen that loads the object *'myStringArray'* for the second time, Zenroom would halt the execution and return an error.

<!-- Unused files

You would get this result, which is probably something you want to avoid:

[](../_media/examples/zencode_cookbook/givenLoadRepetitveObjectOutput.json ':include :type=code json')

This last is the perfect example to introduce the *debug* operator.
--> 
 
## The *debug* operator: a window into Zenroom's virtual machine

Looking back at the previous paragraph, you may be wondering what happens exactly inside Zenroom's virtual machine and - more important - how to peep into it. The *Debug* operator addresses this precise issue: it is a wildcard, meaning that it can be used in any phase of the process. You may for example place it at the end of the *Given* phase, in order to see what data has the virtual machine actually imported (using the same dataset): 


[](../_media/examples/zencode_cookbook/myFlatObject.json ':include :type=code json')

And the script:

[](../_media/examples/zencode_cookbook/givenLoadArrayDebug.zen ':include :type=code gherkin')



Or if you're a fan of verbosity, you can try with this script: 

[](../_media/examples/zencode_cookbook/givenLoadArrayDebugVerbose.zen ':include :type=code gherkin')

We won't show the output of the script here as it would fill a couple pages... so many wasted electrons! Looking at this script can otherwise be a good exercise for you to figure out how Zenroom behaves each time a different piece of data is loaded.


## Enjoy the silence: *Given nothing*
 
 This statement sets a pre-condition to the execution of the script: *Given nothing* will halt the execution if data is passed to Zenroom via *--data* and *--keys* parameters, you want to use it when you want to be sure that no data is being passed to Zenroom. You may want to use it when you generate random objects or keypairs. 



 
# Comprehensive list of *Given* statements

Let's use an even larger object this time, named *myLargeNestedObject.json*: 

[](../_media/examples/zencode_cookbook/myLargeNestedObject.json ':include :type=code json')

Below is a list of most of the *Given* statements you will need in most situations:

[](../_media/examples/zencode_cookbook/givenFullList.zen ':include :type=code gherkin')


# The script used to create the material in this page

All the smart contracts and the data you see in this page are generated by the script [run-given.sh](https://github.com/dyne/Zenroom/blob/master/test/zencode_cookbook/run-given.sh). If you want to run the script (on Linux) you should: 
 - *git clone https://github.com/dyne/Zenroom.git*
 - install **zsh** and **jq**
 - download a [zenroom binary](https://zenroom.org/#downloads) and place it */bin* or */usr/bin* or in *./Zenroom/src*

### 
