# Zenroom-Go

[![Build Status](https://travis-ci.org/dyne/zenroom-go.svg?branch=master)](https://travis-ci.org/dyne/zenroom-go)
[![GoDoc](https://godoc.org/github.com/dyne/zenroom-go?status.svg)](https://godoc.org/github.com/dyne/zenroom-go)

Zenroom Binding for Go

## Introduction

Zenroom is a brand new virtual machine for fast cryptographic operations on Elliptic Curves. The Zenroom VM has no external dependencies, includes a cutting edge selection of C99 libraries and builds a small executable ready to run on: desktop, embedded, mobile, cloud and browsers (webassembly). This library adds a CGO wrapper for Zenroom, which aims to make the Zenroom VM easy to use from Go.

## Installation

Currently the bindings are only available for Linux machines, but if this is your current environment you should be able to just do:

```bash
$ go get github.com/dyne/Zenroom/bindings/golang/zenroom
```

## Usage

```go
package main

import (
  zenroom "github.com/dyne/Zenroom/bindings/golang/zenroom"
  "fmt"
)

func main() {
  genKeysScript :=
`Scenario ecdh
Given nothing
hen I create the ecdh key
Then print 'keyring'
`

  result, success := zenroom.ZencodeExec(genKeysScript, "", "", "")

  if ! success {
    fmt.Println(result.Logs)
  }
  fmt.Println(result.Output)
}
```

## More Documentation

 * Zenroom documentation https://dev.zenroom.org/
 
## Contributors

The original Go bindings for Zenroom were created by [@chespinoza](https://github.com/chespinoza), later updates by [@smulube](https://github.com/smulube).
