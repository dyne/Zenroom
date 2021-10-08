#!/usr/bin/env bash

####################
# common script init
if ! test -r ../utils.sh; then
	echo "run executable from its own directory: $0"; exit 1; fi
. ../utils.sh
Z="`detect_zenroom_path` `detect_zenroom_conf`"
####################

$Z -a kyber512.rsp check_rsp_kyber.lua

## Tests for dilithium currently don't work
# $Z -a dilithium.rsp check_rsp_dilithium.lua
