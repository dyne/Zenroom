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

Which should output (file *keypair_Alice.json*, since **Alice** is the participant we're setting up):

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

Which should output (file *verified_credential_Alice.json*): 

[](../_media/examples/zencode_cookbook/reflow/verified_credential_Alice.json ':include :type=code json')

## The Reflow seal

The **Reflow seal** is the actual multisignature cryptographic object. The **Reflow seal** is created as "empty" and as the participants sign it, their signatures are progressively added to it, using homomorphic encryption. 

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

The seal can be created by anyone, using a **Reflow identity** and the of public keys of the participants. The script that creates the seal is (Input: *public_key_array.json* and *uid.json*):


[](../_media/examples/zencode_cookbook/reflow/seal_start.zen ':include :type=code gherkin')

Which should output (file: *reflow_seal.json*) : 

[](../_media/examples/zencode_cookbook/reflow/reflow_seal_empty.json ':include :type=code json')

The **Reflow seal** that we have just created i *empty* (meaning no one has signed it yet), can now be sent over to the participants so that they can sign it using the **Reflow signature** script (that we'll see in a second) and send it back. 

## The Reflow signature 

In order to create reflow signature, we need to pass to Zenroom 3 objects: 
 - The *issuer public key*
 - The *Reflow seal*
 - The *verified credential* of the participant 

Since Zenroom can only take to parameter as input we need to merge two of these files into one: it is conveniente to merge the *issuer public key* and *Reflow seal* since they are unique to this seal and can therefore be merged once by the organizer and be sent over to all the partecipants.

We did the merge using **jq**:

```shell
jq -s '.[0] * .[1]' ${out}/issuer_public_key.json ${out}/multisignature.json | jq . > ${out}/credential_to_sign.json
```

The output (file: *credential_to_sign.json*) should look like:

[](../_media/examples/zencode_cookbook/reflow/credential_to_sign.json ':include :type=code json')

### Create a Reflow signature

Once we have that figured, each partecipant can produce a signature, for which they will need the files  ***credential_to_sign.json*** and ***verified_credential_Alice.json*** (here **Alice** is the partecipant signing)

[](../_media/examples/zencode_cookbook/reflow/sign_seal.zen ':include :type=code gherkin')

Output (file: *signature_Alice.json*): 

[](../_media/examples/zencode_cookbook/reflow/signature_Alice.json ':include :type=code json')

 The resulted signature has major similarities with the [petition signature](http://bario-x250u:3000/#/pages/zencode-scenarios-petition?id=signing-the-petition). Once each participant has produced a signature, the signatures can be added cryptographically to the **Reflow seal**, using the script **Collect signature**.



### Collect the signatures and add them to the the Reflow seal 

Here we need again to join two files again, the **issuer_verifier.json** and **signature_Alice.json**, which we have achieved with: 


```shell
jq -s '.[0] * .[1]' ${out}/issuer_verifier.json ${out}/signature_$name.json > ${out}/issuer_verifier_signature_$name.json
```

Note that we are using the variable **$name** instead of **Alice**, this line is taken from the script [run-recursive.sh](https://github.com/dyne/Zenroom/blob/master/test/zencode_reflow/run-recursive.sh), also mentioned in the bottom of the page.

The output file looks like (file: *issuer_verifier_signature_Alice.json*):

[](../_media/examples/zencode_cookbook/reflow/issuer_verifier_signature_Alice.json ':include :type=code json')



The file *issuer_verifier_signature_Alice.json* we have just created along with the latest *reflow_seal.json* will be passed as input to the script: 

[](../_media/examples/zencode_cookbook/reflow/collect_sign.zen ':include :type=code gherkin')


the result, after that three signatures have been added, should be (file: *reflow_seal.json*):


[](../_media/examples/zencode_cookbook/reflow/reflow_seal.json ':include :type=code json')

Since in this demo we have 3 partecipants, we now have our fully signed **Reflow seal**.

## Verify the Reflow seal  

After all the signatures have been added to the **Reflow seal**, in order verify the signatures, we can run the script 

[](../_media/examples/zencode_cookbook/reflow/verify_sign.zen ':include :type=code gherkin')

Which will simply return a string: 

```json
{
  "output": [
    "SUCCESS"
  ]
}
```

Keep in mind that this verification can be placed in the beginning of other scripts, providing a condition to the execution.


## Verify the Reflow identity

You may as well want to verify just the **Reflow identity**, so the data that the signature was built around, by running (input: *reflow_seal.json* and *uid.json*)


[](../_media/examples/zencode_cookbook/reflow/verify_identity.zen ':include :type=code gherkin')


```json
{
  "output": [
    "The_reflow_identity_in_the_seal_is_verified"
  ]
}
```

Like above, this verification can be placed in the beginning of other scripts, providing a condition to the execution.






# The script used to create the material in this page

All the smart contracts and the data you see in this page are generated by the script [run-recursive.sh](https://github.com/dyne/Zenroom/blob/master/test/zencode_reflow/run-recursive.sh). If you want to run the script (on Linux) you should: 
 - *git clone https://github.com/dyne/Zenroom.git*
 - install **zsh** and **jq**
 - install **lua cjson**, you'll probably need **luarocks** for this
 - download a [zenroom binary](https://zenroom.org/#downloads) and place it */bin* or */usr/bin* or in *./Zenroom/src*