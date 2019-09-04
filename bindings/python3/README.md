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
then please visit the website linked to above to find out more.


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
the Zenroom VM as a precompiled binary, so will only work on Linux (amd64)
machines.


***
## 🎮 Usage

Two main calls are exposed, one to run `zencode` and one for `zenroom scripts`.

If you don't know what `zencode` is, you can start with this blogpost
https://decodeproject.eu/blog/smart-contracts-english-speaker

A good set of examples of `zencode` contracts could be found here
https://github.com/DECODEproject/dddc-pilot-contracts 

### ZENCODE

Here a quick usage example:

```python
from zenroom import zenroom

contract = """Scenario 'coconut': "To run over the mobile wallet the first time and store the output as keypair.keys"
Given that I am known as 'identifier'
When I create my new keypair
Then print all data
    """

result, errors = zenroom.zencode_exec(contract)
print(result)
```

**NOTE** The result is in `bytes` and not string if you want a string you want to `.decode()` it

The zencode function accepts the following:

 * `script` (str): Required byte string or string containing script which Zenroom will execute
 * `keys` (str): Optional byte string or string containing keys which Zenroom will use
 * `data` (str): Optional byte string or string containing data upon which Zenroom will operate
 * `conf` (str): Optional byte string or string containing conf data for Zenroom
 * `verbosity` (int): Optional int which controls Zenroom's log verbosity ranging from 1 (least verbose) up to 3 (most verbose)

Returns

 * tuple: The output from Zenroom expressed as a byte string, the eventual errors generated as a string

### ZENROOM SCRIPTS

```python
from zenroom import zenroom

script = "print('Hello world')"
output, errors = zenroom.zenroom_exec(script)

print(output)
```

The same arguments and the same result are applied as the `zencode` call.

***
## 📋 Testing

Tests are made wuth pytests, just run 

`python setup.py test`

***
## 🌐 Links

https://decodeproject.eu/

https://zenroom.org/
