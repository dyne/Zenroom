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

## Configuration directives

The list of accepted configurations in `conf` argument are:

- `debug` is the level of log verbosity, default is `debug=1`
- `rngseed` is used to provide an external random seed for fully deterministic behaviour, it accepts an hexadecimal string representing a series of 64 bytes (128 chars in total) prefixed by `hex:`. For example: `rngseed=hex:000000...` up to 128 zeroes
- `logfmt` is the format of the error logs, it can be `text` or `json`, the default is `logfmt=text`

## Extended API

In addition to the main `zencode_exec` function there is another one that copies results (error messages and printed output) inside memory buffers pre-allocated by the caller, instead of stdin and stdout file descriptors:
```c
int zenroom_exec_tobuf(char *script, char *conf,
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

# Language bindings

This API can be called in similar ways from a variety of languages and wrappers that already facilitate its usage.

# Zenroom header file

Here can you find the latest [zenroom.h header file](https://github.com/dyne/Zenroom/blob/master/src/zenroom.h), remember to add *#include <stddef.h>*.

## Javascript


💾 Installation
```
npm install zenroom
```

🎮 Quick Usage

```javascript
const {zenroom_exec} = require("zenroom");
const script = `print("Hello World!")`
zenroom_exec(script).then(({result}) => console.log(result)) //=> "Hello World!"
```

Detailed documentation of js is available [here](/pages/javascript)

Tutorials on how to use the zenRoom in the js world
  * [Node.js](/pages/zenroom-javascript1)
  * [Browser](/pages/zenroom-javascript2)
  * [React](/pages/zenroom-javascript3)

🌐 [Javascript NPM package](https://www.npmjs.com/package/zenroom)


<!-- Outdated
 

## Python


💾 Installation
```
pip install zenroom
```

🎮 Quick Usage

```python
from zenroom import zenroom

script = "print('Hello world!')"
result = zenroom.zenroom_exec(script)
print(result.stdout) # guess what
```

Detailed documentation of python bindings are available [here](/pages/javascript)

🌐 [Python package on Pypi](https://pypi.org/project/zenroom/)

## Golang


💾 Installation
```
import "github.com/dyne/Zenroom/tree/master/bindings/golang/zenroom"
```

🎮 Quick Usage

```go
script := []byte(`print("Hello World!")`)
res, _ := zenroom.Exec(script)
fmt.Println(string(res))
```

[Go language bindings](https://godoc.org/github.com/dyne/Zenroom/bindings/golang/zenroom)

-->
