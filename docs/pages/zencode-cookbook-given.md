<!-- Unused files
 
givenDebugOutputVerbose.json
givenLongOutput.json
 
-->




# *Given*: reading and verifying input

The *Given* keyword marks the first phase of Zencode execution, where input is read and processed and some variables are set. More precisely: 
 - Read data from files, passed using the *--data* and *--keys* parameters, formatted in JSON or CBOR (where JSON is the default and CBOR needs to be specified)
 - State the identity of the script executor
 - Validate the input, both synctatically and cryptographically. 

# *Encoding* and *Schemas* 

Zenroom supports different ***encodings***, and can handle different types of data, referred internally as ***schemas*** which can be simple (like numbers or strings) or complex (like arrays or ''keypair'', a schema present in several ***scenarios*** - we'll read about this later). 

The encodings can be used to tell Zenroom what data to expect as input as well as to convert the output data in the ***Then*** phase (also something we'll talk later about. The ***encodings*** and ***schemas*** supported (without defining a ***scenario*** are the following:
 - ***Encodings***: url64, base64, hex, binary
 - ***Schemas***: array, number, string, string array 

The usage of the ***encodings*** is pretty intuitive, you'll see several example in this chapter. 
The schema ***number*** can be both an integer or a float, in the second case a comma is used as separator as separator.
The ***array*** is also ***quite*** intuitive but not completely: a regular ***array*** will work as expected only if it contains object encoded as ***hex***, ***binary***, ***base64*** or ***url64*** or contain ***number*** objects. 
So where are the strings and arrays that contain strings? We have a little extra chapter for that.



## The ***Schemas*** ***string***  and ***string array***

For security reasons (just search for [LangSec strings](https://langsec.org/bof-handout.pdf)), strings need a special  management differently. 
While for every other schema, once you have declared it in the input phase, you don't need to worry about it anymore, when using ***string*** and ***string arrays*** Zenroom will load them as base 64 and output them as hex by default. 

In order to output a ***string*** and ***string array*** in the same way as they were loaded, you'll need to to tell Zenroom to format them accordingly while processing the output, in the ***Then*** phase.


 

<!-- Temp removed, waiting to see the destiny of given all data
 
## *Given nothing* and *Given all data*
 
 Those two statements are mutually exclusive and can set a pre-condition to the execution of the script where: 
 - *Given nothing* will halt the execution if data is passed to Zenroom (via *-a* and *-k* parameters) 
 - *Given all data* will 
 
-->
 
## *Given nothing*
 
 This statement (which we've used already, so no example here) sets a pre-condition to the execution of the script where: *Given nothing* will halt the execution if data is passed to Zenroom via *--data* and *--keys* parameters, you want to use it when you want to be sure that no parameters are being passed from outside.

 
# Data import and validation in Zencode (part 1)
 
Things are getting serious now: the *Given I have* is in fact a family of statements that do some processing. This changes based on the operator used along: *a*, *my*, *valid*. Let's try with some example:

Let's start with a create a file named *myFlatObject.json* containing several an int, a string and an array of string:

[](../_media/examples/zencode_cookbook/myFlatObject.json ':include :type=code json')



## *Given I have* using a "flat" JSON (part 1)

Following is a script that loads and validates all the data in myNestedObject.json and (extra bonus!) it randomizes the array and prints the output:

[](../_media/examples/zencode_cookbook/givenLoadFlatObject.zen ':include :type=code gherkin')

Let's now the script, loading the data, using the command line:

```bash
zenroom -a myFlatObject.json -z givenLoadFlatObject.zen | tee givenLoadFlatObjectOutput.json
``` 

The output should look like this:

[](../_media/examples/zencode_cookbook/givenLoadFlatObjectOutput.json ':include :type=code json')

Remember that the output gets sorted alphabetically, because in Zenroom *determinism is King*.


Also consider that different data parts in the JSON object, need to be explicitly loaded, else Zenroom will ignore them. Try for example this script:

[](../_media/examples/zencode_cookbook/givenLoadNumber.zen ':include :type=code gherkin')

Which should return this output:

[](../_media/examples/zencode_cookbook/givenLoadNumberOutput.json ':include :type=code json')
 
If you're wondering if you can check what gets loaded and what not, during execution, this will be answered in a little when we'll tell about the *debug* operator.
 
 
<!-- Temp removed, -->


## *Given I have* using a nested JSON file (part 2)

Let's get things more complicated and create a JSON file  containing several nested objects, we'll call it named *myNestedObject.json*:

[](../_media/examples/zencode_cookbook/myNestedObject.json ':include :type=code json')
 
In this JSON we placed three different objects, two contain a similar collection of objects inside and one is a cryptographic keypair, which is perfectly ok. We'll load the two arrays and the keypair: note that in order to load the crypto keypair you'll need to use a *scenario*, in this case we'll use the *scenario 'ecdh'*, don't worry about this for now, let's try focus on the loading part and run this script: 
 
[](../_media/examples/zencode_cookbook/givenLoadNestedObject.zen ':include :type=code gherkin')
 
The output should look like this: 

[](../_media/examples/zencode_cookbook/givenLoadNestedObjectOutput.json ':include :type=code json')


## Variotions on *Given I have* using a nested JSON file (part 3)

Zencode offers some flexibility in how you can read objects and values, here are some examples. Let's see you want to read this JSON: 

[](../_media/examples/zencode_cookbook/myTripleNestedObject.json ':include :type=code json')

You could this script: 

[](../_media/examples/zencode_cookbook/givenLoadTripleNestedObject.zen ':include :type=code gherkin')
 

The output should look like this: 

[](../_media/examples/zencode_cookbook/givenTripleNestedObjectOutput.json ':include :type=code json')

 
## Corner case: omonimity

Now let's look at corner cases: what would happen if I load two differently named objects, that contain objects with the same name? Something like this: 

[](../_media/examples/zencode_cookbook/myNestedRepetitveObject.json ':include :type=code json')

Using a very similar script:


[](../_media/examples/zencode_cookbook/givenLoadRepetitveObject.zen ':include :type=code gherkin')

You would get this result, which is probably something you want to avoid:

[](../_media/examples/zencode_cookbook/givenLoadRepetitveObjectOutput.json ':include :type=code json')

This last is the perfect example to introduce the *debug* operator.
 
 
## The *debug* operator: a window into Zenroom's virtual machine

Looking back at the previous paragraph, you may be wondering what happens exactly inside Zenroom's virtual machine and - more important - how to peep into it. The *Debug* operator addresses this precise issue: it is a wildcard, meaning that it can be used in any phase of the process. You may for example place it at the end of the *Given* phase, in order to see what data has the virtual machine actually imported (using the same dataset): 


[](../_media/examples/zencode_cookbook/myFlatObject.json ':include :type=code json')

And the script:

[](../_media/examples/zencode_cookbook/givenLoadArrayDebug.zen ':include :type=code gherkin')



Or if you're a fan of verbosity, you can try with this script: 

[](../_media/examples/zencode_cookbook/givenLoadArrayDebugVerbose.zen ':include :type=code gherkin')

We won't show the output of the script here as it would fill a couple pages... so many wasted electrons! Looking at this script can otherwise be a good exercise for you to figure out how Zenroom behaves each time a different piece of data is loaded.

 
##  *Given I am*

Here you are declaring the identity of the one who is executing the current script, this can be used: 
 - When executing cryptographic operations that will need a key or keypair: the keys are passed to Zenroom (via *-a* and *-k* parameters) as JSON or CBOR files, with a format that includes the owner of the keys.
 - In scripts using the *my* keyword, the identity a condition for the execution
 
# THE END: Comprehensive list of *Given* statements

Let's use an even larger object this time, named *myLargeNestedObject.json*: 

[](../_media/examples/zencode_cookbook/myLargeNestedObject.json ':include :type=code json')

Below is a list of most of the *Given* statements you will need in most situations:

[](../_media/examples/zencode_cookbook/givenFullList.zen ':include :type=code gherkin')

### 
