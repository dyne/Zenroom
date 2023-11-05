# Embedding Zenroom

Zenroom is designed to facilitate embedding into other native applications and high-level scripting languages. The stable releases distribute compiled library components for Apple/iOS and Google/Android platforms, as well MS/Windows DLL, Apple/OSX shared library and Javascript/WASM.

To call Zenroom from an host program is very simple: there isn't an API to learn, but a single call to execute scripts and return their results. The call is called `zencode_exec` and prints results to the "stderr/stdout" terminal output. It will work more or less the same everywhere:

```c
int zencode_exec(char *script,
                 char *conf,
				 char *keys,
                 char *data);
```
The input string buffers will not be modified by the call, they are:
- `script`: the [Zencode script](https://dev.zenroom.org/#/pages/zencode-cookbook-intro) to be executed
- `conf`: a series of comma separated key=value pairs
- `keys`: JSON formatted data passed as input to the script
- `data`: JSON formatted data passed as input to the script

This is all you need to know to start using Zenroom in your software, to try it out you may want to jump directly to the [specific instructions for language bindings](https://dev.zenroom.org/#/pages/how-to-embed?id=language-bindings).

Here can you find the latest [zenroom.h header file](https://github.com/dyne/Zenroom/blob/master/src/zenroom.h)

## Configuration directives

The list of accepted configurations in `conf` argument are:

- `debug` is the level of log verbosity, default is `debug=1`
- `rngseed` is used to provide an external random seed for fully deterministic behaviour, it accepts an hexadecimal string representing a series of 64 bytes (128 chars in total) prefixed by `hex:`. For example: `rngseed=hex:000000...` up to 128 zeroes
- `logfmt` is the format of the error logs, it can be `text` or `json`, the default is `logfmt=text` of `logfmt=json` when using Zenroom from bindings.

## Parsing the stderr output

The control log (stderr output channel) is a simple array (json or newline terminated according to `logfmt`) sorted in chronological order. The nature of the logged events can be detected by parsing the first 3 chars of each entry:
- `[*]` is a notification of success
- ` . ` is execution information
- `[W]` is a warning
- `[!]` is a fatal error
- `[D]` is a verbose debug information when switched on with conf `debug=3`
- `+1 ` and other decimal numbers indicate the Zencode line being executed
- `-1 ` and other decimal numbers indicate the Zencode line being ignored
- `J64` followed by HEAP or TRACE indicate a base64 encoded JSON dump

## Extended API

In addition to the main `zencode_exec` function there is another one that copies results (error messages and printed output) inside memory buffers pre-allocated by the caller, instead of stdin and stdout file descriptors:
```c
int zencode_exec_tobuf(char *script, char *conf,
                       char *keys,   char *data,
                       char *stdout_buf, size_t stdout_len,
                       char *stderr_buf, size_t stderr_len);
```
The new arguments are:
- `stdout_buf`: pre-allocated buffer where to write data output
- `stdout_len`: maximum length of the data output buffer
- `stderr_buf`: pre-allocated buffer where to write error logs
- `stderr_len`: maximum length of the error logs buffer

More internal functions are made available to C/C++ applications, breaking up the execution in a typical init / exec / teardown sequence:

```c
zenroom_t *zen_init(const char *conf, char *keys, char *data);
int  zen_exec_zencode(zenroom_t *Z, const char *script);
void zen_teardown(zenroom_t *zenroom);
```

In addition to these calls there is also one that allows to execute directly a limited set of Lua instructions using the Zenroom VM, excluding those accessing network and filesystem (`os` etc.)
```c
int zen_exec_script(zenroom_t *Z, const char *script);
```

For more information see the [Zenroom header file](https://github.com/dyne/Zenroom/blob/master/src/zenroom.h) which is the only header you'll need to include in an application linking to the Zenroom static or shared library.

## Advanced API usage

This section lists some of the advanced API calls available, they are
implemented to facilitate some specific use-cases and advanced
applications embedding Zenroom.

### Input Validation

A caller application using Zenroom may want to have more information about the input data accepted by a Zencode script before executing it. Input validation can be operated without executing the whole script by calling `zencode_exec` using a special configuration directive: `scope=given`.

The output of input validation consists of a "`CODEC`" dictionary documenting all expected input by the `Given` section of a script, including data missing from the current input. The `CODEC` is in JSON format and consists of:

- `n`ame = key name of the data
- `r`oot = name of the parent object if present
- `s`chema = scenario specific schema for data import/export
- `e`ncoding = can be `hex`, `base64`, `string`, `base58`, etc.
- `l`uatype = type of value in Lua: `table`, `string`, `number`, etc.
- `z`entype = kind of value: `a`rray, `d`ictionary, `e`lement or `s`chema
- `b`intype = the zenroom binary value type: `octet`, `ecp`, `float`, etc.
- `m`issing = true if the input value was not found and just expected

Each data object will have a corresponding `CODEC` entry describing it
when using input validation: the entry will be part of a dictionary
and its name will be used as key.

### Direct Hash calls

Zenroom offers direct API calls to certain basic cryptographic functions, so that calling applications can run them without the need to initialize the whole VM. These calls are much faster than executing a Zencode script.

All direct API calls return 0 on success, anything else is an error.

All their input arguments are encoded string values.

Their output result is always an encoded string value.

```c
// hash_type may be one of these two strings: 'sha256' or 'sha512'
int zenroom_hash_init(const char *hash_type);

// hash_ctx is the string returned by init
// buffer is an hex encoded string of the value to be hashed
// buffer_size is the size in bytes of the value to be hashed
int zenroom_hash_update(const char *hash_ctx, const char *buffer, const int buffer_size);

// the final call will print the base64 encoded hash of the input data
int zenroom_hash_final(const char *hash_ctx);
```
