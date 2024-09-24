
# BBS

The implementation of the BBS scheme inside Zenroom is based on this [draft](https://identity.foundation/bbs-signature/draft-irtf-cfrg-bbs-signatures.html).

The BBS is a digital signature algorithm categorised as a form of short group signature. It can sign multiple messages and produce a fixed-length output. Also, a zero-knowledge proof scheme can be mounted on top of it. Through this capability, the possessor of a signature can generate proofs by selectively disclosing subsets of the originally signed set of messages, whilst preserving the verifiable authenticity and integrity of the messages.

In Zenroom, using the *Scenario bbs*, you will use the **BLS12-381** ciphersuite designed for this algorithm. Moreover, there is the possibility to use two different hash functions: *SHA-256*, that is set to be the default for the signature and verification algorithms, or *SHAKE-256*.

# Key Generation

## Private key

The script below generates two **BBS** private key. (To generate a *SHAKE-256* key , you need to specify the algorithm)

[](../_media/examples/zencode_cookbook/bbs/keygen_docs.zen ':include :type=code gherkin')

The output should look like this:

[](../_media/examples/zencode_cookbook/bbs/alice_keys_docs.json ':include :type=code json')

## Public key

Once you have created a private key, you can feed it to the following script to generate the **public key**:

[](../_media/examples/zencode_cookbook/bbs/pubkey_docs.zen ':include :type=code gherkin')

The output should look like this:

[](../_media/examples/zencode_cookbook/bbs/alice_pubkey_docs.json ':include :type=code json')

# Signature

In this example we'll sign two objects: a string and a string array, that we'll verify in the next script. We show how to sign the two objects with or without specifing the hash function used, when not declared the algorithm will use *SHA-256*.
Along with the data to be signed, we'll need the private key. The private key is in the file we have generated with the first script, while the one with the messages that we will sign is the following:

[](../_media/examples/zencode_cookbook/bbs/messages_docs.json ':include :type=code json')

The script to **sign** these objects look like this:

[](../_media/examples/zencode_cookbook/bbs/sign_bbs_docs.zen ':include :type=code gherkin')

And the output should look like this:

[](../_media/examples/zencode_cookbook/bbs/signed_bbs_docs.json ':include :type=code json')

# Verification

In this section we will **verify** the signatures produced in the previous step. To carry out this task we would need the signatures, the messages and the signer public key. The signatures and the messages are contanined in the output of the last script, while the signer public key can be found in the output of the second script. So the input files should look like:

[](../_media/examples/zencode_cookbook/bbs/signed_bbs_docs.json ':include :type=code json')


[](../_media/examples/zencode_cookbook/bbs/alice_pubkey_docs.json ':include :type=code json')

The script to verify these signatures is the following:

[](../_media/examples/zencode_cookbook/bbs/verify_bbs_docs.zen ':include :type=code gherkin')

The result should look like:

[](../_media/examples/zencode_cookbook/bbs/verified_bbs_docs.json ':include :type=code json')

# BBS Zero-knowledge proof

This scheme is used to create a proof of knowledge of a signature, also called *credential*. It is said to be zero-knowledge as it does not reveal the underlying signature and the undisclosed messages.

The main entities involved in this scheme are: a trusted authority called issuer, a participant and anyone else who wishes to verify the proof. Assume that the participant has already established a secure communication with the issuer, and assume that the issuer and the participant have agreed on a set of messages. The issuer signs the set of messages using its private key creating the credential. Then he sends both the credential and the set of messages to the participant. Then, the partitpant creates the proof, deciding which messages from the agreed set will be disclosed. Finally, the participant can send its proof and the disclosed messages to someone who requests to verify the proof.

## Creation of the issuer keys

In this section we will show how the issuer can create its private and public key.
This step is identical to the generation of the BBS key shown before.
The script to generate the two keys should look like:

[](../_media/examples/zencode_cookbook/bbs/issuer_keys_docs.zen ':include :type=code gherkin')

The output should look like:

[](../_media/examples/zencode_cookbook/bbs/issuer_keys_output_docs.json ':include :type=code json')

## Creation of the credential

In this section we will show how the issuer can create the **credential** for a participant in the network. Here we suppose that the issuer and the participant have previously agreed on a set of messages to be signed to create the credential.  
In this case the input file for the issuer should look like:

[](../_media/examples/zencode_cookbook/bbs/data_credential_docs.json ':include :type=code json')

The script to generate the valid credential looks like this:

[](../_media/examples/zencode_cookbook/bbs/create_credential_docs.zen ':include :type=code gherkin')

In this case, since we MUST give the hash function used to the participant, the output should look like this:

[](../_media/examples/zencode_cookbook/bbs/output_credential_docs.json ':include :type=code json')

## Generation of the proof

In this section, the participant will create the **proof** for its private credential given from an issuer. In order to generate the proof a participant must have the credential of the messages (i.e. the signature produced by the issuer in the previous step) and the public key of the issuer.
Moreover, the participant should generate a presentation header (in this example is a random bit string) and choose a set of disclosed indexes, that could be empty, corresponding to the messages that will be disclosed by the proof.  
So the input file should look like:

[](../_media/examples/zencode_cookbook/bbs/proof_data_docs.json ':include :type=code json')

Given the inputs, one can choose either to use a verbose declaration of all the data needed to perform the operation, or to use an implicit statement. When creating the proof, one also create the disclosed messages needed later for the verification of the proof.  
The script to create the proof is the following:

[](../_media/examples/zencode_cookbook/bbs/create_proof_docs.zen ':include :type=code gherkin')

Note that the proof generation algorithm is randomized, so the output of the two statement should be different.  
The result should look like this:

[](../_media/examples/zencode_cookbook/bbs/created_proof_docs.json ':include :type=code json')

In order to generate a *SHAKE-256* proof, one should specify it. For example:

[](../_media/examples/zencode_cookbook/bbs/create_shake_proof.zen ':include :type=code gherkin')

## Verification of the proof

In this section we will **verify** the proof produced in the previous step. This task  can be performed by anyone that is in possession of the proof, together with  the disclosed indexes, the disclosed messages, the presentation header used for the proof generation, and the issuer public key.
These data are contanined in the output of the last script. 
So the input file should look like:

[](../_media/examples/zencode_cookbook/bbs/created_proof_docs.json ':include :type=code json')

Given the inputs, one can choose either to use a verbose declaration of all the data needed to perform the operation, or to use an implicit statement. 
The script to verify the proof is the following:

[](../_media/examples/zencode_cookbook/bbs/verify_proof_docs.zen ':include :type=code gherkin')

The result should look like:

[](../_media/examples/zencode_cookbook/bbs/verified_proof_docs.json ':include :type=code json')


# The scripts used to create the material in this page

All the smart contracts and the data you see in this page are generated by the scripts [bbs_sha.bats](https://github.com/dyne/Zenroom/blob/master/test/zencode/bbs_sha.bats) and [bbs_zkp.bats](https://github.com/dyne/Zenroom/blob/master/test/zencode/bbs_zkp.bats).

If you want to run the scripts (on Linux) you should: 
 - *git clone https://github.com/dyne/Zenroom.git*
 - install  **jq**
 - download a [zenroom binary](https://zenroom.org/#downloads) and place it */bin* or */usr/bin* or in *./Zenroom/src*
