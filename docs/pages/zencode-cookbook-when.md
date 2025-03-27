<!-- Unused files
TODO:
* explain better inputs (sometimes they are the value in the statement, sometime they must points to a variable or both)
* use more links to other sections
* develop all the examples in the cookbook_when tests
* maybe a section on `set` after the `create`?
* 
-->




# The *When* statements: all operations with data

The *When* keyword introduces the phase of Zencode execution, where data can be manipulated. The statemens executed in this phase allow you to:
- Manipulate objects: rename, append, cut, insert, remove, etc.
- Create objects: different schemas can be created in different ways (including random objects), and values assigned to them.
- Execute cryptography: this is where all the crypto-magic happens: creating keyring, hashing points...
- Comparisons: compare value of numbers, strings and complex objects.

<!---TODO: link loop page as soon as it present-->
Moreover you can enanche this phase power thourgh the use of [conditional branching](zencode-if-endif.md) and loops.

## The create keyword

Before diving into the world of *When* statements, we need to understand a key mechanism in zencode:
the `create` keyword.

When used in a sentence, the `create` keyword indicates that a new element will be added to the zencode memory.
The name of this element is specified immediately after `create` (ignoring any `the` that follows).
However, note that Zenroom does not allow overwriting elements already present in its memory. Therfore,
ensure that the element you are creating does not already exist! Later, we will learn how to handle
such conflicts using the [rename and remove statements](#rename-and-remove-statements).

A quick example is to create an array or a dictionary:

[](../_media/examples/zencode_cookbook/cookbook_when/when_create_new_array.zen ':include :type=code gherkin')

the above statements will always create a new array called `string_array`, thus if you try to create another
one you will get an error, to overcome this problem, other than using the `rename` or `remove` statement, you can
also give a specific name to the new array or dictionary using:

[](../_media/examples/zencode_cookbook/cookbook_when/when_create_new_array_with_name.zen ':include :type=code gherkin')

We will see a lot of `create` statements in the cookbook examples, but there is still a particular case
in which the behavior of the `create` keyword changes a bit: creating a cryptographic secret key.
For security reasons, all secret keys created in zencode are stored within an object called `keyring`.
For instance, creating an [ECDH key](zencode-scenarios-ecdh?id=key-generation) looks like this:

[](../_media/examples/zencode_cookbook/cookbook_when/when_create_new_key.zen ':include :type=code gherkin')

that outputs something like:

[](../_media/examples/zencode_cookbook/cookbook_when/when_create_new_key.out.json ':include :type=code json')

As shown above, the `keyring` contains an element named `ecdh`, which holds the newly created `ecdh key`.

## Check if elements exists in memory or inside another object

Now that we have learnt how to create elements in memory, we can also check if they exist.

### Found in memory

To search if an element exists or not in the memory you can use:

[](../_media/examples/zencode_cookbook/cookbook_when/when_found_examples.zen ':include :type=code gherkin')

Copy paste the above example in [Apiroom](https://apiroom.net) and see the result, now try to change `dictionary`,
in the verify statement, to something that doesn't exist in the memory and see what happens.

### Found in another object

You can also check if an element exists in another object. Where the object is specified after the `in` keyword
and it can be an array or a dictionary (a lua table). The search in a dictionary is done by key, while the search
in an array is done by value.

For example suppose to have the following objects:

[](../_media/examples/zencode_cookbook/cookbook_when/when_found_in_examples.data.json ':include :type=code json')

we can do some checks like:

[](../_media/examples/zencode_cookbook/cookbook_when/when_found_in_examples.zen ':include :type=code gherkin')

## Managing Memory with Renaming and Removing Statements

Zenroom provides rename and remove (or delete) statements to manage elements in memory. These statements
are particularly useful for resolving conflicts or cleaning up data during a script's execution.

### Rename

The rename statement allows you to change the name of an object or element in memory. This is especially
helpful when working with temporary objects or when avoiding naming conflicts. Additionally, it supports
dynamic renaming by referencing names stored in variables or derived from other elements. This feature
is particularly useful when names are not known at design time or need to be generated programmatically.
For example

[](../_media/examples/zencode_cookbook/cookbook_when/when_rename_examples.zen ':include :type=code gherkin')

with data

[](../_media/examples/zencode_cookbook/cookbook_when/when_rename_examples.data.json ':include :type=code json')

will results in

[](../_media/examples/zencode_cookbook/cookbook_when/when_rename_examples.out.json ':include :type=code json')

where you can see that the `to_be_renamed_*` variable have been renamed.

### Remove

The remove or delete statement allows you to delete elements from memory, freeing up space and avoiding
conflicts. These two keywords can be used interchangeably.

[](../_media/examples/zencode_cookbook/cookbook_when/when_remove_examples.zen ':include :type=code gherkin')

they become particularly useful when working with [loops](zencode-foreach-endforeach).
If you want you can also remove an element from an object in the memory with

[](../_media/examples/zencode_cookbook/cookbook_when/when_remove_from_examples.zen ':include :type=code gherkin')

where the data in input look like

[](../_media/examples/zencode_cookbook/cookbook_when/when_remove_from_examples.data.json ':include :type=code json')

## Managing Data with Copying and Moving Statements

### Copy

The copy statement allows you to copy an object into a new object. Consider the data input:

[](../_media/examples/zencode_cookbook/cookbook_when/when_copy_to_object.data.json ':include :type=code json')

copy some objects into other objects

[](../_media/examples/zencode_cookbook/cookbook_when/when_copy_to_object.zen ':include :type=code gherkin')

the output will be

[](../_media/examples/zencode_cookbook/cookbook_when/when_copy_to_object.out.json ':include :type=code json')

It's also possible to copy from an object. Consider the data input:

[](../_media/examples/zencode_cookbook/cookbook_when/when_copy_from_object.data.json ':include :type=code json')

copy from an object

[](../_media/examples/zencode_cookbook/cookbook_when/when_copy_from_object.zen ':include :type=code gherkin')

the output will be

[](../_media/examples/zencode_cookbook/cookbook_when/when_copy_from_object.out.json ':include :type=code json')


It's also possible to encode an object before copying it. Consider the data input:

[](../_media/examples/zencode_cookbook/cookbook_when/when_copy_enc.data.json ':include :type=code json')

and the code 

[](../_media/examples/zencode_cookbook/cookbook_when/when_copy_enc.zen ':include :type=code zen')

then, in the output, `string_1` will be added to `dictionary_1` in hexadecimal form and will be copied to `string_copied` in binary format.

Other possible operations include: copying the entire content of an object into another object, copying a specific element of an object into another object, or copying the last element of an object into a new element called `copy_of_last_element`. For example consider the input:

[](../_media/examples/zencode_cookbook/cookbook_when/when_copy_object.data.json ':include :type=code json')

and the code 

[](../_media/examples/zencode_cookbook/cookbook_when/when_copy_object.zen ':include :type=code zen')

then, in the output, `dictionary_1` and `dictionary_2` will have the same elements. Additionally, outside of the two dictionaries, `copy_of_last_element` will also appear.


```gherkin

# deprecate? much simpler and powerful `When I copy '' from '' in ''`
When I create copy of '' from ''
When I create copy of '' from dictionary ''

# can be deprecated by creating `When I copy named by '' from '' to ''`
When I create copy of object named by '' from dictionary ''

# can be deprecated by making `When I copy '' from '' to ''` to support numbers as position and array (not much work)
When I create copy of element '' from array ''
```

### Move

The Move statement allows to move an Object into another Object or outside from and to rename it.
For example, if we take the data input

[](../_media/examples/zencode_cookbook/cookbook_when/when_move_to.data.json ':include :type=code json')

the Complex Object 'array' will be renamed

[](../_media/examples/zencode_cookbook/cookbook_when/when_move_to.zen ':include :type=code gherkin')

and the output will be the following.

[](../_media/examples/zencode_cookbook/cookbook_when/when_move_to.out.json ':include :type=code json')

It is possible to move an Object or a Complex Object into a specific Complex Object adding the command "in".
If we take in input the following data

[](../_media/examples/zencode_cookbook/cookbook_when/When_move_in_object.data.json ':include :type=code json')

the following code

[](../_media/examples/zencode_cookbook/cookbook_when/When_move_in_object.zen ':include :type=code gherkin')

allows to print the following output.

[](../_media/examples/zencode_cookbook/cookbook_when/When_move_in_object.out.json ':include :type=code json')

A variation of the previous code allows to choose the element to move from a Complex Object.

[](../_media/examples/zencode_cookbook/cookbook_when/when_move_from.zen ':include :type=code gherkin')

It is possible to move an Object changing its representation specifying the desired basis as follow

[](../_media/examples/zencode_cookbook/cookbook_when/when_move_as.data.json ':include :type=code json')

[](../_media/examples/zencode_cookbook/cookbook_when/when_move_as.zen ':include :type=code gherkin')

obtaining the following output

[](../_media/examples/zencode_cookbook/cookbook_when/when_move_as.out.json ':include :type=code json')

## Random statements

Randomness plays a crucial role in cryptography. While it's often hidden within cryptographic algorithms,
Zenroom provides direct access to random utilities, which can be used in various ways.

### Create a random object

To create a random object, you can use the following syntax:

```gherkin
Given nothing

# 32 bytes long random
When I create the random '32 byte long random'

# 1 byte (or 8 bits) long random
When I create the random object of '8' bits
When I rename the 'random object' to '1 byte long random'

# 2 bytes long random
When I create the random object of '2' bytes
When I rename the 'random object' to '2 bytes long random'

Then print the data
```

### Create an array of random objects or numbers

Why limit yourself to just one object? You can create arrays of random objects:

```gherkin
Given nothing

# array of 5 random objects, each 64 bytes long
When I create the array of '5' random objects
When I rename the 'array' to '5 64 bytes long randoms'

# array of 6 random objects, each 1 byte (8 bits) long
When I create the array of '6' random objects of '8' bits
When I rename the 'array' to '6 1 bytes long randoms'

# array of 7 random objects, each 2 bytes long
When I create the array of '6' random objects of '2' bytes
When I rename the 'array' to '7 2 bytes long randoms'

Then print the data
```

Need random numbers instead? Here's how:

```gherkin
Given nothing

# array of 5 random integers
When I create the array of '5' random numbers
When I rename the 'array' to '5 random numbers'

# array of 5 random integers with a maximum value of 165165
When I create the array of '5' random numbers modulo '165165'
When I rename the 'array' to '5 random numbers modulo 165165'

Then print the data
```

### Randomize an array

If you already have an array of elements and want to randomize it, you can do so easily.
For example, given the following data:

```json
{
  "ordered": [
    "first",
    "second",
    "third",
    "fourth",
    "fiveth"
  ]
}
```

You can randomize it using:

```gherkin
Given I have a 'string array' named 'ordered'

When I randomize the 'ordered' array

Then I print the 'ordered'
```

The result will look something like this (actual order may vary):

```json
{}
```

### Pick one or more random objects from a table

Zenroom also lets you pick random objects from a table:

```gherkin
When I pick random object in ''
When I create random dictionary with '' random objects from ''
```

## Numbers statements

This section will discuss numbers, specifically integers, floats, and time. Floating-point numbers are a fundamental data type in computing used to represent real numbers (numbers with fractional parts). They are designed to handle a wide range of magnitudes, from very small to very large values, by using a scientific notation-like format in binary.
All TIME objects are float number. Since all TIME objects are 32 bit signed, there are two limitations for values allowed:

-The MAXIMUM TIME value allowed is the number 2147483647 

-The MINIMUM TIME value allowed is the number -2147483647 

### Create a number

[](../_media/examples/zencode_cookbook/cookbook_when/when_numbers_create.zen ':include :type=code gherkin')

The ouput will be the number `12345` saved in `nameOfNewNumber` and its base64 version saved in `number`.
The numbers that can be encoded with the command shown above are integers from 0 to 1000000.

### Possible casting between number types

It is also possible to perform casting operations between number types. For example, let's consider providing the input `{"number": 1234}` and consider the code:

[](../_media/examples/zencode_cookbook/cookbook_when/when_numbers_cast.zen ':include :type=code gherkin')

then the output will be: `f`,`float` and `number` equal to `1234` and `integer` equal to `"1234"`.

### Mathematical operations

Zenroom provides support a range of basic mathematical operations, including addition, subtraction,
multiplication, division, modulo and sign inversion. These operations allow step-by-step numeric
manipulations, with results stored for reuse.

Consider the two input numbers

[](../_media/examples/zencode_cookbook/cookbook_when/when_numbers_operations.data.json ':include :type=code json')

and the code 

[](../_media/examples/zencode_cookbook/cookbook_when/when_numbers_operations.zen ':include :type=code gherkin')

the output will be

[](../_media/examples/zencode_cookbook/cookbook_when/when_numbers_operations.out.json ':include :type=code json')


For more advanced use cases, you can calculate an entire equation in a single statement.
This allows for concise and efficient computations without breaking them into smaller steps.

Consider the same numbers used in the previous example and the equation

[](../_media/examples/zencode_cookbook/cookbook_when/when_numbers_equations.zen ':include :type=code gherkin')

then the output will be `{"expr": 7647246}`.


### Comparison

For the next two example scripts where we will compare two numbers, we will use the same input file, which will be as follows:

[](../_media/examples/zencode_cookbook/cookbook_when/when_numbers_compare.data.json ':include :type=code json')

It is now possible to check if a number is greater than, greater than or equal to, less than, or less than or equal to another

[](../_media/examples/zencode_cookbook/cookbook_when/when_numbers_compare.zen ':include :type=code gherkin')

Furthermore, it is also possible to check if a number is equal to or different from another, even within a dictionary

[](../_media/examples/zencode_cookbook/cookbook_when/when_numbers_equal.zen ':include :type=code gherkin')

Both scripts will return the same output `{"output":["success"]}`.

All this statement can be used as `When` or `If`.

## String operations statements

### Create a new string

This method allows to create e new string and name it

[](../_media/examples/zencode_cookbook/cookbook_when/when_create_string.zen ':include :type=code gherkin')

and the outoput will be

[](../_media/examples/zencode_cookbook/cookbook_when/when_create_string.out.json ':include :type=code json')

### Append at the end

This methods allows to append a string at the end of another one.
Given the input

[](../_media/examples/zencode_cookbook/cookbook_when/when_append.data.json ':include :type=code json')

and the code

[](../_media/examples/zencode_cookbook/cookbook_when/when_append.zen ':include :type=code gherkin')

the output will be 

[](../_media/examples/zencode_cookbook/cookbook_when/when_append.out.json ':include :type=code json')

Another version of the previous code allows to append at the end of a string the codification of another string in a chosen basis

[](../_media/examples/zencode_cookbook/cookbook_when/when_append_mod.zen ':include :type=code gherkin')


### Split at a certain point

These command allow to split a string in a desired point. The number of bytes indicates the number of charachters will be removed from the left side or right side of the input string.
Given the following input

[](../_media/examples/zencode_cookbook/cookbook_when/when_split.data.json ':include :type=code json')

and the code

[](../_media/examples/zencode_cookbook/cookbook_when/when_split.zen ':include :type=code gherkin')

the output will be

[](../_media/examples/zencode_cookbook/cookbook_when/when_split.out.json ':include :type=code json')


The following version of the command "split" allows to create a string array splitting a given String all times an input Character is found.

Using the following data

[](../_media/examples/zencode_cookbook/cookbook_when/when_split_into_array.data.json ':include :type=code json')

and the code

[](../_media/examples/zencode_cookbook/cookbook_when/when_split_into_array.zen ':include :type=code gherkin')

the output will be

[](../_media/examples/zencode_cookbook/cookbook_when/when_split_into_array.out.json ':include :type=code json')

### Remove characters

```gherkin
When I remove spaces in ''
When I remove newlines in ''
When I remove all occurrences of character '' in ''
When I compact ascii strings in ''
```

### Count character occurrences

```gherkin
When I create count of char '' found in ''
```

## Table operations statements

### Works on both array and dictionary

#### pickup from path

```gherkin
When I pickup from path ''
When I pickup a '' from path ''
When I take '' from path ''
```

#### table size

```gherkin
When I create the size of ''
```

#### json encoding/decoding

```gherkin
When I verify '' is a json
When I create json escaped string of ''
When I create json unescaped object of ''
```

#### remove zero values

```gherkin
When I remove zero values in ''
```

### Only array statements

#### create
```gherkin
When I create new array
```

#### insert
```gherkin
When I insert string '' in ''
When I insert true in ''
When I insert false in ''
```

#### math ops
```gherkin
When I create sum value of elements in array ''
# equal to `When I create aggregation of array ''`
When I create average of elements in array ''
When I create variance of elements in array ''
When I create standard deviation of elements in array ''
```

#### create flat array
```gherkin
When I create flat array of contents in ''
When I create flat array of keys in ''
```

#### particular stuff
```gherkin
When I create array of objects named by '' found in ''
When I create '' from '' in ''
```

### Only dictionary statements

#### create
```gherkin
When I create new dictionary
When I create new dictionary named ''
```

#### math ops (?)
```gherkin
When I find max value '' for dictionaries in ''
When I find min value '' for dictionaries in ''
When I create sum value '' for dictionaries in ''
When I create sum value '' for dictionaries in '' where '' > ''
When I find '' for dictionaries in '' where '' = ''
```

#### filter fields
```gherkin
When I filter '' fields from ''
```

#### particular stuff
```gherkin
When I for each dictionary in '' append '' to ''
```
#### idk

maybe deprecable using nested foreach?
```gherkin
When I create array of elements named '' for dictionaries in ''
```

## Throw an error

```gherkin
When I exit with error message ''
```

## First crypto steps

### Hash

Hashing works for any data type, so you can hash simple objects (strings, numbers etc.) as well as hashes and dictionaries. The format is the following:

```gherkin
When I create the hash of 'source' using 'sha512'
```

It works with any source data named as first argument and one of the hashing algorithms supported. At the time of writing they are:
- the default SHA2 `sha256` (32 bytes long)
- and the SHA2 `sha512` (64 bytes long)
- the new SHA3 class `sha3_256` (32 bytes)
- the new SHA3 class `sha3_512` (64 bytes)
- the SHA3 class `shake256` (also 32 bytes)
- the SHA3 class `keccak256` used in Ethereum

<!-- should we document also?
When I create hash of ''                  -> better the explicit one
When I create hashes of each object in '' -> can be done using foreach and explicit one
-->

#### Multihash encoded hash
 
If needed it can be easy to encode hashed results in Zencode using [Multihash](https://multiformats.io/multihash/). Just use a similar statement:
```gherkin
When I create the multihash of 'source' using 'sha512'
```

This way the multihash content will be usable in its pure binary form while being in the `When` phase, but will be printed out in multihash format by the `Then` phase.

### hash to point

```gherkin
When I create hash to point '' of ''
```

### hmac

```gherkin
When I create hmac of '' with key ''
```

### kdf

```gherkin
When I create key derivation of ''
When I create key derivations of each object in '' # maybe deprecable using foreach?
```

### pbkdf

```gherkin
When I create key derivation of '' with password ''
When I create key derivation of '' with '' rounds
When I create key derivation of '' with '' rounds with password ''
```


<!---
## Manipulation: sum/subtract, rename, remove, append...

We grouped together all the statements that perform object manipulation, so:


 ***Math operations***: sum, subtraction, multiplication, division and modulo, between numbers

 ***Invert sign*** invert the sign of a number

 ***Append*** a simple object to another

 ***Rename*** an object

 ***Delete*** an object from the memory stack

 ***Copy*** an object into new object

 ***Split string*** using leftmost or rightmost bytes

 ***Create string/number*** (statement "write in")

 ***Create flat array*** of contents or keys of a dictionary or an array


In the script below, we've put together a list of this statement and explained in the comments how each statement works:


[](../_media/examples/zencode_cookbook/cookbook_when/whenCompleteScriptPart1.zen ':include :type=code gherkin')


To play with the script, first save it into the file *whenCompleteScriptPart1.zen*. Then run it while loading the data, using the command line:

```bash
zenroom -a myLargeNestedObjectWhen.json -z whenCompleteScriptPart1.zen | jq | tee whenCompleteOutputPart1.json
```

The output should look like <a href="../_media/examples/zencode_cookbook/cookbook_when/whenCompleteOutputPart1.json" download>whenCompleteOutputPart1.json</a>. Remember that the output gets sorted alphabetically, because in Zenroom *determinism is King*.


## Create regular or random objects and render them

In the second group we gathered the *When* statements that can create new objects and assign values to them.

 The "create" statements can ***generate random numbers*** (or arrays thereof), with different parameters.

 The "set" statements allow you to ***create an object and assign a value to it***.


 See our example script below:


[](../_media/examples/zencode_cookbook/cookbook_when/whenCompleteScriptPart2.zen ':include :type=code gherkin')



The output should look like <a href="../_media/examples/zencode_cookbook/cookbook_when/whenCompleteOutputPart2.json" download>whenCompleteOutputPart2.json</a>.



## Basic cryptography: hashing

Here we have grouped together the statements that perform:


 ***Basic hashing***

 ***Key derivation function (KDF)***

 ***Password-Based Key Derivation Function (pbKDF)***

 ***Hash-based message authentication code (HMAC)***

 ***Aggregation of ECP or ECP2 points***

Hashing works for any data type, so you can hash simple objects (strings, numbers etc.) as well as hashes and dictionaries.

Keep in mind that in order to use more advanced cryptography like encryption, zero knowledge proof, zk-SNARKS, attributed based credential or the [Credential](https://dev.zenroom.org/#/pages/zencode-scenario-credentials) flow you will need to select a *scenario* in the beginning of the scripts. We'll write more about scenarios later, for now we're using the "ecdh" scenario as we're loading an ecdh key from the JSON. See our example below:




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


-->

# The script used to create the material in this page

All the smart contracts and the data you see in this page are generated by the scripts [cookbook_when.bats](https://github.com/dyne/Zenroom/blob/master/test/zencode/cookbook_when.bats) and [cookbook_dictionaries.bats](https://github.com/dyne/Zenroom/blob/master/test/zencode/cookbook_dictionaries.bats). If you want to run the scripts (on Linux) you should:
 - *git clone https://github.com/dyne/Zenroom.git*
 - install  **jq**
 - download a [zenroom binary](https://zenroom.org/#downloads) and place it */bin* or */usr/bin* or in *./Zenroom/src*









<!-- Temp removed,


-->
###
