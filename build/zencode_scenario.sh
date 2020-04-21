#!/usr/bin/env zsh
#
# build the zencode scenario test scripts and copy them into the
# documentation folder. called from zenroom/docs

scen="$1"
R="$PWD/.."
[[ -r "$R/test/zencode_${scen}" ]] || {
	echo "error in script $0"
	echo "scenario not found: $R/test/zencode_${scen}"
	exit 1 }
pushd $R/test/zencode_${scen}
./run.sh
mkdir -p $R/docs/examples/zencode_${scen}
cp -av *zen *json $R/docs/examples/zencode_${scen}
popd
