# Testnet vs Mainnet

There are format difference between Bitcoin *testnet* and *mainnet*. We wanted to enable both the networks, making it comfortable for the developer to switch from one to another (note: keys and protocols have slight differences between testnet and mainnet. 

For this reason in any statement that is specific for the network, by swapping the word **testnet** with **bitcoin**, you change the way the statement works.  

For example, In order to create a **key for the testnet**, you can use the statement 

```gherkin
When I create the testnet key
```

On the other hand, to **create a key for mainnet** you can use:

```gherkin
When I create the bitcoin key
```

The example below is created for the **testnet** as we believe that's a convenient starting point.

Note: you don't need to define a scenario, as the zencode statements for **bitcoin are always loaded**. 


# Key generation

On this page we prioritize security over easy of use, therefore we have chosen to keep some operations separated. 

Particularly the generation of private and public key (and the creation and signature of transactions, further down), which can indeed be merged into one script, but you would end up with both the keys in the same output. 

## Private key
The script below generates a **bitcoin testnet** private key. 

Note: you don't need to declare your identity using the statement ***Given I am 'User1234'***, but you can still do it if it comes handy, and then use the statement ***Then print my 'keys'*** to format the output.

[](../_media/examples/zencode_cookbook/bitcoin/keygen.zen ':include :type=code gherkin')

The output should look like this: 

[](../_media/examples/zencode_cookbook/bitcoin/keys.json ':include :type=code json')

You want to store this into the file 
<a href="../_media/examples/zencode_cookbook/bitcoin/keys.json" download>keys.json</a>

### Generate a private key from a known seed 

Key generation in Zenroom uses by default a pseudo-random as seed, that is internally generated. 

You can also opt to use a seed generated elsewhere, for example by using the [keypairoom](https://github.com/ledgerproject/keypairoom) library or it's [npm package](https://www.npmjs.com/package/keypair-lib). 

The statements looks like:

```gherkin
When I create the testnet key with secret key 'mySeed'
```
Which requires you to load a 32 bytes long *base64* object named 'mySeed', the statement is defined [here](https://github.com/dyne/Zenroom/blob/master/src/lua/zencode_bitcoin.lua#L156).



## Public key 

Once you have created a private key, you can feed it to the following script to generate the public key:


[](../_media/examples/zencode_cookbook/bitcoin/pubkeygen.zen ':include :type=code gherkin')


The output should look like this: 

[](../_media/examples/zencode_cookbook/bitcoin/pubkey.json ':include :type=code json')

You want to store this into the file 
<a href="../_media/examples/zencode_cookbook/bitcoin/pubkey.json" download>pubkey.json</a>


# Create testnet address


Next, you'll need to generate a **bitcoin testnet address**, you'll need the <a href="../_media/examples/zencode_cookbook/bitcoin/keys.json" download>keys.json</a> you've just generated as input to the following script: 

[](../_media/examples/zencode_cookbook/bitcoin/pubgen.zen ':include :type=code gherkin')


The output should look like: 

[](../_media/examples/zencode_cookbook/bitcoin/address.json ':include :type=code json')


# The transaction: setup and execution

The statements used to manage a transaction, follow closely the logic of the Bitcoin protocol. What we'll do here is:

* Prepare a JSON file containing the **amount** to be transferred, **recipient, sender and fee**.
* **Add to the JSON file a list of the unspent transactions**, as it is returned from a Bitcoin explorer (we're using Blockstream in the test).
* Then we use the file above, to create a **testnet transaction**.
* After creating the transaction, first we'll **sign it** using the key we generated above, then we'll create a **raw transaction** out of it, which can be posted to any Bitcoin client. 


## Load amount, recipient, sender and fee

Now prepare a JSON file containing the amount, recipient, fee and sender: the sender in this example is the one we have just generated as **testnet_address**. The file should look like this: 

[](../_media/examples/zencode_cookbook/bitcoin/transaction_data.json ':include :type=code json')

## Load unspent transaction

Then, get a **list of the unspent transactions from your address**, which is again the **testnet_address** we have generated above, but at this point we have already transferred some coins to this address (otherwise the list of unspent transactions would be empty). In the example we ***curl*** blockstream.info with the address we generated above:

[](../_media/examples/zencode_cookbook/bitcoin/unspent_query.sh ':include :type=code bash')


The result should be a JSON file looking like: 

[](../_media/examples/zencode_cookbook/bitcoin/unspent.json ':include :type=code json')

Now merge the <a href="../_media/examples/zencode_cookbook/bitcoin/transaction_data.json" download>transaction_data.json</a>
  and <a href="../_media/examples/zencode_cookbook/bitcoin/unspent.json" download>unspent.json</a>  two files together into <a href="../_media/examples/zencode_cookbook/bitcoin/order.json" download>order.json</a>. 
  
You can do so for example by using **jq**: 
 
```bash
 jq -s '.[0] * .[1]' unspent.json  transaction_data.json
```

## Create the transaction 

Now, you can feed the file **order.json** to the script:

[](../_media/examples/zencode_cookbook/bitcoin/sign.zen ':include :type=code gherkin')


Which will produce an unsigned transaction, formatted in human-readable JSON, that should look like:

[](../_media/examples/zencode_cookbook/bitcoin/transaction.json ':include :type=code json')

If the recipient address is saved under a name other than **recipient** then the transaction can be created using the statement:

```gherkin
When I create the testnet transaction to ''
```

## Sign the transaction and format as raw transaction 

You can now pass the transaction produced from the above script, along with <a href="../_media/examples/zencode_cookbook/bitcoin/keys.json" download>keys.json</a> to the following script that will sign the transaction and format it so that we can pass it to any Bitcoin node. 

[](../_media/examples/zencode_cookbook/bitcoin/sign_transaction.zen ':include :type=code gherkin')

The signed transaction should look like:

[](../_media/examples/zencode_cookbook/bitcoin/rawtx.json ':include :type=code json')

**Note: this script and the previous one can be merged** into one script that creates the transaction, signs it and prints it out as raw transaction. 

In this example we kept the script separated as this script was originally meant to demonstrate how to make an **offline Bitcoin wallet**, where the signature happens on different machine (which can be kept offline for security reasons). You can merge the two scripts and feed the resulting script with <a href="../_media/examples/zencode_cookbook/bitcoin/keys.json" download>keys.json</a> we created on top of this page and <a href="../_media/examples/zencode_cookbook/bitcoin/order.json" download>order.json</a>



# The script used to create the material in this page

All the smart contracts and the data you see in this page are generated by the scripts [run_offline_wallet.sh](https://github.com/dyne/Zenroom/blob/master/test/zencode_bitcoin/run_offline_wallet.sh) . If you want to run the scripts (on Linux) you should: 
 - *git clone https://github.com/dyne/Zenroom.git*
 - install **zsh** and **jq**
 - download a [zenroom binary](https://zenroom.org/#downloads) and place it */bin* or */usr/bin* or in *./Zenroom/src*




<!-- Temp removed, 

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
 



-->
### 
