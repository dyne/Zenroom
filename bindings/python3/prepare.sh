#!/bin/bash
mkdir -p src/docs/pages
cp ../../docs/pages/python.md src/docs/pages/python.md

py_version=`git describe --tags --abbrev=0 | sed 's/^v//'`
py_version_hash=${py_version}
py_version_time=${py_version}
hash="$(git rev-parse --short HEAD)"
branch=`git rev-parse --abbrev-ref HEAD`
if [ "$branch" != "master" ]; then
    py_version_hash="${py_version_hash}+${hash}"
    py_version_time="${py_version_time}.dev$(git show -s --format=%ct HEAD)"
fi
echo "${py_version_hash}" > src/git_utils
echo "${py_version_time}" >> src/git_utils
echo "${hash}" >> src/git_utils
