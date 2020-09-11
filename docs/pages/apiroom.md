<!-- Unused files 
 
givenDebugOutputVerbose.json
givenLongOutput.json
 

Link file with relative path: <a href="./_media/examples/zencode_cookbook/givenArraysLoadInput.json">givenArraysLoadInput.json</a>
 
-->


This is the user manual of Zenroom's web playground [Apiroom](https://apiroom.net). Apiroom has built in: 

 - A [Zencode](/pages/zencode-intro) editor, equipped with auto-complete and syntax highlight
 - An in-the-browser Zenroom instance: you can use the editor to test your smart contracts and run them inside your browser window
 - An instance of [RESTroom-mw](/pages/restroom-mw) that enables you to create an API from a Zencode smart contract with one click
 - An instance of [Swagger ](https://swagger.io/) that you can use to test and debug the APIs you created

# Getting started

When landing on [Apiroom](https://apiroom.net) you're prompted with its front-end, where you have: 

- The text box **Zencode smart contract**: use it to type your [Zencode](pages/zencode-cookbook-intro) scripts
- The text boxes **Keys** and **Data** that you can use to pass different kind of data to Zenroom, as you would do with the parameters **-a** and **-k** from the command line application
 - The **Examples** drop-down menu, that fills the text boxes with sample Zencode smart contracts
- The text box named **Config** that you can use to pass [configuration](/pages/zenroom-config) files to Zenroom (in the front end only)
- The **PLAY▶️** button, that will execute the smart contracts, along with the keys and data you provided
- An output box to show you the output of the Zencode smart contract you executed

And also:

- The **Create API** button, that will save your smart contract and create an API from it (you need to be logged in to use it)
- The **Login** button that allows you to login and create an account
- After having logged in, the **My Contracts** button, to check, test and debug the APIs you have created from your Zencode smart contracts

![ApiroomShots](../_media/images/apiroom/Shot1.png)

# Let's start with an example: Generate a keypair

Press the **Examples** drop-down menu, and click on *Generate a keypair*

![ApiroomShots](../_media/images/apiroom/Shot3.png)

## Running a script 

After that, press the **PLAY▶️** button, and you should be presented with an [ecdh keypair](/pages/zencode-scenarios-ecdh?id=generate-a-keypair) in the **Result** box, looking like this:

![ApiroomShots](../_media/images/apiroom/Shot4.png)


# The auto-complete function

Now, in the **Zencode smart contract** text box, try and type *When I*: the auto-complete should be triggered, prompting you a window like this:

![ApiroomShots](../_media/images/apiroom/Shot5Autocomplete.png)

## Mastering the auto-complete

In the auto-complete window you can scroll up and down, and by clicking or pressing enter, the line will be inserted. The lines inserted will typically include a *dummy object name*, which some times will work straight of the box (like the example highlighted in the screenshot) but more often will need some adjustment. For example, the second statement from top:

```gherkin
When I create the 'nameOfNewObject'
```

will work and create a generic **simple object** named ***nameOfNewObject***. If you change ***nameOfNewObject*** to ***justThrowSomeName***, the statement will still work, cause its job is to create a new object whose name is defined between the quotation marks

But in the statement that is under it in the screenshot, we are in a very different situation: 

```gherkin
When I create the aggregation array of 'nameOfArray'
```

Here the statement is meant the perform the [aggregation](/pages/zencode-cookbook-when?id=basic-cryptography-hashing) of an array of ECP/ECP2 points (a cryptographical operation), so it's especting to be with an existing array. Therefore, as things are now, the statement will not work and throw an error.

If we look instead at the first statement in the screenshot, we first read: 

```gherkin
When I create a petition tally 
```

Followed by *scenario 'petition'* printed in a different color: this part indicates that in order to execute the statement, you need to load the [scenario 'petition'](/pages/zencode-scenarios-petition) in the top of the Zencode smart contract, as we did with the [scenario 'ecdh'](/pages/zencode-scenarios-ecdh) when we generated the keypair. Executing the script without the scenario will throw an error.


## The syntax highlight

The syntax highlight does not perform a syntax check, it's only there to help you read the Zencode smart contract easily, namely to help you make sure you are using the **Given**, **When** and **Then** statements as they should, in the right order.



# Check your APIs: Apiroom's back-end

If you aren't yet logged in, you can see the button **Login**. After logging in, you will be able to see **Create API** button, by pressing it you are prompted with a list of your saves Zencode smart contracts, turned into APIs: 

![ApiroomShots](../_media/images/apiroom/Shot7LinkApi.png)


Here we see: 

- Under **Zencode smart contract** you read the name of the smart contract and the API. By clicking on it you can edit the Zencode of the smart contract and by hovering with your mouse you can edit the whole smart contract in the front-end editor, or delete it.
- The three columns **Keys (-k)**, **Config (-c)** and **Data (-d)**: under them you have the respective keys, config and data, saved in the front-end editor. 
- A column with a **ON-OFF** toggle button: that turns on and off the API.
- When the **ON-OFF** button is on, you have a **Link** clickable link, that takes you straight the the API. 

In the top right you see the buttons: 
- **Export**: it exports the ticked smart contracts and builds a *Dockerfile* along with the software needed to run them, so you can deploy your service wherever you want (currently in beta).
- **Test APIs**: this will bring to a [Swagger](https://swagger.io/) instance, where you can test and debug your APIs.

**IMPORTANT**: take a mental note of the smart contract **Encrypt message with password** as we'll be giving a deeper look at it in a minute. That comes straight from the smart contract **Encrypt a message using a password** from the examples of the front-end editor. 


## Difference between *Keys* and *Data* in the back-end

This is a very **important** point, so pay attention: the Data you saved in the front-end editor is stored here for reference only and ***will not be loaded as the smart-contract is exposed to an API in RESTroom-mw*** (more about this in a minute). 

# A smart contract just turned into an API?

The easiest way to explain this is by demonstrating it, just click on the link [https://apiroom.net/api/dyneorg/Create-a-keypair](https://apiroom.net/api/dyneorg/Create-a-keypair) and you should see something like this: 

![ApiroomShots](../_media/images/apiroom/Shot7BKeypair.png)

If you refresh the page, you will get every time a new keypair. The keypair is being generated on Apiroom's server by [RESTroom-mw](https://dyne.github.io/restroom-mw/#/) and you can call the API with a REST call. 

**IMPORTANT**: the Data you saved in the front-end editor is stored here for reference only and ***will not be loaded as the smart-contract is exposed to an API in RESTroom-mw***, so if the smart contract you are trying to use needs something inside Data to run, the output will be an error. In order to test and debug all of this, [Swagger ](https://swagger.io/) comes to help.

# Testing and debugging an API

If you press the **Test APIs** button you land on something like this: 

![ApiroomShots](../_media/images/apiroom/Shot8Swagger.png)

Let's have a look at the API *Encrypt-message-with-password*: this exposes a smart contract that performs symetric encryption from a string, loaded from the examples in front-end editor. The smart contracts requires several strings to run, of which only one (the password) is saved in the **Keys** field. If you execute it from the **Link** in Apiroom's backend, you would get the error:

```bash
ZEN:run() [!] /zencode.lua:285: Given that I have a 'string' named 'header' [!] Error detected. Execution aborted.
```

The reason is, the smart contract is missing a string (it is actually missing two in total) which we need to pass to the API. This where Swagger comes to help, if you click on the ***/dyneorg/Encrypt-message-with-password*** smart contract link in Swagger, and below you press the ***Try it out*** you are presented with something like this: 

![ApiroomShots](../_media/images/apiroom/Shot8bSwagger.png)

What you want to do now, is
- Fill the **data** in text box with the strings that the smart contract is expecting, in JSON, which you can again check in the **Encrypt a message using a password** example in the front-end editor, 
- Leave the **keys** part empty, because the content of that will be read by the keys stored in the Apiroom's back-end.

The result should look like this (don't mind the formatting, as long as it's JSON it will work): 

![ApiroomShots](../_media/images/apiroom/Shot9Swagger.png)

When you press the **Execute button**, you should be getting the result of the smart-contract (some cryptographic material, in the *Response body* ) along with some other interesting stuff that we see below:

![ApiroomShots](../_media/images/apiroom/Shot10Swagger.png)


## CURL 

Swagger provides you with a *curl* shell script to test the API from a command line, which you can do straight ahead (it works on Windows too!):

```bash
curl -X POST "https://apiroom.net/api/dyneorg/Encrypt-message-with-password" -H  "accept: application/json" -H  "Content-Type: application/json" -d "{\"data\":{\"header\":\"A very important secret\",\"message\":\"Dear Bob, your name is too short, goodbye - Alice.\"},\"keys\":{}}"
```

The result should be some crypto-material, similar to the one you saw in the *Response body*


## CURL with a file

You may also want to use the *curl* script, but instead of passing the data inline in the script, you may want to upload it from a file: you'll simply need to properly encapsulated the **data** in a json file and use the right *curl* parameter to upload the file. 

The file should look like this: 

[](./ApiroomDemoData.json ':include :type=code json')

and the *curl* script should use the the parameter **-d "@./pathOf/myFile.json"**, looking like:

```bash
curl "https://apiroom.net/api/dyneorg/Encrypt-message-with-password" -H "accept: application/json" -H "Content-Type: application/json" -d "@./data.json"
```

## Prototyping your microservice

If you master *curl* and some shell scripting, you will easily be able to create a service that pulls data from somewhere, encapsulates it in a file and then uploads to your favourite *smart-contract turned API* for some super-rapid micro-service prototyping.

You can obviously also use the APIs exposed in Apiroom in your web/mobile application, by using the **POST** call that we have just tested in *curl* 


<!-- WIP 

## TEMP
 
We've done this already: let's start with create a file named *myLargeNestedObjectWhen.json*. This file contains everything we need for every part of this chapter and - along  with the *Given* part of the script, you can use this JSON to later make your own experiments with Zencode.

[](../_media/examples/zencode_cookbook/myLargeNestedObjectWhen.json ':include :type=code json')


[](../_media/examples/zencode_cookbook/whenCompleteScriptGiven.zen ':include :type=code gherkin')
 
-->