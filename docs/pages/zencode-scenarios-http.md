



This scenario enables the creation of HTTP GET requests, by appending parameters to base URLs.
The formed GET requests can be called using [Restroom-mw's http statements](https://dyne.github.io/restroom-mw/#/packages/http), using **curl** or other. 
 


You would load a base url:

[](../_media/examples/zencode_cookbook/http/base-url.json ':include :type=code json')


And then load the parameters: 

[](../_media/examples/zencode_cookbook/http/api-values.json ':include :type=code json')

The basic script to generate the GET looks like this:

[](../_media/examples/zencode_cookbook/http/api-compose.zen ':include :type=code gherkin')


Note that the parameters are added in the order they're appended in the script. The result should look like: 

[](../_media/examples/zencode_cookbook/http/api-compose-output.json ':include :type=code json')


<!-- Unused files

 
## Generate a keypair
 
We've already generated a bunch of keypairs in the Zencode Basics part of the manual. In Zenroom the *keypair* is ***schema***, meaning it has a hardcoded structure that works throughout all the statements. 

A keypair will normally be generated from a random seed: if you need to generate a keypair from a known seed - as it is actually happening in this script - you can pass the seed as "rngseed" as a [config parameter](/pages/zenroom-config.md).

The basic script to generate a keypair looks like this:

[](../_media/examples/zencode_cookbook/scenarioECDHZencodePart0.zen ':include :type=code gherkin')

The result should look like this

[](../_media/examples/zencode_cookbook/scenarioECDHKeypair1.json ':include :type=code json')



## Encrypt a message with a public key

Here we'll encrypt a **secret message** using a public key, more precisely we'll encrypt it for two different recipients who have two different keypairs.
Keep in mind that you can in fact encrypt the same message for as many recipient as you like, just follow the structure of the script and extend it as you like.
Remember that that, like the **keypair**, the **public key** is a ***schema*** and it has its own predefined structure. 

For sake of good order, we'll load the keypair of the user encrypting the message (in this case "Alice") separately, passing it to Zenroom using the *-a* parameter:

[](../_media/examples/zencode_cookbook/scenarioECDHAliceKeyapir.json ':include :type=code json')

Following we'll load the secret message and public keys of the recipients, using the *-a* parameter. :

[](../_media/examples/zencode_cookbook/scenarioECDHBobCarlKeysMessage.json ':include :type=code json')


Here's a script to encrypt a **secret message** using two keypairs for two recipients:

[](../_media/examples/zencode_cookbook/scenarioECDHZencodePart5.zen ':include :type=code gherkin')

What we see here are two **secret messages**, next to each other, each encoded for one recipient:

[](../_media/examples/zencode_cookbook/scenarioECDHPart5.json ':include :type=code json')

You can feed this output in the next script to decrypt decrypt it, so you may want to save it into a file that we'll name *scenarioECDHPart5.json*.


### Decrypt a message, encrypted with a public key 

Here we'll learn how to decrypt the message encrypted in the previous script. Keep in mind that the typical use case for this consists in a single user decrypting the message. Therefore, we are able to load one keypair only per script. 

So first we'll load the file *scenarioECDHPart5.json* (the output of the previous script) using the *-a* parameter, and then we'll need a keypair (Bob's in this case) along with Alice's public key, to decrypt the message:

[](../_media/examples/zencode_cookbook/scenarioECDHAliceBobDecryptKeys.json ':include :type=code json')


A basic script to decrypt the **secret message** with a keypair would look like:

[](../_media/examples/zencode_cookbook/scenarioECDHZencodePart6.zen ':include :type=code gherkin')

The result should look like this:

[](../_media/examples/zencode_cookbook/scenarioECDHPart6.json ':include :type=code json')

## Encrypt a JSON with a public key

What if you want to encrypt a more complex data structure? Zenroom can handle that too, provided that you feed the data in a way it can process it, for example in ***base64***. 

Let's say that you want to encrypt this large JSON file, that we'll save as *scenarioECDHJSONdata.json*: 

[](../_media/examples/zencode_cookbook/scenarioECDHJSONdata.json ':include :type=code txt')


First thing to do is encode it to ***base64***, the linux command *base64* will come in handy here, so you could 

```bash
base64 -w 0 scenarioECDHJSONdata.json > scenarioECDHJSONToBased64.b64
``` 
The result should be a file named *scenarioECDHJSONToBased64.b64* containing a long string looking like this: 

[](../_media/examples/zencode_cookbook/scenarioECDHJSONToBased64.b64 ':include :type=code b64')

Then we'll need to insert this string into a JSON that we can feed to Zenroom, and for good order we'll also include the **header** in the file. We can use a shell script like this: 

```bash
cat << EOF > ./scenarioECDHJSONInBased64.json
{"message": "$(cat ./scenarioECDHJSONToBased64.b64)"}
EOF
``` 

The output should be a JSON file named *scenarioECDHJSONInBase64.json*, that we can feed to Zenroom (using the parameter *-a*) and should look like this: 

[](../_media/examples/zencode_cookbook/scenarioECDHJSONInBase64.json ':include :type=code json')

Now we can load our **keypair** and **public keys** to use for the encryption, which look pretty much like in the example where we're encrypting a **secret message**:

[](../_media/examples/zencode_cookbook/scenarioECDHJSONAliceBobCarlKeys.json ':include :type=code json')


Here's a script to encrypt a the JSON file, which also looks a lot like the script used to encrypt a regular **secret message**

[](../_media/examples/zencode_cookbook/scenarioECDHZencodePart5.zen ':include :type=code gherkin')

Again we two encrypted objects, next to each other, each encoded for one recipient:

[](../_media/examples/zencode_cookbook/scenarioECDHJSONOutputbase64.json ':include :type=code json')

You can feed this output in the next script to decrypt decrypt it, so you may want to save it into a file that we'll name *scenarioECDHJSONOutputbase64.json*.


### Decrypt a JSON, encrypted with a public key 

So here we'll learn how to decrypt the message encrypted in the previous script. Again that the typical use case for this consists in a single user decrypting the message. Therefore, we are able to load one keypair only per script. 

So first we'll load the file *scenarioECDHJSONOutputbase64.json* (the output of the previous script) using the *-a* parameter, and then we'll need a keypair (Bob's in this case) along with Alice's public key, to decrypt the message:

[](../_media/examples/zencode_cookbook/scenarioECDHJSONAliceBobDecryptKeys.json ':include :type=code json')


A basic script to decrypt the payload with a keypair would look like:

[](../_media/examples/zencode_cookbook/scenarioECDHJSONDecrypt.zen ':include :type=code gherkin')

The decrypted object, that we'll call *scenarioECDHJSONOutput.json* will look like this and it may look funny at first:

[](../_media/examples/zencode_cookbook/scenarioECDHJSONOutput.json ':include :type=code json')

Now remember that we have temporary encoded this as ***base64***, so we probably want to transform this in JSON again. The linux command *jq* and again the command *base64* will come to help: 

```bash
cat ./scenarioECDHJSONOutput.json | jq -r '.textForBob' | base64 -d | jq . | tee ./scenarioECDHJSONdecryptedOutput.json
EOF
``` 

This script should produce a file named *scenarioECDHJSONdecryptedOutput.json* which should look exactly like the prettified version of initial JSON file before the encryption:

[](../_media/examples/zencode_cookbook/scenarioECDHJSONdecryptedOutput.json ':include :type=code json')



## Create the signature of an object

If you need to transfer some data, where the information itself is readable by everybody, but the readers need to be able to verify that you have written the data yourself, then creating an ECDH signature is what you need.

In this example we'll sign two objects: a ***string*** and a ***string array***, that we'll verify in the next script. Along with the data to be signed, we'll need a **keypair**, and for a change we'll load all of this from single file, that you can pass to Zenroom both as *-a* or as *-k* (in fact there is no difference between the two paramenters), and we'll name *scenarioECDHInputDataPart2.json*:


[](../_media/examples/zencode_cookbook/scenarioECDHInputDataPart2.json ':include :type=code json')


A script to sign two objects looks like:

[](../_media/examples/zencode_cookbook/scenarioECDHZencodePart3.zen ':include :type=code gherkin')


The output should be a JSON file named *scenarioECDHPart3.json*, that we can feed to Zenroom (using the parameter *-a*) and should look like this: 

[](../_media/examples/zencode_cookbook/scenarioECDHPart3.json ':include :type=code json')



### Verify the signature of an object

Here we'll learn how to verify the ECDH signatures produced in the previous script. The typical use case for this consists in a single user verifying the signature so again we are able to load one keypair only per script. 

So first we'll load the file *scenarioECDHPart3.json* (the output of the previous script) using the *-a* parameter, and then we'll need a keypair (Bob's in this case, but it could be anyone's keypair) along with Alice's public key, to verify the message:


[](../_media/examples/zencode_cookbook/scenarioECDHPart3.json ':include :type=code json')

A basic script to verify an ECDH signature looks like:

[](../_media/examples/zencode_cookbook/scenarioECDHZencodePart4.zen ':include :type=code gherkin')

The result should look like this:

[](../_media/examples/zencode_cookbook/scenarioECDHPart4.json ':include :type=code json')




## Symetric cryptography: encrypt with password

The *secret message* is also a ***schema*** in Zenroom, it comprises a string named **header** and a second string containing the message that can have any name. 

In thos very simple encryption, we can load the following data, that include the **password** (just a string in this case) and the whole **secret message**, all of which comes nested inside *"mySecretStuff"* just for the fun of it:

[](../_media/examples/zencode_cookbook/scenarioECDHInputSecretData1.json ':include :type=code json')


A basic script to encrypt the **secret message** with a password would look like:

[](../_media/examples/zencode_cookbook/scenarioECDHZencodePart1.zen ':include :type=code gherkin')

What happens here is: 
 - The regular string inside the **secret message** (here called *myMessage*) will be encrypted.
 - The **header** will simply be signed.

The result should look like this:

[](../_media/examples/zencode_cookbook/scenarioECDHPart1.json ':include :type=code json')

If you later want to decrypt this, you may want to save it into a file that we'll name *scenarioECDHPart1.json*.


### Symetric cryptography: decrypt with password

Decryption does normally come after the encryption, so following script allows you to decrypt the encrypted **secret message** you generated above. So you can pass the file *scenarioECDHPart1.json* (the output from the previous script) to Zenroom using the *-a*, along with password alone using the *-k* parameter:

[](../_media/examples/zencode_cookbook/scenarioECDHInputDataPart1.json ':include :type=code json')


A basic script to decrypt the **secret message** with a password would look like:

[](../_media/examples/zencode_cookbook/scenarioECDHZencodePart2.zen ':include :type=code gherkin')

The result should look like this:

[](../_media/examples/zencode_cookbook/scenarioECDHPart2.json ':include :type=code json')

 -->

# The script used to create the material in this page

All the smart contracts and the data you see in this page are generated by the script [run.sh](https://github.com/dyne/Zenroom/blob/master/test/zencode_http/run.sh). If you want to run the script (on Linux) you should: 
 - *git clone https://github.com/dyne/Zenroom.git*
 - install **zsh** and **jq**
 - download a [zenroom binary](https://zenroom.org/#downloads) and place it */bin* or */usr/bin* or in *./Zenroom/src*
 
 


