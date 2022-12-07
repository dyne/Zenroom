## Usage

Zenroom configuration is used to set some application wide parameters at initialization time. The configuration is passed as a parameter (not as file!) using the "-c" option, or as a parameter if Zenroom is used as lib. You can pass Zenroom several attributes, wrapped in quotes and separated by a comma, as in the example below: 

```shell
zenroom -z keypair.zen -c "debug=3, rngseed=hex:74eeeab870a394175fae808dd5dd3b047f3ee2d6a8d01e14bff94271565625e98a63babe8dd6cbea6fedf3e19de4bc80314b861599522e44409fdd20f7cd6cfc"
```

Below a list of the config parameters with a description and usage examples.

## Debug verbosity

### Syntax and values: **debug=1, 2, 3**

Define the verbosity of Zenroom's output, bug reports need to be sent with "debug=3"



## Color

### Syntax and values: **color=1, 0**

Defines color from printout log, "color=0" removes colors.


## Seccomp (CLI isolation)

### Syntax and values: **seccomp=0, 1**

Secure execution isolation for the CLI: separates the CLI to the OS kernel, file system and network in a provable way. Works only in Linux.



## Random seed

### Syntax and values: **rngseed=hex:[64 bytes in hex notation]**

Loads a random seed at start, that will be used through the Zenroom execution whenever a random seed is requested. A fixed random can be used to test determinism. For example, when generating an ECDH keypair, using:


```shell
rngseed=hex:74eeeab870a394175fae808dd5dd3b047f3ee2d6a8d01e14bff94271565625e98a63babe8dd6cbea6fedf3e19de4bc80314b861599522e44409fdd20f7cd6cfc
```

Should always generate the keypair:

```json
  {
  "Alice": {
    "keypair": {
      "private_key": "Aku7vkJ7K01gQehKELav3qaQfTeTMZKgK+5VhaR3Ui0=",
      "public_key": "BBCQg21VcjsmfTmNsg+I+8m1Cm0neaYONTqRnXUjsJLPa8075IYH+a9w2wRO7rFM1cKmv19Igd7ntDZcUvLq3xI="
    }
  }

}
```  
  
## Limit iterations

### Syntax and values: **maxiter=dec:[at most 10 decimal digits]**

Define the maximum number of iterations the contract is allowed to do.


## Memory manager
### Syntax and values: **memmanager=sys, lw, je**

Switch the use of a different memory manager, between: 

- **sys**: system memory manager
- **lw**: "lightweight" memory manager, internal to Zenroom, can be more performant on some situation and required when running Zenroom on embedded systems with RTOS, baremetal or situations where there is no memory manager offered by the OS 
- **je**: experimental memory manager based on "jemalloc", safe and fast alternative supported by some OS.

## Print output
### Syntax and values: **print=sys, stb**

Defines the function used to print the output.

- **sys** = uses system defined print, typically "sprintf" or "vsprintf"
- **stb** = internal print function based on [stb](https://github.com/nothings/stb) to be used with on embedded systems with RTOS, baremetal
