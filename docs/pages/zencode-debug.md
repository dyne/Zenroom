# The *debug* operators

Looking back at the previous paragraphs, you may be wondering what happens exactly inside Zenroom's virtual machine and - more important - how to peep into it. The *Debug operators* address this precise issue: they are a wildcard, meaning that they can be used in any phase of the process. You may for example place it at the end of the Given phase, in order to see what data has the virtual machine actually imported. These are the *Debug operators* that you can use:

- *backtrace*
- *codec*
- *config*
- *debug*
- *schema*
- *trace*

In order to understand better in what they differ we will test them on the same script and with the same input:
- input:

[](../_media/examples/zencode_cookbook/cookbook_debug/input.json ':include :type=code json')

- script:

[](../_media/examples/zencode_cookbook/cookbook_debug/main_script.zen ':include :type=code gherkin')

## Backtrace and Trace
The **backtrace** and **trace** operators are the same commands. These commands print, as warning, the stack traces, i.e. a report of Zenroom's internal processing operations. In order to understand it better let see an example.

[](../_media/examples/zencode_cookbook/cookbook_debug/backtrace_script.zen ':include :type=code gherkin')

And at screen we can see the following warnings messages:
```bash
[W]  .  Scenario 'eddsa'
[W]  .  Scenario 'schnorr'
```
That means that Zenroom has loaded the [EdDSA](zencode-scenarios-eddsa.md) and [Schnorr](zencode-scenarios-schnorr.md)'s scenarios. This result is obtained by using the [debug level](zenroom-config.md) equal to 1, increasing it to 2 we will also see if the loading of the objects in the *Given phase* was successful.


## Codec
The **codec** command print to screen the encoding specification for each item specified from the beginning of the script to the point where it is deployed. For example the following script:

[](../_media/examples/zencode_cookbook/cookbook_debug/codec_script.zen ':include :type=code gherkin')

will prompt to the screen the following warning message:
```bash
[W] {
    CODEC = {
        eddsa_public_key = {
            encoding = "base58",
            luatype = "userdata",
            name = "eddsa_public_key",
            zentype = "element"
        },
        keyring = {
            encoding = "complex",
            luatype = "table",
            name = "keyring",
            zentype = "schema"
        },
        schnorr_public_key = {
            luatype = "userdata",
            name = "schnorr_public_key",
            zentype = "element"
        }
    }
}
```

From these information for example we can see that the EdDSA public key is encoded as base58, while the Keyring as a complex encoding because the keys inside it have different encoding, finally we can see that the Schnorr public key has no encoding and this is due to the fact that it uses base64 encoding that is the default inside Zenroom so there is no need to specify it.

## Config

The **config** command print to screen the configuration under which Zenroom is running. For example the following script:

[](../_media/examples/zencode_cookbook/cookbook_debug/config_script.zen ':include :type=code gherkin')

will prompt to the screen the following warning message:
```bash
[W] {
    debug = {
        encoding = {
            fun = <function 1>,
            name = "hex"
        }
    },
    hash = "sha256",
    heap = {
        check_collision = true
    },
    heapguard = true,
    input = {
        encoding = {
            check = <function 2>,
            encoding = "base64",
            fun = <function 3>
        },
        format = {
            fun = <function 4>,
            name = "json"
        },
        tagged = false
    },
    output = {
        encoding = {
            fun = <function 5>,
            name = "base64"
        },
        format = {
            fun = <function 4>,
            name = "json"
        },
        versioning = false
    },
    parser = {
        strict_match = true
    }
}
```

This, for example, tell us that the default settings are:
- the output of the debug command is encoded as hex;
- the hash function is SHA256;
- the input and output encoding is base64 and in JSON format.


## Schema

The **schema** command print to screen all the schemes in the heap and the keys inside it, but not the value. For example the following script:

[](../_media/examples/zencode_cookbook/cookbook_debug/debug_script.zen ':include :type=code gherkin')

will prompt to the screen the following warning message:

```bash
[W] {
    SCHEMA = {
        ACK = {
            eddsa_public_key = octet[32] ,
            keyring = {
                eddsa = octet[32] ,
                schnorr = octet[32] 
            },
            schnorr_public_key = octet[48] 
        },
        IN = {},
        KIN = {},
        OUT = {},
        TMP = {}
    }
}
```

Where **IN** and **KIN** represent the *Given phase* (respectively data and keys), **ACK** the *When phase*, **OUT** the *Then phase* and **TMP** is a temporary memory where data in input is allocated before being validated and moved to the **ACK** memory. In the above example we can see that in the *When phase* we have a 32 bytes EdDSA public key, the keyring containing the 32 bytes EdDSA and Schnorr keys and a 32 bytes Schnorr public key. They are all stored as octet because Zenroom converts all data to an internal encoding, called *octet*, when processing it and converts it back to the data original encoding when the output is being generated. Moreover you can see that the **IN** and **KIN** memories are empty, this is due to the fact that as soon as the *When phase* is reached the *Zenroom Garbage collector* clears this two piece of memory since they will not be used anymore.


## Debug

The **debug** command is the most powerful one, it performs the *backtrace* command and a version of the *schema* command that print also the value and not only the keys. For example the following script:

[](../_media/examples/zencode_cookbook/cookbook_debug/debug_script.zen ':include :type=code gherkin')

will prompt to the screen the following warning messages:

```bash
[W]  .  Scenario 'eddsa'
[W]  .  Scenario 'schnorr'
[W] {
    a_GIVEN_in = {},
    b_GIVEN_in = {},
    c_WHEN_ack = {
        eddsa_public_key = octet[32] a53e7a70bd4002f76734039399a1b57322ed7c8295576d0ee14a9430e3fa4ab0,
        keyring = {
            eddsa = octet[32] ac3127d66c12bd6635a6d3486d48ee83616d053e78b3a2b0b4e4af947a9ea806,
            schnorr = octet[32] 5dd8c0623f9163de7ebb260c23c7d1dfe7e63f92f241a379e2fc934d52b16720
        },
        schnorr_public_key = octet[48] 051f7c0e1e97325df15f074b0f6fac9a1390c828c19449cbc4c57a574b51581501a092c05acd56100819da76e1768521
    },
    d_THEN_out = {}
}

```

# The script used to create the material in this page

All the smart contracts and the data you see in this page are generated by the scripts [cookbook_debug.sh](https://github.com/dyne/Zenroom/blob/master/test/zencode/cookbook_debug.sh) . If you want to run the scripts (on Linux) you should: 
 - *git clone https://github.com/dyne/Zenroom.git*
 - install **zsh** and **jq**
 - download a [zenroom binary](https://zenroom.org/#downloads) and place it */bin* or */usr/bin* or in *./Zenroom/src*
