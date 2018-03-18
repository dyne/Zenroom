#!/usr/bin/env zenroom
hello = "Hello World!"
print(hello)
print("Base58 encoded Blake2b hash of the string above:")
hash = hash_blake2b(hello)
hash_str = encode_b58(hash)
print(hash_str)

