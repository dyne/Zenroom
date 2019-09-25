<p align="center">
  <br/>
  <a href="https://zenroom.dyne.org/">
    <img src="https://cdn.jsdelivr.net/gh/DECODEproject/zenroom@master/docs/logo/zenroom.svg" height="140" alt="Zenroom">
  </a>
  <h1 align="center">
    zenroom.py 🐍
    <br>
    <sub>A python wrapper for Zenroom</sub>
  </h1>

  <a href="https://travis-ci.com/DECODEproject/zenroom-py">
    <img src="https://travis-ci.com/DECODEproject/zenroom-py.svg?branch=master" alt="Build status"/>
  </a>
  <a href="https://codecov.io/gh/DECODEproject/zenroom-py">
    <img src="https://codecov.io/gh/DECODEproject/zenroom-py/branch/master/graph/badge.svg" alt="Code coverage"/>
  </a>
  <a href="https://pypi.org/project/zenroom/">
    <img alt="PyPI" src="https://img.shields.io/pypi/v/zenroom.svg" alt="Latest release">
  </a>
</p>

<hr/>


This library attempts to provide a very simple wrapper around the Zenroom
(https://zenroom.dyne.org/) crypto virtual machine developed as part of the
DECODE project (https://decodeproject.eu/), that aims to make the Zenroom
virtual machine easier to call from normal Python code.

This library has been developed for a specific deliverable within the project,
and as such will likely not be suitable for most people's needs. Here we
directly include a binary build of Zenroom compiled only for Linux (amd64), so
any other platforms will be unable to use this library. This library has also
only been tested under Python 3.

Zenroom itself does have good cross platform functionality, so if you are
interested in finding out more about the functionalities offered by Zenroom,
then please visit the website (https://dev.zenroom.org/) find out more.


<details>
 <summary><strong>🚩 Table of Contents</strong> (click to expand)</summary>

* [Installation](#floppy_disk-installation)
* [Usage](#video_game-usage)
* [Testing](#clipboard-testing)
* [Links](#globe_with_meridians-links)
</details>


***
## 💾 Installation

```bash
pip install zenroom
```

**NOTE** - the above command attempts to install the zenroom package, pulling in
the Zenroom VM as a precompiled binary, so will only work on Linux (amd64) and macOS
machines.


***
## 🎮 Usage

Two main calls are exposed `zencode_exec` and `zenroom_exec`, one to run
`zencode` and one for `zenroom scripts` as names suggest.
The names follow the standard Zenroom naming as per Zenroom documentation.

If you don't know what `zencode` is, you can start with this blogpost
https://decodeproject.eu/blog/smart-contracts-english-speaker

A good set of examples of `zencode` contracts could be found
(https://github.com/DECODEproject/Zenroom/tree/master/test/zencode_simple)[here]
and
(https://github.com/DECODEproject/Zenroom/tree/master/test/zencode_coconut)[here].

The complete documentation about `zencode` is available on
http://dev.zenroom.org/zencode

### ZENCODE

Here a quick usage example:

```python
from zenroom import zenroom

contract = """Scenario 'coconut': "To run over the mobile wallet the first time and store the output as keypair.keys"
Given that I am known as 'identifier'
When I create my new keypair
Then print all data
    """

result = zenroom.zencode_exec(contract)
print(result.stdout)
```

The zencode function accepts the following:

 * `script` (str): Required byte string or string containing script which Zenroom will execute
 * `keys` (str): Optional byte string or string containing keys which Zenroom will use
 * `data` (str): Optional byte string or string containing data upon which Zenroom will operate
 * `conf` (str): Optional byte string or string containing conf data for Zenroom
 * `verbosity` (int): Optional int which controls Zenroom's log verbosity ranging from 1 (least verbose) up to 3 (most verbose)

Returns

 * an object (#ZenroomResult)[ZenroomResult] that is a facility to access the `stdout` and `stderr`
   result from the execution of the script

### ZENROOM SCRIPTS

```python
from zenroom import zenroom

script = "print('Hello world')"
output, errors = zenroom.zenroom_exec(script)

print(output)
```

The same arguments and the same result are applied as the `zencode` call.

### ZenroomResult

This is a facility object that allows to acces the output result of the
execution of zen{code,room}_exec commands.

Each time zenroom and zencode are executed stdout and stderr will be filled
accordingly and a code is returned (`0` for success and `1` if errored).

The following methods and properties are available:

#### stdout

This property contains all the output printing from the script/zencode run

#### stderr

This property contains all the content going to stderr that contains debug info
and or stacktrace of the script/zencode run

#### has_error()

Returns `True` or `False` based on the return code of the zen{room,code}_exec calls

#### get_warnings()

Filters the warning messages from the `stderr`

#### get_errors()

Filters the error messages from the `stderr`

#### get_debug()

Filters the debug messages from the `stderr`

#### get_info()

Filters the info messages from the `stderr`


## 📋 Testing

Tests are made wuth pytests, just run 

`python setup.py test`

***
## 🌐 Links

https://decodeproject.eu/

https://zenroom.org/
