#!/usr/bin/env zsh

## This needs pyenv as a dependency (https://github.com/pyenv/pyenv)
## You should install all the versions needed with
## PYTHON_CONFIGURE_OPTS="--enable-shared" pyenv install 3.6.8
## and so on for 3.5.6 and 3.7.2

cd ../

pys=(3.5.0 3.5.1 3.5.2 3.5.3 3.5.4 3.5.5 3.5.6)
pys+=(     3.6.0 3.6.1 3.6.2 3.6.3 3.6.4 3.6.5 3.6.6 3.6.7 3.6.8 3.6.9)
pys+=(           3.7.0 3.7.1 3.7.2 3.7.3 3.7.4)
OK='\033[1;32m'
NC='\033[0m' # No Color

command -v pyenv > /dev/null && {
	for VERSION in $pys
	do
	  echo -e "Compiling Zenroom for ${OK}Python $(uname) ${VERSION}${NC}"
	  make -s clean > /dev/null 2>&1
	  PYTHON_CONFIGURE_OPTS="--enable-shared" pyenv install -s $VERSION
	  pyenv local $VERSION
	  case "$(uname)" in
	  Linux)
		make -s linux-python3 > /dev/null 2>&1 || exit 1
		;;
	  Darwin)
		make -s osx-python3 || exit 1
		;;
	  esac
	  echo
	done
}
