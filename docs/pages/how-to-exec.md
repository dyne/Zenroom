# How to execute Zenroom scripts

This section explains how to invoke the Zenroom to execute scripts from commandline or using the interactive console.


## Commandline

From **command-line** the Zenroom is operated passing files as
arguments:
```text
Usage: zenroom [-h] [ -d lvl ] [ -i ] [ -c config ] [ -k keys ] [ -a data ] [ -S seed ] [ -p ] [ -z ] [ script.zen | script.lua  ]

```
The **`-d`** flag activates more verbose output for debugging.

The **`-z`** flag activates the **zenCode** interpreter (rather than Lua)

The `script.zen` can be the path to a script or a single dash (`-`) to instruct zenroom to process the script piped from `stdin`.

## Interactive console

Just executing `zenroom` will open an interactive console with limited functionalities, which is capable to parse finite instruction blocks on each line. To facilitate editing of lines is possible to prefix it with readline using the `rlwrap zenroom` command instead.

The content of the KEYS, DATA and SCRIPT files cannot exceed 500KB.

Try:
```sh
./zenroom-static      [enter]
print("Hello World!") [enter]
                      [Ctrl-D] to quit
```
Will print Zenroom's execution details on `stderr` and the "Hello World!" string on `stdout`.

## Hashbang executable script

Zenroom also supports being used as an "hashbang" interpreter at the beginning of executable scripts. Just use:
```sh
#!/usr/bin/env zenroom-static -
```
in the header, please note the final dash which is pretty important to tell zenroom to process the script from `stdin`.


