#!/bin/bash

# script that cleans up libs imported from upstream
# this helps remember what needs to be deleted on import

i=mlkem
rm -rf $i/.git
rm -rf $i/.github
rm -rf $i/.envrc
rm -rf $i/.dev
rm -rf $i/proofs
rm -rf $i/nix
rm -rf "$i/test/acvp_data"
rm -rf "$i/test/acvp*"
rm -rf "$i/mlkem/native"
rm -rf "$i/mlkem/fips202/native"
rm -rf "$i/scripts"
rm -rf "$i/integration"
rm -rf "$i/examples"


