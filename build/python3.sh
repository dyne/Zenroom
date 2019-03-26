#!/usr/bin/env zsh

## This script wraps the build for different python3 versions since
## there is incompatibility even between minor versions. I needs pyenv
## as a dependency (https://github.com/pyenv/pyenv)

help="usage: build/python3.sh [ osx | linux ] (from base src dir)"
[[ -r README.md ]] || {	print $help; return 1 }
[[ "$1" == "" ]] &&   {	print $help; return 1 }
mkdir -p build/python3

## Cycle through versions needed with
## PYTHON_CONFIGURE_OPTS="--enable-shared" pyenv install 3.6.8
## ...... and so on for 3.5.6 and 3.7.2
pys=(3.5.0 3.5.1 3.5.2 3.5.3 3.5.4 3.5.5 3.5.6)
pys+=(     3.6.0 3.6.1 3.6.2 3.6.3 3.6.4 3.6.5 3.6.6 3.6.7 3.6.8)
pys+=(           3.7.0 3.7.1 3.7.2)
## Run the script below in a zsh on the build machine
# for VERSION in $pys; do
# 	PYTHON_CONFIGURE_OPTS="--enable-shared" pyenv install $VERSION
# done

command -v pyenv > /dev/null && {
	for VERSION in $pys; do
		pyenv local $VERSION
		make ${1}-python3
		mv "build/python3/_zenroom.so" "build/python3/_zenroom_$VERSION.so"
	done
	return 0
}

VERSION=`pkg-config python3 --modversion`
make ${1}-python3 &&
	mv "build/python3/_zenroom.so" "build/python3/_zenroom_$VERSION.so"
