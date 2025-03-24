## Usage

Zenroom configuration is used to set some application wide parameters at initialization time.
The configuration is passed as a parameter (not as file!) using the "-c" option, or as a parameter
if Zenroom is used as lib. You can pass Zenroom several attributes, wrapped in quotes and separated
by a comma, as in the example below:

```shell
zenroom -z keyring.zen -c "debug=3, rngseed=hex:74eeeab870a394175fae808dd5dd3b047f3ee2d6a8d01e14bff94271565625e98a63babe8dd6cbea6fedf3e19de4bc80314b861599522e44409fdd20f7cd6cfc"
```

Below a list of the config parameters with a description and usage examples.

## Debug verbosity

Syntax and values: **debug=1|2|3** or **verbose=1|2|3**

*debug* and *verbose* are synonyms. They define the verbosity of Zenroom's output.
Moreove if this value is grater than 1 the zenroom watchdog is activated and at each step a check on all internal
data is performed to assert all values in memory are converted to zenroom types.

*Default*: 2

## Scope

Syntax and values: **scope=given|full**

Scope represent wich part of the zenroom contract should be executed. When it is set to *full*, that is the default value,
all the contract is run, on the other hand when it is *given* only the given part is run and the result is the CODEC
status after the given phase, it can be used to know what data a user needs to pass to the contract.

*Default*: full.

## Random seed

Syntax and values: **rngseed=hex:[64 bytes in hex notation]**

Loads a random seed at start, that will be used through the Zenroom execution whenever a random seed is requested.
A fixed random can be used to test determinism. For example, when generating an ECDH key, using:


```shell
rngseed=hex:74eeeab870a394175fae808dd5dd3b047f3ee2d6a8d01e14bff94271565625e98a63babe8dd6cbea6fedf3e19de4bc80314b861599522e44409fdd20f7cd6cfc
```

Should always generate the keyring:

```json
{
  "keyring": {
    "private_key": "Aku7vkJ7K01gQehKELav3qaQfTeTMZKgK+5VhaR3Ui0="
  }
}
```

## Log format

Syntax and values: **logfmt=text|json**

When using *text* as log format, all the log is printed as a text, while using the *json* it is an array,
where, when an error happens, the trace and heap are base64 encoded and can be found respectively in the
values starting with *J64 TRACE:* and *J64 HEAP:*.

Example of log in text:
```
Release version: v4.36.0
Build commit hash: 760ca7bb
Memory manager: libc
ECDH curve is SECP256K1
ECP curve is BLS381
[W] Zencode is missing version check, please add: rule check version N.N.N
[W] {
 KEYRING = {
 bbs = int[32] ,
 bitcoin = octet[32] ,
 dilithium = octet[2528] ,
 ecdh = octet[32] ,
 eddsa = octet[32] ,
 es256 = octet[32] ,
 ethereum = octet[32] ,
 pvss = int[32] ,
 reflow = int[32] ,
 schnorr = octet[32]
 }
}
[W] {
 a_GIVEN_in = {},
 c_CACHE_ack = {},
 c_CODEC_ack = {
 keyring = {
 encoding = "def",
 name = "keyring",
 schema = "keyring",
 zentype = "e"
 }
 },
 c_WHEN_ack = {
 keyring = "(hidden)"
 },
 d_THEN_out = {}
}
+18 Given nothing
+23 When I create the ecdh key
+24 When I create the es256 key
+25 When I create the ethereum key
+26 When I create the reflow key
+27 When I create the schnorr key
+28 When I create the bitcoin key
+29 When I create the eddsa key
+30 When I create the bbs key
+31 When I create the pvss key
+32 When I create the dilithium key
+34 Then print the 'keyrig'
[!] Error at Zencode line 34
[!] /zencode_then.lua:158: Cannot find object: keyrig
[!] Zencode runtime error
[!] /zencode.lua:706: Zencode line 34: Then print the 'keyrig'
[!] Execution aborted with errors.
[*] Zenroom teardown.
Memory used: 606 KB
```
the same log in json
```json
[ "ZENROOM JSON LOG START",
" Release version: v4.36.0",
" Build commit hash: 760ca7bb",
" Memory manager: libc",
" ECDH curve is SECP256K1",
" ECP curve is BLS381",
"[W] Zencode is missing version check, please add: rule check version N.N.N",
"J64 HEAP: eyJDQUNIRSI6W10sIkNPREVDIjp7ImtleXJpbmciOnsiZW5jb2RpbmciOiJkZWYiLCJuYW1lIjoia2V5cmluZyIsInNjaGVtYSI6ImtleXJpbmciLCJ6ZW50eXBlIjoiZSJ9fSwiR0lWRU5fZGF0YSI6W10sIlRIRU4iOltdLCJXSEVOIjp7ImtleXJpbmciOiIoaGlkZGVuKSJ9fQ==",
"J64 TRACE: WyIrMTggIEdpdmVuIG5vdGhpbmciLCIrMjMgIFdoZW4gSSBjcmVhdGUgdGhlIGVjZGgga2V5IiwiKzI0ICBXaGVuIEkgY3JlYXRlIHRoZSBlczI1NiBrZXkiLCIrMjUgIFdoZW4gSSBjcmVhdGUgdGhlIGV0aGVyZXVtIGtleSIsIisyNiAgV2hlbiBJIGNyZWF0ZSB0aGUgcmVmbG93IGtleSIsIisyNyAgV2hlbiBJIGNyZWF0ZSB0aGUgc2Nobm9yciBrZXkiLCIrMjggIFdoZW4gSSBjcmVhdGUgdGhlIGJpdGNvaW4ga2V5IiwiKzI5ICBXaGVuIEkgY3JlYXRlIHRoZSBlZGRzYSBrZXkiLCIrMzAgIFdoZW4gSSBjcmVhdGUgdGhlIGJicyBrZXkiLCIrMzEgIFdoZW4gSSBjcmVhdGUgdGhlIHB2c3Mga2V5IiwiKzMyICBXaGVuIEkgY3JlYXRlIHRoZSBkaWxpdGhpdW0ga2V5IiwiKzM0ICBUaGVuIHByaW50IHRoZSAna2V5cmlnJyIsIlshXSBFcnJvciBhdCBaZW5jb2RlIGxpbmUgMzQiLCJbIV0gL3plbmNvZGVfdGhlbi5sdWE6MTU4OiBDYW5ub3QgZmluZCBvYmplY3Q6IGtleXJpZyJd",
"[!] Zencode runtime error",
"[!] /zencode.lua:706: Zencode line 34: Then print the 'keyrig'",
"[!] Execution aborted with errors.",
"[*] Zenroom teardown.",
" Memory used: 663 KB",
"ZENROOM JSON LOG END" ]
```
*Default*: *json* in javascript bindings and *text* otherwise.

## Limit iterations

Syntax and values: **maxiter=dec:[at most 10 decimal digits]**

Define the maximum number of iterations the contract is allowed to do.

*Default*: 1000.

## Limit of memory

Syntax and values: **maxmem=dec:[at most 10 decimal digits]**

Define the maximum memory in MB that lua can occupy before calling the garbage collector
during the run phase.

*Default*: 1024 (1GB)

## Secure memory block num and size

Syntax and values: **memblocknum=dec (default 64)**,**memblocksize=dec (default 256)**

Number of blocks and size of each block in size, defining the space of memory allocated for the secure pool used in Zenroom for sensitive values during operation (internal [sailfish-pool](https://github.com/dyne/sailfish-pool/))

