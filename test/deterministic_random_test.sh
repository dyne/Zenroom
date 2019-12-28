#!/usr/bin/env zsh


set -e
set -u
set -o pipefail

seed="0x619007c2ae1cf73f188d142f168a127d29fb59291713394f703ca8501e31548015de3f89ef6ca10043e0f7fa2bf7c1525634065cbe5fb14f7c8aa652d726334e633537ec5b15b399897f8389230d9cc06d2143bf58ed0a3f6407daeb339ab099630a898ba4d3bcf13b896c1f5d4620da7117cb647a9ae0e46b046d17a50f190000e87d250d08e38ed1843d70a12ad5a4d00bb91d3d5109b8c1d77c4e83861ab6de8297bbc4ad68481305f0c4b32860f41afc74937e10b0e4b911d97b9b6435fd7a00ae2dd3ff7721021acfbab2146bc0c6ad796969ed0451b8913f1e4813ab9e25506e199a69dcea7856bf2003dae16db2f9ca95a765dd52cf2d919200b1501f"

exe=${1:-zenroom}
first=`${exe} -c rngseed=\"$seed\" test/deterministic_mode.lua`
second=`${exe} -c rngseed=\"$seed\" test/deterministic_mode.lua`

# echo "$first"

if test "$first" = "$second"; then
	echo
	echo "====================="
	echo "Deterministic mode OK"
	echo "====================="
	echo
else
	echo
	echo "Error in deterministic mode"
	echo
	echo "$first" > /tmp/first
	echo "$second" > /tmp/second
	diff /tmp/first /tmp/second
	echo
	return 1
fi

first=`${exe}  test/deterministic_mode.lua`
second=`${exe} test/deterministic_mode.lua`


if ! [[ "$first" == "$second" ]]; then
	echo
	echo "======================="
	echo "Undeterministic mode OK"
	echo "======================="
	echo
	return 0
else
	echo
	echo "Error in undeterministic mode"
	echo
	echo "$first" > /tmp/first
	echo "$second" > /tmp/second
	diff /tmp/first /tmp/second
	echo
	return 1
fi
