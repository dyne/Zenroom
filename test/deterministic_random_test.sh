#!/usr/bin/env zsh

seed="000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
exe=${1:-zenroom}
first=`${exe} -S $seed test/deterministic_mode.lua`
second=`${exe} -S $seed test/deterministic_mode.lua`

# echo "$first"

if test "$first" = "$second"; then
	echo
	echo "====================="
	echo "Deterministic mode OK"
	echo "====================="
	echo
	return 0
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
