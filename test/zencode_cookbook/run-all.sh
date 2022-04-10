#!/bin/bash

set -e

./run-dictionaries.sh "$1"
./run-given.sh "$1"
./run-hash-pdf.sh "$1"
./run-intro.sh "$1"
./run-scenarios-ecdh-encrypt-json.sh "$1"
./run-scenarios-ecdh.sh "$1"
./run-then.sh "$1"
./run-when.sh "$1"
