# Zencode command list

Start reading here to understand how Zencode smart contracts are written and the philosophy behind the technology. 

# Smart contract setup

First we'll look at **phases, scenarios, rules and configuration**.

*Phases*: let's rememeber that Zencode contracts operate in 3 phases:

1. **Given** - validates the input
2. **When** - processes the contents
3. **Then** - prints out the results

So each Zencode smart contract will contain at least three lines, each begining with one of the 3 keywords, in the given order.

## Scenarios

Scenarios are set in the beginning of a script and they make Zenroom use a certain set of rules to interpretate the Zencode contained in the smart contract. Different scenarios will typically contain different keywords. The syntax to set a scenario is: 

```gherkin
   Scenario 'simple': Create the keypair
```

The scenario setting happens before the ```:```, everything right of that isn't processed by Zenroom and can be used as a title to the smart contract. 

## Rules

Rules are *optional*, they are used to define input and output formats of the smart contract, they have to be set after the scenario and before the rest of the smart contracts. Current rules: 

```txt
rule input encoding [ url64 | base64 | hex | bin ]
rule input format [ json | cbor ]
```

For example, a valid config is: 

```gherkin
rule input encoding hex
rule output encoding hex
```

A rule can be set also check that Zenroom is at a certain version: if the rule is not satisfied, Zenroom will stop. 

```gherkin
   rule check version 1.0.0
```

## Configurations 

You can pass to Zenroom a configuration file, using the parameter ```-c```, description will follow soon.

---

# *Given*

This affects **my** statements

```gherkin
   Given I introduce myself as ''
   Given I am known as ''
   Given I am ''
   Given I have my ''
   Given I have my valid ''
```

Data provided as input (from **data** and **keys**) is all imported
automatically from **JSON** or [CBOR](https://tools.ietf.org/html/rfc7049) binary formats.

Scenarios can add Schema for specific data validation mapped to **words** like: **signature**, **proof** or **secret**.


**Data input**
```gherkin
   Given I have a ''
   Given I have a valid ''
   Given I have a '' inside ''
   Given I have a valid '' inside ''
   Given I have a '' from ''
   Given I have a valid '' from ''
   Given the '' is valid
```

or check emptiness:

```gherkin
   Given nothing
```

all the list of valid `given` statements are:

[](../_media/zencode_utterances.yaml ':include :fragment=given :type=code yaml')


When **valid** is specified then extra checks are made on input value,
mostly according to the **scenario**


# *When*

Processing data is done in the when block. Also scenarios add statements to this block.

Without extensions, these are the basic functions available

[](../_media/zencode_utterances.yaml ':include :fragment=when :type=code yaml')

with the `simple` extension the following statementa are valid

[](../_media/zencode_utterances.yaml ':include :fragment=simple_when :type=code yaml')

with the `coconut` extension the following statementa are valid

[](../_media/zencode_utterances.yaml ':include :fragment=coconut_when :type=code yaml')

# *Then*

Output is all exported in JSON or CBOR

[](../_media/zencode_utterances.yaml ':include :fragment=then :type=code yaml')

Settings:
```txt
rule output encoding [ url64 | base64 | hex | bin ]
rule output format [ json | cbor ]
```
