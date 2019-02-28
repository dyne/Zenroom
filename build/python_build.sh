#!/bin/bash

## This needs pyenv as a dependency (https://github.com/pyenv/pyenv)
## You should install all the versions needed with
## PYTHON_CONFIGURE_OPTS="--enable-shared" pyenv install 3.6.8
## and so on for 3.5.6 and 3.7.2

cd ../

for VERSION in 3.5.0 3.5.1 3.5.2 3.5.3 3.5.4 3.5.5 3.5.6 3.6.0 3.6.1 3.6.2 3.6.3 3.6.4 3.6.5 3.6.6 3.6.7 3.6.8 3.7.0 3.7.1 3.7.2
do
  PYTHON_CONFIGURE_OPTS="--enable-shared" pyenv install $VERSION
  pyenv local $VERSION
  make linux-python3
  mv "build/python3/_zenroom.so" "build/python3/_zenroom_$VERSION.so"
done
