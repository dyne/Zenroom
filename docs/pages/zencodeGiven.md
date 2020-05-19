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

Let's start with a create a file named *myObject.json* containing an int, a string and an array of string:

[](../_media/examples/zencode_cookbook/myObject.json ':include :type=code json')




## *Given I have* (part 1)

Following is a scrip that loads and validates all the data in myObject.json and (extra bonus!) it randomizes the array and prints the output:

[](../_media/examples/zencode_cookbook/givenLoadArray1.zen ':include :type=code gherkin')

Let's now the script, loading the data, using the command line:

```bash
zenroom -a myObject.json -z givenLoadArray1.zen | tee myArray.json
``` 


Looking at the previous example, be aware that using the same dataset:
 

[](../_media/examples/zencode_cookbook/myObject.json ':include :type=code json')

 

Also this script would have worked.

[](../_media/examples/zencode_cookbook/givenLoadArray2.zen ':include :type=code gherkin')


 
 
 
## The *Debug* operator: a window into Zenroom's virtual machine

Looking back at the previous paragraph, you may be wondering what happens exactly inside Zenroom's virtual machine and - more important - how to peep into it. The *Debug* operator addresses this precise issue: it is a wildcard, meaning that it can be used in any phase of the process. You may for example place it at the end of the *Given* phase, in order to see what data has the virtual machine actually imported (using the same dataset): 


[](../_media/examples/zencode_cookbook/myObject.json ':include :type=code json')

And the script:

[](../_media/examples/zencode_cookbook/givenLoadArrayDebug.zen ':include :type=code gherkin')



Or if you're a fan of verbosity, you can try with this: 


[](../_media/examples/zencode_cookbook/myObject.json ':include :type=code json')

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