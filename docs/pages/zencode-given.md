# *Given*: reading and verifying input

The *Given* keyword marks the first phase of Zencode execution, where input is read and processed and some variables are set. More precisely: 
 - Read data from files, passed using the *-a* and *-k* parameters, formatted in JSON or CBOR
 - State the identity of the script executor
 - Validate the input, both synctatically and cryptographically. 


<!-- Temp removed, waiting to see the destiny of given all data
 
## *Given nothing* and *Given all data*
 
 Those two statements are mutually exclusive and can set a pre-condition to the execution of the script where: 
 - *Given nothing* will halt the execution if data is passed to Zenroom (via *-a* and *-k* parameters) 
 - *Given all data* will 
 
-->
 
## *Given nothing*
 
 This statement (which we've used already, so no example here) sets a pre-condition to the execution of the script where: *Given nothing* will halt the execution if data is passed to Zenroom via *-a* and *-k* parameters, you want to use it when you want to be sure that no parameters are being passed from outside.

 
# Data import and validation in Zencode (part 1)
 
Things are getting serious now: the *Given I have* is in fact a family of statements that do some processing. This changes based on the operator used along: *a*, *my*, *valid*. Let's try with some example:

Let's start with a create a file named *myFlatObject.json* containing several an int, a string and an array of string:

[](../_media/examples/zencode_cookbook/myFlatObject.json ':include :type=code json')



## *Given I have* using a "flat" JSON (part 1)

Following is a scrip that loads and validates all the data in myNestedObject.json and (extra bonus!) it randomizes the array and prints the output:

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
 
 
<!-- Temp removed, waiting to see the destiny of given all data
 
 

Also this script would have worked.

[](../_media/examples/zencode_cookbook/givenLoadArray2.zen ':include :type=code gherkin')
-->


## *Given I have* using a nested JSON file (part 2)

Let's get things more complicated and create a JSON file  containing several nested objects, we'll call it named *myNestedObject.json*:

[](../_media/examples/zencode_cookbook/myNestedObject.json ':include :type=code json')
 
In this JSON we placed three different objects, two contain a similar collection of objects inside and one is a cryptographic keypair, which is perfectly ok. We'll load the two arrays and the keypair: note that in order to load the crypto keypair you'll need to use a *scenario*, in this case we'll use the *scenario 'simple'*, don't worry about this for now, let's try focus on the loading part and run this script: 
 
[](../_media/examples/zencode_cookbook/givenLoadNestedObject.zen ':include :type=code gherkin')
 
The output should look like this: 

[](../_media/examples/zencode_cookbook/givenLoadNestedObjectOutput.json ':include :type=code json')


Now let's look at corner cases: what would happen if I load two differently named objects, that contain objects with the same name? Something like this: 

[](../_media/examples/zencode_cookbook/myNestedRepetitveObject.json ':include :type=code json')

Using a very similar script:


[](../_media/examples/zencode_cookbook/givenLoadRepetitveObject.zen ':include :type=code gherkin')

You would get this result, which is probably something you want to avoid:

[](../_media/examples/zencode_cookbook/givenLoadRepetitveObjectOutput.json ':include :type=code json')

This last is the perfect example to introduce the *debug* operator.
 
 
## The *debug* operator: a window into Zenroom's virtual machine

Looking back at the previous paragraph, you may be wondering what happens exactly inside Zenroom's virtual machine and - more important - how to peep into it. The *Debug* operator addresses this precise issue: it is a wildcard, meaning that it can be used in any phase of the process. You may for example place it at the end of the *Given* phase, in order to see what data has the virtual machine actually imported (using the same dataset): 


[](../_media/examples/zencode_cookbook/myNestedObject.json ':include :type=code json')

And the script:

[](../_media/examples/zencode_cookbook/givenLoadArrayDebug.zen ':include :type=code gherkin')



Or if you're a fan of verbosity, you can try with this: 


[](../_media/examples/zencode_cookbook/myNestedObject.json ':include :type=code json')

[](../_media/examples/zencode_cookbook/givenLoadArrayDebugVerbose.zen ':include :type=code gherkin')

 
 
##  *Given I am*

Here you are declaring the identity of the one who is executing the current script, this can be used: 
 - When executing cryptographic operations that will need a key or keypair: the keys are passed to Zenroom (via *-a* and *-k* parameters) as JSON or CBOR files, with a format that includes the owner of the keys.
 - In scripts using the *my* keyword, the identity a condition for the execution
 



<!-- Temp 

 

 
### Importing and validating an array 


 
 Given I have a 'keypair'
 When I rename the 'object' to 'renObject'
 Then print all data 
 
 
 
 given: I have a valid array of 'number' in 'lista_di_numeri'
 
 
 
 
 
array
array_ecp
array_string
array_number

 
 
  - given: I have a ''
  - given: I have my ''
  - given: I have my valid ''
  - given: I have a valid ''
  
  
 
 
 Given I have an 'array'
 When I rename the 'array' to 'renArray'
 Then print all data 
 
 


On Linux, you can use: 

```bash
zenroom -z arrayGenerator.zen | tee myArray.json
```

-->