# Encoding formats

In Zencode the initial Given and final Then phases allow one to specify which encoding formats should be used to interpret input and output data. This is an example how it is done:

```
Given I have a 'string' named 'address'
```
The above will take an input value whose key is 'address' and interpret its contents as string.

```
Then print my data as 'hex'
```

The above will print an output value whose key is 'data' and show it as hexadecimal.

In addition to the usual hexadecimal and string encoding formats, there are many more especially useful in cryptography and to transport data around. Zencode supports the following formats. 

For the examples below, in which we will show the result of the various encodings, we will use the following string.
```json
{
	"address": "String to encode"
}
```


## base64
Base64 is the default encoding used for input and output data when nothing is specified. It is a case-sensitive sequence of letters and numbers with some '=' characters at the end and it is very commonly used to encode binary data like keys or even images.

```
When I rename the 'address' to 'address_to_base64'

Then print 'address_to_base64' as 'base64'
```

```json
{
   "address_to_base64": "U3RyaW5nIHRvIGVuY29kZQ=="
}
```

## url64
URL64 encoding is similar to Base64 but optimized for URLs and filenames. It replaces '+' with '-' and '/' with '_' to avoid issues with special characters in URLs. Additionally, URL64 removes the '=' padding at the end and instead adds zeros to generate a character with a fixed value. This ensures safe encoding while maintaining compatibility with URL structures.
```
When I rename the 'address' to 'address_to_url64'

Then print 'address_to_url64' as 'url64'
```

```json
{
   "address_to_url64": "U3RyaW5nIHRvIGVuY29kZQ"
}
```

## base58
Base58 encoding is an encoding scheme that uses 58 alphanumeric characters to represent binary data in a more compact and readable format. It is similar to Base64 but excludes characters that can be easily confused with others, such as 0 (zero), O (capital o), I (capital i), and l (lowercase L). This makes Base58 more suitable for human-readable identifiers, such as Bitcoin addresses.

```
When I rename the 'address' to 'address_to_base58'

Then print 'address_to_base58' as 'base58'
```

```json
{
   "address_to_base58": "BJiF2nwtq1yvLdVQgqmra8"
}
```

## mnemonic
Mnemonic encoding (based on BIP39) converts a binary string into a sequence of words from a predefined wordlist. Each word represents an 11-bit index in a dictionary of 2048 words. The resulting phrase consists of 12, 15, 18, 21, or 24 words, making it easier to read, write, and remember cryptographic keys or seed phrases securely.

```
When I rename the 'address' to 'address_to_mnemonic'

Then print 'address_to_mnemonic' as 'mnemonic'
```

```json
{
   "address_to_mnemonic": "fat phone olympic system improve demand route arrow hover bread suit slice"
}
```

## hex
Hexadecimal encoding converts a byte array into a readable string using hexadecimal characters. Each byte is split into two nibbles (4 bits each), which are then mapped to hexadecimal digits (0-9 and a-f). This encoding is commonly used in computing and cryptography to represent binary data in a compact and human-readable format.
```
When I rename the 'address' to 'address_to_hex'

Then print 'address_to_hex' as 'hex'
```
```json
{
   "address_to_hex": "537472696e6720746f20656e636f6465"
}
```

## bin
Binary encoding represents data using only two symbols: 0 and 1. Each byte is converted into an 8-bit sequence, making it easy for computers to process but less human-readable. This encoding is fundamental in computing, as all digital data is ultimately stored and processed in binary form.

```
When I rename the 'address' to 'address_to_bin'

Then print 'address_to_bin' as 'bin'
```

```json
{
   "address_to_bin:": "01010011011101000111001001101001011011100110011100100000011101000110111100100000011001010110111001100011011011110110010001100101"
}
```


## base32
Base32 encoding represents binary data using 32 ASCII characters (A-Z, 2-7). Output is padded with '=' to make the total length a multiple of 8 characters.

```
When I rename the 'address' to 'address_to_base32'

Then print 'address_to_base32' as 'base32'
```

```json
{
   "address_to_base32": "KN2HE2LOM4QHI3ZAMVXGG33EMU======"
}
```

## base32 crockford
Base32 Crockford is a human-friendly encoding using digits 0–9 and letters A–Z (excluding I, L, O, and U), designed for readability, error tolerance, and optional checksum support. The checksum uses 37 possible characters: 0–9 and A–Z (excluding I, L, and O) plus *, ~, $, =.

```
When I rename the 'address' to 'address_to_base32crockford'

Then print 'address_to_base32crockford' as 'base32crockford'
```

```json
{
   "address_to_base32crockford": "ADT74TBECWG78VS0CNQ66VV4CM"
}
```

## uuid
A UUID (Universally Unique Identifier) is a 16-byte identifier used to uniquely label information in computer systems. It is typically represented as a 32-character hexadecimal string, divided into five groups separated by hyphens (e.g., 123e4567-e89b-12d3-a456-426614174000).

Consider the following 16-byte base64 string

```json
{
   "data": "VQ6EAOKbQdSnFkRmVUQAAA=="
}
```
and the script

```
Given I have a 'base64' named 'data'
Then print the 'data' as 'uuid'
```
the output will be

```json
{
   "data":"550e8400-e29b-41d4-a716-446655440000"
}
```
