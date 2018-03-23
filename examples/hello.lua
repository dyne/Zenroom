#!/usr/bin/env zenroom
crypto = require "crypto"
hello = "Hello World!"
print(hello)
print("Base58 encoded Blake2b hash of the string above:")
hash = crypto.hash_blake2b(hello)
hash_str = crypto.encode_b58(hash)
print(hash_str)

