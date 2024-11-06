#!/bin/bash

# template: %PATH% has to be subsituted with absolute path
# this is processed by check-js to create a zenroom wrapper

conf=${conf:-"logfmt=text,debug=0"}

while getopts "zc:k:a:" arg; do
  case $arg in
    z) ;; # autodetected from script name
	k) keys="${OPTARG}" ;;
	a) data="${OPTARG}" ;;
	c) conf="${OPTARG},logfmt=text,debug=0" ;;
  esac
done
shift $((OPTIND-1))

if [[ $1 == *.lua ]]; then
	node =ROOT=/test/zenroom_exec.js \
		 =ROOT=/bindings/javascript/dist/main/zenroom.js $1 $conf $keys $data
elif [[ $1 == *.zen ]]; then
	node =ROOT=/test/zencode_exec.js \
		 =ROOT=/bindings/javascript/dist/main/zenroom.js $1 $conf $keys $data
else
	echo "Unsupported script: $1"
fi
