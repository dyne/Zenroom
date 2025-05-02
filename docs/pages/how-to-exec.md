# How to execute Zenroom scripts

This section explains how to invoke the Zenroom to execute scripts from commandline or using the interactive console.


## Commandline

From **command-line** the Zenroom is operated passing files as
arguments:
```text
Usage: zenroom [-h] [-s] [ -D scenario ] [ -i ] [ -c config ] [ -k keys ] [ -a data ] [ -z | -v ] [ -l lib ] [ script.lua ]
```
where:
* **`-h`** show the help meessage
* **`-s`** activate seccomp execution
* **`-D`** followed by a scenario return all the statements under that scenario divided by the phase they are into
* **`-i`** activate the interactive mode
* **`-c`** followed by a string indicates the [configuration](zenroom-config.md) to use
* **`-k`** indicates the path to contract keys file
* **`-a`** indicates the path to contract data file
* **`-e`** indicates the path to contract extra file
* **`-x`** indicates the path to contract context file
* **`-z`** activates the **zenCode** interpreter (rather than Lua)
* **`-v`** run only the given phase and reutrn if the input is valid for the given smart contract
* **`-l`**  allows to load an external lua library before executing zencode.

## Interactive console

Just executing `zenroom` will open an interactive console with limited functionalities, which is capable to parse finite instruction blocks on each line. To facilitate editing of lines is possible to prefix it with readline using the `rlwrap zenroom` command instead.

The content of the KEYS, DATA and SCRIPT files cannot exceed 2MiB.

Try:
```sh
./zenroom             [enter]
print("Hello World!") [enter]
                      [Ctrl-D] to quit
```
Will print Zenroom's execution details on `stderr` and the "Hello World!" string on `stdout`.

## Hashbang executable script

Zenroom also supports being used as an "hashbang" interpreter at the beginning of executable scripts. Just use:
```sh
#!/usr/bin/env zenroom
```
in the header to run lua commands with zenroom, or
```sh
#!/usr/bin/env -S zenroom -z
```
to run zencode contracts (the `-S` lets you pass multiple arguments in the shebang line).
