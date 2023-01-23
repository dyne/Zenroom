#!/bin/bash
mkdir -p src/docs/pages
cp ../../docs/pages/python.md src/docs/pages/python.md
cp ../../Makefile src/Makefile
cp -r ../../build src/build
cp -r ../../lib src/lib
cp -r ../../src src/src
cp -r ../../test src/test

py_version=`git describe --tags --abbrev=0 | sed 's/^v//'`
branch=`git rev-parse --abbrev-ref HEAD`
hash=""
time=""
if [ "$branch" != "master" ]; then
    hash="+$(git rev-parse --short HEAD)"
    time=".dev$(git show -s --format=%ct HEAD)"
fi
echo "${py_version}${hash}" > src/git_utils
echo "${py_version}${time}" >> src/git_utils