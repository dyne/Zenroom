<p align="center">
  <br/>
  <a href="https://dev.zenroom.org/">
    <img src="https://dev.zenroom.org/_media/images/zenroom_logo.png" height="140" alt="Zenroom">
  </a>
  <h2 align="center">
    zenroom.py 🐍
    <a href="https://pypi.org/project/zenroom/">
      <img alt="PyPI" src="https://img.shields.io/pypi/v/zenroom.svg" alt="Latest release">
    </a>
    <br>
    <sub>A Python3 wrapper of <a href="https://zenroom.org">Zenroom</a>, a secure and small virtual machine for crypto language processing</sub> </h2>
    <br>
</p>


This library attempts to provide a very simple wrapper around the 
[Zenroom](https://zenroom.dyne.org/) crypto virtual machine developed as part of the
[DECODE project](https://decodeproject.eu/), that aims to make the Zenroom
virtual machine easier to call from normal Python code.

Zenroom itself does have good cross platform functionality, so if you are
interested in finding out more about the functionalities offered by Zenroom,
then please visit the website linked to above to find out more.


***
## 💾 Installation

> [!NOTE]
> The `zenroom` package is just a wrapper around the `zencode-exec` utility.
> You also need to install `zencode-exec`, you can download if from the official [releases on github](https://github.com/dyne/Zenroom/releases/).
> After downloading it, you have to move it somewhere in your path, like `/usr/local/bin/`

<!-- tabs:start -->

### ** Linux **

```bash
# install zenroom wrapper
pip install zenroom

# install zencode-exec and copy it into PATH
wget https://github.com/dyne/zenroom/releases/latest/download/zencode-exec
chmod +x zencode-exec
sudo cp zencode-exec /usr/local/bin/
```

### ** MacOS **

> [!WARNING]
> On Mac OS, the executable is `zencode-exec.command` and you have to symlink it to `zencode-exec`

```bash
# install zenroom wrapper
pip install zenroom

# install zencode-exec and copy it into PATH
wget https://github.com/dyne/zenroom/releases/latest/download/zencode-exec.command
chmod +x zencode-exec.command
sudo cp zencode-exec.command /usr/local/bin/
sudo ln -s /usr/local/bin/zencode-exec.command /usr/local/bin/zencode-exec
```

<!-- tabs:end -->
### ** Windows **

> [!WARNING]
> On Windows, the executable is `zencode-exec.command` and you have to symlink it to `zencode-exec.exe`

To install on Windows, please do the same as in the previous guides, but download instead [zencode-exec.exe](https://github.com/dyne/zenroom/releases/latest/download/zencode-exec.exe) and place where python can execute it.



***
## 🎮 Usage

If you don't know what `zencode` is, you can start with the [official documentation](https://dev.zenroom.org).

The wrapper exposes one simple calls: `zencode_exec`

#### args
- `script` **[string](https://docs.python.org/3/library/stdtypes.html#text-sequence-type-str)**
 the zencode script to be executed
- `conf` **[string](https://docs.python.org/3/library/stdtypes.html#text-sequence-type-str)** the optional conf
 string to pass according to [zenroom config](https://dev.zenroom.org/#/pages/zenroom-config)
- `keys` **[string](https://docs.python.org/3/library/stdtypes.html#text-sequence-type-str)** the optional keys
 string to pass in execution as documented in zenroom docs
- `data` **[string](https://docs.python.org/3/library/stdtypes.html#text-sequence-type-str)** the optional data
 string to pass in execution as documented in zenroom docs

#### return
- `output` **[string](https://docs.python.org/3/library/stdtypes.html#text-sequence-type-str)** holds the stdout of the script execution
- `logs` **[string](https://docs.python.org/3/library/stdtypes.html#text-sequence-type-str)** holds the stderr of the script execution
- `result` (dictionary or None) holds the JSON parsed output if output contains valid JSON, otherwise it is None.

##### Examples

Example usage of `zencode_exec(script, keys=None, data=None, conf=None)`


```python
from zenroom import zenroom

contract = """Scenario ecdh: Create a ecdh key
Given that I am known as 'Alice'
When I create the ecdh key
Then print the 'keyring'
"""

result = zenroom.zencode_exec(contract)
print(result.output)
```

Next, we show a more complex example involving an ethereum signature
```python
from zenroom import zenroom
import json

conf = ""

keys = {
    "participant": {
        "keyring": {
            "ethereum": "6b4f32fc48ff19f0c184f1b7c593fbe26633421798191931c210a3a9bb46ae22"
        }
    }
}

data = {
    "myString": "I love the Beatles, all but 3",
    "participant ethereum address": "0x2B8070975AF995Ef7eb949AE28ee7706B9039504"
}

contract = """Scenario ethereum: sign ethereum message

# Here we are loading the private key and the message to be signed
Given I am 'participant'
Given I have my 'keyring'
Given I have a 'string' named 'myString'
Given I have a 'ethereum address' named 'participant ethereum address'


# Here we are creating the signature according to EIP712
When I create the ethereum signature of 'myString'
When I rename the 'ethereum signature' to 'myString.ethereum-signature'

# Here we copy the signature, which we'll print in a different format
When I copy 'myString.ethereum-signature' to 'myString.ethereum-signature.rsv'

# Here we print the signature in the regular 65 bytes long 'signaure hash' format
When I create ethereum address from ethereum signature 'myString.ethereum-signature' of 'myString'
When I copy 'ethereum address' to 'newEthereumAddress'


If I verify 'newEthereumAddress' is equal to 'participant ethereum address'
Then print string 'all good, the recovered ethereum address matches the original one'
Endif

Then print the 'myString.ethereum-signature'
Then print the 'newEthereumAddress'


# Here we print the copy of the signature in the [r,s,v], simply printing it as 'hex'
Then print the 'myString.ethereum-signature.rsv' as 'hex'
"""

result = zenroom.zencode_exec(contract, conf, json.dumps(keys), json.dumps(data))
print(result.output)
```


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

Copyright (C) 2018-2025 by [Dyne.org](https://www.dyne.org) foundation, Amsterdam

Originally designed and written by Sam Mulube.

Designed, written and maintained by Puria Nafisi Azizi 

Rewritten by Danilo Spinella and David Dashyan

<img src="https://upload.wikimedia.org/wikipedia/commons/8/84/European_Commission.svg" width="310" alt="Project funded by the European Commission">

This project is receiving funding from the European Union’s Horizon 2020 research and innovation programme under grant agreement nr. 732546 (DECODE).

***

## 👥 Contributing
Please first take a look at the [Dyne.org - Contributor License Agreement](https://github.com/dyne/Zenroom/blob/master/Agreement.md) then

1.  🔀 [FORK IT](https://github.com/dyne/Zenroom//fork)
2.  Create your feature branch `git checkout -b feature/branch`
3.  Commit your changes `git commit -am 'Add some fooBar'`
4.  Push to the branch `git push origin feature/branch`
5.  Create a new Pull Request `gh pr create -f`
6.  🙏 Thank you

***

## 💼 License

      Zenroom.py - a python wrapper of zenroom
      Copyright (c) 2018-2025 Dyne.org foundation, Amsterdam

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
