# Key generation

On this page we prioritize security over easy of use, therefore we have chosen to keep some operations separated.

Particularly the generation of private and public key (and the creation and signature of transactions, further down), which can indeed be merged into one script, but you would end up with both the keys in the same output.

## Private key
The script below generates a **ethereum** private key.

Note: you don't need to declare your identity using the statement ***Given I am 'User1234'***, but you can still do it if it comes handy, and then use the statement ***Then print my 'keys'*** to format the output.

[](../_media/examples/zencode_cookbook/ethereum/alice_keygen.zen ':include :type=code gherkin')

The output should look like this:

[](../_media/examples/zencode_cookbook/ethereum/alice_keys.json ':include :type=code json')

You want to store this into the file
<a href="../_media/examples/zencode_cookbook/ethereum/alice_keys.json" download>keys.json</a>

### Generate a private key from a known seed

Key generation in Zenroom uses by default a pseudo-random as seed, that is internally generated. 

You can also opt to use a seed generated elsewhere, for example by using the [keypairoom](https://github.com/ledgerproject/keypairoom) library or it's [npm package](https://www.npmjs.com/package/keypair-lib). Suppose you have an Ethereum private key:

[](../_media/examples/zencode_cookbook/ethereum/doc_key.json ':include :type=code json')

Then you can upload it with a script that look like the following script:

[](../_media/examples/zencode_cookbook/ethereum/doc_key_upload.zen ':include :type=code gherkin')


## Public key

Ethereum does not use explicitly a public key, it use it only to create an Ethereum address that represents an account. So in Zencode there are no sentences to produce the public keys, but only the address.

If, for any reason, you need the ethereum public key, then you can simply compute it by understanding that the Ethereum private key is an ECDH private key so the following script will do the trick:

[](../_media/examples/zencode_cookbook/ethereum/doc_pubgen.zen ':include :type=code gherkin')

# Create Ethereum address


The **Ethereum address** is derived as the last 20 bytes of the public key controlling the account. The public key is produced starting from the private key so you'll need the <a href="../_media/examples/zencode_cookbook/ethereum/alice_keys.json" download>keys.json</a> you've just generated as input to the following script: 

[](../_media/examples/zencode_cookbook/ethereum/alice_addrgen.zen ':include :type=code gherkin')

The output should look like:

[](../_media/examples/zencode_cookbook/ethereum/alice_address.json ':include :type=code json')


# The transaction: setup and execution

The statements used to manage a transaction, follow closely the logic of the Ethereum protocol. With Ethereum we can store data on the chain or transafer eth from an address to another. What we'll do here is:

* Prepare a JSON file containing:
  * the **ethereum noce**, it is the number of transactions sent from the sender address
  * the **gas price**
  * the **gas limit**
  * the **recipient address**
* If the transaction is used to store data then we will add to the JSON file the **data**
* Otherwise if it used to transfer eth we will add the value of the transaction which can be  expressed in wei (**wei value**), gwei (**gwei value**) or eth (**ethereum value**)
* Then we use the file above, to create a **ethereum transaction**.
* Finally we'll **sign** it using the key we generated above.

## Fist step: JSON file

Now Prepare a JSON file containing the noce, the gas price and the gas limit. The file should look like this:

[](../_media/examples/zencode_cookbook/ethereum/doc_tx_information.json ':include :type=code json')

## Create the transaction

### Eth transfer

Now, if you want to transfer eth, then you will need to add the recipient address and the value to be transfer in the JSON file. That will look like:

[](../_media/examples/zencode_cookbook/ethereum/doc_tx_information_eth.json ':include :type=code json')

you can feed the above JSON to the script:

[](../_media/examples/zencode_cookbook/ethereum/doc_transaction.zen ':include :type=code gherkin')

Which will produce an unsigned transaction, formatted in human-readable JSON, that should look like:

[](../_media/examples/zencode_cookbook/ethereum/doc_alice_to_bob_transaction.json ':include :type=code json')

### Data storage

On the other hand, if you want to store data on the chain then you will add to the JSON file a **storage contract address** and the **data** to be stored. The file should look like this:

[](../_media/examples/zencode_cookbook/ethereum/doc_tx_information_data.json ':include :type=code json')

you can feed the above JSON to the script:

[](../_media/examples/zencode_cookbook/ethereum/doc_transaction_storage.zen ':include :type=code gherkin')


Which will produce an unsigned transaction, formatted in human-readable JSON, that should look like:

[](../_media/examples/zencode_cookbook/ethereum/doc_alice_storage_tx.json ':include :type=code json')

The data stored in this case was a **string** because ethereum allows only array of bytes as data and the string is the simplest example of that. However you can upload the type of data that you want (array or dictionaries) and then use [mpack](https://dev.zenroom.org/#/pages/zencode-cookbook-when) to serialize it before uploading it in the ethereum transaction.


## Sign the transaction

You can now pass the **transaction** produced from the above script (here we are using the transaction created to sotre the data), along with <a href="../_media/examples/zencode_cookbook/ethereum/alice_keys.json" download>keys.json</a> to the following script that will sign the transaction for a specific chain with **chain id** specified in the statement and produce the raw transaction. Here, for example, we are using fabt as **chain id** (https://github.com/dyne/fabchain).

[](../_media/examples/zencode_cookbook/ethereum/doc_sign_transaction.zen ':include :type=code gherkin')

The signed raw transaction should look like:

[](../_media/examples/zencode_cookbook/ethereum/doc_signed_tx.json ':include :type=code json')

**Note: this script and the previous one can be merged** into one script that creates the transaction, signs it and prints it out.

Moreover, if you want to sign the transaction for the local testnet you can use the following script:

[](../_media/examples/zencode_cookbook/ethereum/doc_sign_transaction_local.zen ':include :type=code gherkin')

that use 1337 as default chain id.

## Broadcast and read ethereum transactions

Once you have created your signed ethereum transaction then you can use [RESTroom-mw](https://dev.zenroom.org/#/pages/restroom-mw) to connect to a node and broadcast your transaction in the Ethereum chain you have choosen. Obviously you have to have some Eth in your address to broadcast the transaction, if you want to do some test you can use the [fabchain](https://github.com/dyne/fabchain) test network, where you can claim 1 eth per day inserting your ethreum address [here](http://test.fabchain.net:5000/).

Now that you have broadcasted your transaction you can use also RESTroom-mw to retrieve the data stored in the transaction, but the data you will get will be of the form:

[](../_media/examples/zencode_cookbook/ethereum/doc_read_stored_string.json ':include :type=code json')

and we can read the original data with the following script:

[](../_media/examples/zencode_cookbook/ethereum/doc_read_stored_string.zen ':include :type=code gherkin')

The output will be:

[](../_media/examples/zencode_cookbook/ethereum/doc_retrieved_data.json ':include :type=code json')

# The script used to create the material in this page

All the smart contracts and the data you see in this page are generated by the scripts [run.sh](https://github.com/dyne/Zenroom/blob/master/test/zencode_ethereum/run.sh) . If you want to run the scripts (on Linux) you should: 
 - *git clone https://github.com/dyne/Zenroom.git*
 - install **zsh** and **jq**
 - download a [zenroom binary](https://zenroom.org/#downloads) and place it */bin* or */usr/bin* or in *./Zenroom/src*
