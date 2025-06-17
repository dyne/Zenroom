#!/bin/bash

[ "$1" == "" ] && {
	>&2 echo "usage: ./import.sh path/to/longfellow-zk"
	exit 1
}

[ -r "$1" ] || {
	>&2 echo "not found: $1"
	exit 1
}

cp "$1"/libmdoc_static.a .
cp "$1"/mdoc_zk.h .
