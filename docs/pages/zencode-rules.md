# Zencode *rules*

Rules in Zencode are directives that influence the whole computation of the script. Rules can be written before or after the 'Scenario' directive(s) but always before the first 'Given' statement


# Rule input/output encode: setting encoding for the whole script

When processing the output, Zenroom will use the own encoding of the object. 
This can be overriden by using the ***Rule output encoding*** statement, for example the line:

```gherkin
Rule output encoding hex
```
will get all the output to be printed as *hex*, which may come in handy when working with cryptography.

You can also redefine the input encoding, which would work only with ***schemas*** whose encoding is pre-defined. This will be again useful mostly when working with cryptography. For example the statement:

```gherkin
Rule input encoding base58 
```
Will assume the schemas imported are encoded in base58 and load them accordingly.



# Rule check version

The ***rule check version*** statement, will validate the script's syntax to make sure it matches the Zencode version stated. Not using the line in the beginning of each script will cause a warning. You can use the statement like this:

```gherkin
rule check version 1.0.0
```

# Rule input/output format: using JSON or CBOR

Zenroom's default file format is JSON, but it can also manage CBOR. You can switch between the two by using the ***rule format*** statement, like for example: 

```gherkin
Rule input format CBOR
Rule output format JSON
```

This two statements will make sure that CBOR data is imported, and then the output is printed in JSON. 