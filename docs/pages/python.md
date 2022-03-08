# Use Zenroom in Python3
<p align="center">
  <br/>
  <a href="https://dev.zenroom.org/">
    <img src="https://dev.zenroom.org/_media/images/zenroom_logo.png" height="140" alt="Zenroom">
  </a>
  <h2 align="center">
    zenroom.py 🐍
    <br>
    <sub>A Python3 wrapper of <a href="https://zenroom.org">Zenroom</a>, a secure and small virtual machine for crypto language processing</sub> </h2>
  
<br><br>

  <a href="https://travis-ci.com/dyne/zenroom-py">
    <img src="https://travis-ci.com/dyne/zenroom-py.svg?branch=master" alt="Build status"/>
  </a>
  <a href="https://codecov.io/gh/dyne/zenroom-py">
    <img src="https://codecov.io/gh/dyne/zenroom-py/branch/master/graph/badge.svg" alt="Code coverage"/>
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

Zenroom itself does have good cross platform functionality, so if you are
interested in finding out more about the functionalities offered by Zenroom,
then please visit the website linked to above to find out more.


***
## 💾 Installation

```bash
pip install zenroom
```

**NOTE** - the above command attempts to install the zenroom package, pulling in
the Zenroom VM as a precompiled binary, so will only work on Linux and macOS
machines.

for the edge (syn to the latest commit on master) version please run:
```bash
pip install zenroom --pre
```


***
## 🎮 Usage

Two main calls are exposed, one to run `zencode` and one for `zenroom scripts`.

If you don't know what `zencode` is, you can start with this blogpost
https://decodeproject.eu/blog/smart-contracts-english-speaker
The official documentation is available on [https://dev.zenroom.org/zencode/](https://dev.zenroom.org/zencode/)

A good set of examples of `zencode` contracts could be found on
* [zencode simple tests](https://github.com/dyne/Zenroom/tree/master/test/zencode_simple)
* [zencode coconut tests](https://github.com/dyne/Zenroom/tree/master/test/zencode_coconut)


### 🐍 Python wrapper

the wrapper exposes two simple calls:

* `zenroom_exec`
* `zencode_exec`

as the names suggest are the two methods to execute zenroom (lua scripts) and zencode.

#### args
Both functions accept the same arguments:

- `script` **[string](https://docs.python.org/3/library/stdtypes.html#text-sequence-type-str)** the lua script or
 the zencode script to be executed
- `keys` **[string](https://docs.python.org/3/library/stdtypes.html#text-sequence-type-str)** the optional keys
 string to pass in execution as documented in zenroom docs [here](https://dev.zenroom.org/wiki/how-to-exec/#keys-string)
- `data` **[string](https://docs.python.org/3/library/stdtypes.html#text-sequence-type-str)** the optional data
 string to pass in execution as documented in zenroom docs [here](https://dev.zenroom.org/wiki/how-to-exec/#data-string)
- `conf` **[string](https://docs.python.org/3/library/stdtypes.html#text-sequence-type-str)** the optional conf
 string to pass according to zen_config [here](https://github.com/dyne/Zenroom/blob/master/src/zen_config.c#L99-L104)

#### return
Both functions return the same object result `ZenResult` that have two attributes:

- `stdout` **[string](https://docs.python.org/3/library/stdtypes.html#text-sequence-type-str)** holds the stdout of the script execution
- `stderr` **[string](https://docs.python.org/3/library/stdtypes.html#text-sequence-type-str)** holds the stderr of the script execution

##### Examples

Example usage of `zencode_exec(script, keys=None, data=None, conf=None)`


```python
from zenroom import zenroom

contract = """Scenario ecdh: Create a keypair"
Given that I am known as 'identifier'
When I create the keypair
Then print my data
"""

result = zenroom.zencode_exec(contract)
print(result.output)
```


Example usage of `zenroom_exec(script, keys=None, data=None, conf=None)`

```python
from zenroom import zenroom

script = "print('Hello world')"
result = zenroom.zenroom_exec(script)

print(result.output)
```

The same arguments and the same result are applied as the `zencode_exec` call.

***
## 📋 Testing

Tests are made with pytests, just run 

`python setup.py test`

in [`zenroom_test.py`](https://github.com/dyne/Zenroom/blob/master/bindings/python3/tests/test_all.py) file you'll find more usage examples of the wrapper

***
## 🌐 Links

https://decodeproject.eu/

https://zenroom.org/

https://dev.zenroom.org/

## 😍 Acknowledgements

Copyright (C) 2018-2022 by [Dyne.org](https://www.dyne.org) foundation, Amsterdam

Originally designed and written by Sam Mulube.

Designed, written and maintained by Puria Nafisi Azizi 

Rewritten by Danilo Spinella and David Dashyan

<img src="https://ec.europa.eu/cefdigital/wiki/download/attachments/289112547/logo-cef-digital-2021.png" width="310" alt="Project funded by the European Commission">
This project is receiving funding from the European Union’s Horizon 2020 research and innovation programme under grant agreement nr. 732546 (DECODE).

***

## 👥 Contributing
Please first take a look at the [Dyne.org - Contributor License Agreement](CONTRIBUTING.md) then

1.  🔀 [FORK IT](https://github.com/dyne/Zenroom//fork)
2.  Create your feature branch `git checkout -b feature/branch`
3.  Commit your changes `git commit -am 'Add some fooBar'`
4.  Push to the branch `git push origin feature/branch`
5.  Create a new Pull Request `gh pr create -f`
6.  🙏 Thank you

***

## 💼 License

      Zenroom.py - a python wrapper of zenroom
      Copyright (c) 2018-2022 Dyne.org foundation, Amsterdam

      This program is free software: you can redistribute it and/or modify
      it under the terms of the GNU Affero General Public License as
      published by the Free Software Foundation, either version 3 of the
      License, or (at your option) any later version.

      This program is distributed in the hope that it will be useful,
      but WITHOUT ANY WARRANTY; without even the implied warranty of
      MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
      GNU Affero General Public License for more details.

      You should have received a copy of the GNU Affero General Public License
      along with this program.  If not, see <http://www.gnu.org/licenses/>.
