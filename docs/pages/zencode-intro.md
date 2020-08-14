# Zencode in a nutshell

Zenroom's development is heavily inspired by the [language-theoretical security](http://langsec.org) research and the [BDD Language](https://en.wikipedia.org/wiki/Behavior-driven_development). 

# Smart contracts in *human* language

Zenroom can execute smart contracts written in the  domain-specific language **Zencode**, which reads in a [natural English-like fashion](https://decodeproject.eu/blog/smart-contracts-english-speaker), and allows to perform cryptographic operations as long as more traditional data manipulation.

For the theoretical background see the [Zencode Whitepaper](https://files.dyne.org/zenroom/Zencode_Whitepaper.pdf).

Here we go with the <span class="big">**tutorial to learn the Zencode language!**</span>

# Introduction

Zencode contracts operate in 3 phases:

1. **Given** - validates the input
2. **When** - processes the contents
3. **Then** - prints out the results

The 3 separate blocks of code also correspond to 3 separate memory areas, sealed by security measures.

If any single line in a Zencode contract fails, Zenroom stops executing and returns the error.

![Zencode documentation diagram](../_media/images/zencode_diagram.png)

All data processed has first to pass the validation phase according to scenario specific data schemas.

<span class="mdi mdi-lightbulb-on-outline"></span>
**Good Practice**: start your Zencode noting down the Zenroom version you are using!

```
rule check version 1.0.0
```

---