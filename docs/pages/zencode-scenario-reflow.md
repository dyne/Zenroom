# Scenario 'Reflow': multisignature

Reflow is a novel signature scheme supporting unlinkable signatures by multiple parties authenticated by means of a zero-knowledge credential scheme.  Reflow integrates with blockchains to ensure condidentiality, authenticity and availability even when credential issuing authorities are offline. 

Reflow uses short and computationally efficient authentication credentials and signatures application scale linearly over thousands of participants.

The Reflow crypto scheme is based on the [Credential scenario](/pages/zencode-scenario-credentials.md), an implementation of the [Coconut](https://arxiv.org/abs/1802.07344) paper, which combines with the [BLS signatures](https://link.springer.com/chapter/10.1007/3-540-45708-9_23). 

## Setup: Credential and BLS keys 

### Issuer setup 

In the first part of the setup, we need to create the key and public key of the issuer, this is similar to what happens with the **Credential** flow, firste the private key: 

[](../_media/examples/zencode_cookbook/reflow/issuer_keygen.zen ':include :type=code gherkin')

Which should output (file *issuer_keypair.json*): 

[](../_media/examples/zencode_cookbook/reflow/issuer_keypair.json ':include :type=code json')

And using the *keypair* we should generate the public key: 

[](../_media/examples/zencode_cookbook/reflow/issuer_verifier.zen ':include :type=code gherkin')

Which should output (file *issuer_verifier.json*): 

[](../_media/examples/zencode_cookbook/reflow/issuer_verifier.json ':include :type=code json')

**Note:** these two scripts can be merged into one, so that both the private and public key are produced at once. We kept the scripts separated cause typically the keys are stored separately.

### Participant setup

Here we are setting up the participants to the signature, we'll create to different and independent keys at once: 
 - the **Credential key** 
 - the **BLS key** 
 - the **BLS public key** 

Needless to say, each Participant will need to create their own keypair, so this script will run on the participant's device. In this example the flow includes 3 participants: in our benchmarks we have tested the flow with up to 5000, so anything between 2 and 5000 should work. 

[](../_media/examples/zencode_cookbook/reflow/keygen_Alice.zen ':include :type=code gherkin')

Which should output (file *keypair_Alice.json*): 

[](../_media/examples/zencode_cookbook/reflow/keypair_Alice.json ':include :type=code json')

Using this keypair, the participant will use it to create its BLS public key (file: *public_key_Alice.json*): 

[](../_media/examples/zencode_cookbook/reflow/pubkey_Alice.zen ':include :type=code gherkin')

Which should output (file *public_key_Alice.json*): 

[](../_media/examples/zencode_cookbook/reflow/public_key_Alice.json ':include :type=code json')

**Note:** also these two scripts can be merged into one, so that both the private and public key are produced at once. We kept the scripts separated cause typically the keys are stored separately.


Next, each participant should generate a **Credential request** (input: *keypair_Alice.json*): 

[](../_media/examples/zencode_cookbook/reflow/request_Alice.zen ':include :type=code gherkin')

Which should output (file *request_Alice.json*): 

[](../_media/examples/zencode_cookbook/reflow/request_Alice.json ':include :type=code json')

 

**Note:** the name of the participant can be passed a parameter to the script using the [Given my name is in a 'string' named 'myUserName'](/pages/zencode-cookbook-given?id=state-the-user39s-identity-given-i-am "Reflow Multisignature") statement, this will help you keeping the code separated from the data. 

#### Issuer signs the credential

The following step of the participant setup corresponds to the **Issuer** signing the **Credential request** generated just above. So this script is run on the Issuer's machine (input: *issuer_keypair.json* and *request_Alice.json*):

[](../_media/examples/zencode_cookbook/reflow/issuer_sign_Alice.zen ':include :type=code gherkin')

Which should output (file: **issuer_signature_Alice.json**): 

[](../_media/examples/zencode_cookbook/reflow/issuer_signature_Alice.json ':include :type=code json')


#### Participant aggregates the credential

The last step of the participant setup is the **Credential aggregation**, again happening on the participant's device: (input *keypair_Alice.json* and *issuer_signature_Alice.json*)


[](../_media/examples/zencode_cookbook/reflow/aggr_cred_Alice.zen ':include :type=code gherkin')

Which should output: 

[](../_media/examples/zencode_cookbook/reflow/verified_credential_Alice.json ':include :type=code json')

## The Reflow seal

The **Reflow seal** is the actual multisignature object. This **Reflow seal** is created as "empty" and as the participants sign it, their signatures are progressively added to it, using homomorphic encryption. 

The creation of the **Reflow seal** requires some preparation, namely generating the ***Reflow Identity*** and the ***Public keys array***, which in our example is done ***outside of Zenroom***.

### The "Reflow identity" and Public keys array

The ***Reflow identity*** is data, you can use to give context to the **Reflow seal**, which in our flow is passed as a json file. In our example we're using a JSON fine describing a business transactionm but it could be just a **string** or a **number** (file: *uid.json*): 

[](../_media/examples/zencode_cookbook/reflow/uid.json ':include :type=code json')

The ***Public keys array*** contains the BLS public keys of each participant, and it's a **Schema**, so its format is hardcoded in Zenroom. The list has the look like this (file: *public_key_array.json*): 

[](../_media/examples/zencode_cookbook/reflow/public_key_array.json ':include :type=code json')

Assuming that all your public keys are named **public_key_(something).json**, you generate it using the **jq** with the line (also see the shell script mentioned at the bottom of this page): 

```shell
jq -s 'reduce .[] as $item ({}; . * $item)' . /path/public_key_* | tee /path/public_keys.json
```

### Create the Reflow seal  

Input: *public_key_array.json* and *uid.json*



[](../_media/examples/zencode_cookbook/reflow/seal_start.zen ':include :type=code gherkin')

Which should output (file: *reflow_seal.json*) : 

[](../_media/examples/zencode_cookbook/reflow/reflow_seal.json ':include :type=code json')


### Create a Reflow signature 

Input: ***credential_to_sign.json*** and ***verified_credential_Alice.json***

[](../_media/examples/zencode_cookbook/reflow/sign_seal.zen ':include :type=code gherkin')

 



### Collect the Reflow signatures 



## Verify the Reflow seal  



## Verify the Reflow seal  





```json
{
   "list_of_infected" : [
      "b2bf0a3038f3810d2b3fbd4f300b3d8827cf5fb0078c3bd3dc65c48481162820",
      "d843e0cec156f496e11f39f81e40708cf95341dad022a450924decd7e153354c",
      "64c200f8db42a03f9757529f6415aa452639039f2c92301b640c17b3889b6ccc",
      "595d59e1ddc733536e9943f29ad066904bb06802cfe8c216bdc9d67d0deb28f9",
      "e28668b87d50147848385b5adfc010f7fce516e57115220be49214d415a0e451",
      "3188ab1c837658bd906430d98b41eb3b6012c153282456abbaf622036f4996e9"
}
```




# The script used to create the material in this page

All the smart contracts and the data you see in this page are generated by the script [run-recursive.sh](https://github.com/dyne/Zenroom/blob/master/test/zencode_reflow/run-recursive.sh). If you want to run the script (on Linux) you should: 
 - *git clone https://github.com/dyne/Zenroom.git*
 - install **zsh** and **jq**
 - install **lua cjson**, you'll probably need **luarocks** for this
 - download a [zenroom binary](https://zenroom.org/#downloads) and place it */bin* or */usr/bin* or in *./Zenroom/src*