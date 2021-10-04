#!/bin/sh

# without output on screen, used by meson tests
set -e
./run-dictionaries.sh "$1" > /dev/null
# ./run-given.sh "$1" > /dev/null
./run-hash-pdf.sh "$1" > /dev/null
./run-intro.sh "$1" > /dev/null
./run-scenarios-ecdh-encrypt-json.sh "$1" > /dev/null
./run-scenarios-ecdh.sh "$1" > /dev/null

./run-then.sh "$1" > /dev/null

./run-when.sh "$1" > /dev/null

