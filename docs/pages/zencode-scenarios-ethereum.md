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

You can also opt to use a seed generated elsewhere, for example by using the [keypairoom](https://github.com/ledgerproject/keypairoom) library or it's [npm package](https://www.npmjs.com/package/keypair-lib). 

The statements looks like:

```gherkin
When I create the ethereum key with secret key 'mySeed'
When I create the ethereum key with secret 'mySeed'
```
Which requires you to load a 32 bytes long *base64* object named 'mySeed'.


## Public key 

Ethereum does not use explicitly a public key, it use it only to create an Ethereum address that represents an account. So in Zencode there are no sentences to produce the public keys, but only the address.

# Create Ethereum address


The **Ethereum address** is derived as the last 20 bytes of the public key controlling the account. The public key is produced starting from the private key so you'll need the <a href="../_media/examples/zencode_cookbook/bitcoin/keys.json" download>keys.json</a> you've just generated as input to the following script: 

[](../_media/examples/zencode_cookbook/ethereum/alice_addrgen.zen ':include :type=code gherkin')

The output should look like:

[](../_media/examples/zencode_cookbook/ethereum/alice_address.json ':include :type=code json')


# The transaction: setup and execution

The statements used to manage a transaction, follow closely the logic of the Ethereum protocol. With Ethereum we can store data on the chain or transafer eth from an address to another. What we'll do here is:

* Prepare a JSON file containing:
  * a **ethereum noce**
  * the **gas price**
  * the **gas limit**
  * the **recipient address**
* If the transaction is used to store data then we will add to the JSON file the **data**
* Otherwise if it used to transfer eth we will add the value of the transaction which can be  expressed in wei (**wei value**), gwei (**gwei value**) or eth (**ethereum value**)
* Then we use the file above, to create a **ethereum transaction**.
* Finally we'll **sign it** using the key we generated above.

## Fist step: JSON file

Now Prepare a JSON file containing an ethereum noce, the gas price, the gas limit. The file should look like this: 

[](../_media/examples/zencode_cookbook/ethereum/doc_tx_information.json ':include :type=code json')

## Create the transaction 

### Eth transfer

Now, if you want to trnaser eth, then you will need to add the recipient address and the value to be transfer in the JSON file. That will look like:

[](../_media/examples/zencode_cookbook/ethereum/doc_tx_information_eth.json ':include :type=code json')

you can feed the above json to the script:

[](../_media/examples/zencode_cookbook/ethereum/doc_transaction.zen ':include :type=code gherkin')


Which will produce an unsigned transaction, formatted in human-readable JSON, that should look like:

[](../_media/examples/zencode_cookbook/ethereum/doc_alice_to_bob_transaction.json ':include :type=code json')

### Data storage

On the other hand, if you want to store data on the chain then you will add to the JSON file a **storage contract address** and the **data** to be stored (for the moment data can only be a string). The file should look like this:

[](../_media/examples/zencode_cookbook/ethereum/doc_tx_information_data.json ':include :type=code json')

you can feed the above json to the script:

[](../_media/examples/zencode_cookbook/ethereum/doc_transaction_storage.zen ':include :type=code gherkin')


Which will produce an unsigned transaction, formatted in human-readable JSON, that should look like:

[](../_media/examples/zencode_cookbook/ethereum/doc_alice_storage_tx.json ':include :type=code json')

## Sign the transaction

You can now pass the **transaction** produced from the above script, along with <a href="../_media/examples/zencode_cookbook/ethereum/alice_keys.json" download>keys.json</a> to the following script that will sign the transaction for the chain with **chain id** fabt (https://github.com/dyne/fabchain), you can change it with the **chain id** that you want to use. 

[](../_media/examples/zencode_cookbook/ethereum/doc_sign_transaction.zen ':include :type=code gherkin')

The signed transaction should look like:

[](../_media/examples/zencode_cookbook/ethereum/doc_signed_tx.json ':include :type=code json')

**Note: this script and the previous one can be merged** into one script that creates the transaction, signs it and prints it out.

Moreover, if you want to sign the transaction for the local testnet you can use the following statement:

```gherkin
When I create the signed ethereum transaction
```
that use 1337 as default chain id.

# The script used to create the material in this page

All the smart contracts and the data you see in this page are generated by the scripts [run_offline_wallet.sh](https://github.com/dyne/Zenroom/blob/master/test/zencode_bitcoin/run_offline_wallet.sh) . If you want to run the scripts (on Linux) you should: 
 - *git clone https://github.com/dyne/Zenroom.git*
 - install **zsh** and **jq**
 - download a [zenroom binary](https://zenroom.org/#downloads) and place it */bin* or */usr/bin* or in *./Zenroom/src*


### 
