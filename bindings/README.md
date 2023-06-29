# Zenroom bindings

This folder contains all the bindings for languages other than `C`.

## :snake: Python3

<a href="https://travis-ci.com/DECODEproject/zenroom-py">
  <img src="https://travis-ci.com/DECODEproject/zenroom-py.svg?branch=master" alt="Build status"/>
</a>
<a href="https://codecov.io/gh/DECODEproject/zenroom-py">
  <img src="https://codecov.io/gh/DECODEproject/zenroom-py/branch/master/graph/badge.svg" alt="Code coverage"/>
</a>
<a href="https://pypi.org/project/zenroom/">
  <img alt="PyPI" src="https://img.shields.io/pypi/v/zenroom.svg" alt="Latest release">
</a>

## Javascript

<a href="https://travis-ci.com/DECODEproject/zenroomjs">
  <img src="https://travis-ci.com/DECODEproject/zenroomjs.svg?branch=master" alt="Build Status">
</a>
<a href="https://codecov.io/gh/DECODEproject/zenroomjs">
  <img src="https://codecov.io/gh/DECODEproject/zenroomjs/branch/master/graph/badge.svg" />
</a>
<a href="https://badge.fury.io/js/zenroom">
  <img alt="npm" src="https://img.shields.io/npm/v/zenroom.svg">
</a>

## Internals

The new recommended way to make Zenroom bindinds is to spawn an execution process of the `zencode-exec` binary, then call it passing it all arguments from an input stream (`stdin`) encoded as `base64`.

In brief such a shell command:
```
cat zencode-data-keys-conf | zencode-exec
```

The `zencode-data-keys-conf` is a file or stream with a newline separated list of base64 encoded inputs (except the initial `conf` line) which has to be in this order:
1. conf (string) *newline*
2. zencode script (string -> base64) *newline*
3. keys (json -> base64) *newline*
4. data (json -> base64) *newline*

Each line should start directly with the base64 string without any prefix and should end with a newline. Anything else will likely be rejected.

This executes and returns two streams:
1. `stdout` with the `json` formatted results of the execution
2. `stderr` with a `json` formatted array as log of events

The log of events is a simple array sorted in chronological order, the nature of the events can be detected by parsing the first 3 chars of each entry (or just the second most significant char):
- `[*]` is a notification of success
- ` . ` is execution information
- `[W]` is a warning
- `[!]` is a fatal error
- `[D]` is a verbose debug information when switched on with conf `debug=3`

It is also worth noting that `zencode-exec` utility will dump the HEAP and TRACE on errors and on debug requests on one single line using JSON format encoded as base64, i.e:
```
 .  HEAP: (base64 -> json)
 .  TRACE: (base64 -> json)
```
This should ease the task of the calling application to show the status of the execution and of the HEAP inside the VM, in case for instance of a debugging session.
