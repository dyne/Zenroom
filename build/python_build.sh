#!/bin/bash

## This needs pyenv as a dependency (https://github.com/pyenv/pyenv)
## You should install all the versions needed with
## PYTHON_CONFIGURE_OPTS="--enable-shared" pyenv install 3.6.8
## and so on for 3.5.6 and 3.7.2

for VERSION in 3.5.6 3.6.8 3.7.2
do
  pyenv local $VERSION
  make linux-python3
  PY=$(python -c "import sys; print('_'.join(map(str, sys.version_info[:2])))")
  mv "build/python3/_zenroom.so" "build/python3/_zenroom_$PY.so"
done
