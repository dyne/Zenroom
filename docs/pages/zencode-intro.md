# The Zenroom's virtual machine

At each run, Zenroom starts a **virtual machine** (VM) that is completely isolated from the operating system, has no access to the file system, is stateless and [fully deterministic](/pages/random). During operation, Zenroom's memory is heavily fenced and it gets wiped when Zenroom shuts down.

The Zenroom VM then executes smart contracts in the  domain-specific language **Zencode** and in Lua.


# Smart contracts in *human* language

The domain-specific language **Zencode** reads in a [natural English-like fashion](https://decodeproject.eu/blog/smart-contracts-english-speaker), and allows to perform cryptographic operations as long as more traditional data manipulation.

Zencode is heavily inspired by the [language-theoretical security](http://langsec.org) research and the [BDD Language](https://en.wikipedia.org/wiki/Behavior-driven_development). 

For the theoretical background see the [Zencode Whitepaper](https://files.dyne.org/zenroom/Zencode_Whitepaper.pdf).


# The 3 phases of Zencode execution

the Zenroom virtual machine that executes **Zencode** smart contracts operate in 3 phases:

1. **Given** - loads and validates the input
2. **When** - performs the computing
3. **Then** - prints out the output

The 3 separate blocks of code also correspond to 3 separate memory areas, sealed by security measures. 

If any single line in a Zencode contract fails, Zenroom stops executing and returns the error.

![Zencode documentation diagram](../_media/images/zencode_diagram.png)

All data processed has first to pass the validation phase according to scenario specific data schemas.
