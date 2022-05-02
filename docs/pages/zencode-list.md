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
   rule check version 2.0.0
```

## Configurations 

You can pass to Zenroom a configuration file, using the parameter ```-c```, description will follow soon.

---

# *Given*

There are different ways to state who you are in order to use **my** statements later

```gherkin
   Given I am ''
   Given my name is in a '' named ''
   Given my name is in a '' named '' in ''
```

Data provided as input (from **data** and **keys**) is all imported
automatically from **JSON** or [CBOR](https://tools.ietf.org/html/rfc7049) binary formats.
There can also be no input to the code, in this case can be checked the emptiness with:

```gherkin
   Given nothing
```

Scenarios can add Schema for specific data validation mapped to **words** like: **signature**, **proof** or **secret**.

All the valid `given` statements are:

[](../_media/zencode_utterances_reworked.yaml ':include :fragment=given :type=code gherkin')


When **valid** is specified then extra checks are made on input value,
mostly according to the **scenario**


# *When*

Processing data is done in the when block. Also scenarios add statements to this block.

## Basic

Without extensions, all the following statementes are valid:

- basic functions

[](../_media/zencode_utterances_reworked.yaml ':include :fragment=when :type=code gherkin')
- array functions

[](../_media/zencode_utterances_reworked.yaml ':include :fragment=array :type=code gherkin')
- bitcoin functions

[](../_media/zencode_utterances_reworked.yaml ':include :fragment=bitcoin :type=code gherkin')
- debug functions

[](../_media/zencode_utterances_reworked.yaml ':include :fragment=debug :type=code gherkin')
- dictionary functions

[](../_media/zencode_utterances_reworked.yaml ':include :fragment=dictionary :type=code gherkin')
- hash functions

[](../_media/zencode_utterances_reworked.yaml ':include :fragment=hash :type=code gherkin')
- keyring functions

[](../_media/zencode_utterances_reworked.yaml ':include :fragment=keyring :type=code gherkin')
- random functions

[](../_media/zencode_utterances_reworked.yaml ':include :fragment=random :type=code gherkin')
- verify functions

[](../_media/zencode_utterances_reworked.yaml ':include :fragment=verify :type=code gherkin')

## Extensions

Each of the following scenario enable a set of sentences:
- `credential`

[](../_media/zencode_utterances_reworked.yaml ':include :fragment=credential :type=code gherkin')
- `dp3t`

[](../_media/zencode_utterances_reworked.yaml ':include :fragment=dp3t :type=code gherkin')
- `ecdh`

[](../_media/zencode_utterances_reworked.yaml ':include :fragment=ecdh :type=code gherkin')
- `ethereum`

[](../_media/zencode_utterances_reworked.yaml ':include :fragment=ethereum :type=code gherkin')
- `http`

[](../_media/zencode_utterances_reworked.yaml ':include :fragment=http :type=code gherkin')
- `petition`

[](../_media/zencode_utterances_reworked.yaml ':include :fragment=petition :type=code gherkin')
- `qp`

[](../_media/zencode_utterances_reworked.yaml ':include :fragment=qp :type=code gherkin')
- `reflow`

[](../_media/zencode_utterances_reworked.yaml ':include :fragment=reflow :type=code gherkin')
- `schnorr`

[](../_media/zencode_utterances_reworked.yaml ':include :fragment=schnorr :type=code gherkin')
- `secshare`

[](../_media/zencode_utterances_reworked.yaml ':include :fragment=secshare :type=code gherkin')
- `w3c`

[](../_media/zencode_utterances_reworked.yaml ':include :fragment=w3c :type=code gherkin')



# *Then*

Output is all exported in JSON or CBOR

[](../_media/zencode_utterances_reworked.yaml ':include :fragment=then :type=code gherkin')

Settings:
```txt
rule output encoding [ url64 | base64 | hex | bin ]
rule output format [ json | cbor ]
```
