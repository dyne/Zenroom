# Zenroom Crypto VM

## Intro

Zenroom is a **secure language interpreter** of both Lua and its own
secure domain specific language (DSL) to execute fast cryptographic
operations using elliptic curve arithmetics.

The Zenroom VM is very small, has **no external dependency**, is fully
deterministic and ready to run **end-to-end encryption** on any platform:
desktop, embedded, mobile, cloud and even web browsers.

**Zencode** is the name of the DSL executed by Zenroom: it is similar
to human language and can process large data structures while
operating cryptographic transformations and basic logical operations
on them.

## Quickstart


1. Download the [Zenroom binary](https://zenroom.org/#downloads) that works for your system  
1. Download the smart contract <a href="data:text/plain,Scenario coconut: credential keygen
Given that I am known as 'Alice'
When I create the credential keypair
Then print my 'credential keypair'" 
download="credential_keygen.zen">credential_keygen.zen</a>  
1. (On Linux/Mac) Run: `zenroom -z credential_keygen.zen | tee keypair.json` 

If everything went well, in the file `keypair.json` you will see something like this:


```json
{
   "Alice":{
      "credential_keypair":{
         "private":"AZNuDnEujJlccuejLIHihxFeKzzuReL3mwikvtcCVHlFaYo7rCdR",
         "public":"AhMBC4woNICc0OZyQS3kPE5q6EVlwyn5VTsBKG1ulsxmDfN1f9Kmqc0fgWUsRxRSIhSsJnSsP1CUjNk"
      }
   }
}
```

## Quicklinks


Checkout Zenroom's [documentation](https://dev.zenroom.org/),  [homepage](http://zenroom.org/), the ["Coconut" smart contracts](https://github.com/DECODEproject/Zenroom/tree/master/test/zencode_coconut) or the [Zencode whitepaper](https://dev.zenroom.org/pages/zenroom_whitepaper.pdf).



**Zenroom is licensed as AGPLv3, we are happy to discuss dual-licensing on a commercial base.**
