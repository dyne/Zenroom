#!/usr/bin/env bash

TEMP="$(mktemp)"

IFS=$'\n'       # make newlines the only separator
c=0

zenroom=../../src/zenroom
if [ ! -r ${zenroom} ]; then zenroom="../../meson/zenroom"; fi

echo
echo "####################"
echo "EDDSA SIGNATURE TEST"
for row in $(cat ./ed25519_tests.txt)
do
  echo "$row" >$TEMP
  ${zenroom} test_row.lua -a $TEMP 2>/dev/null
  res=$?
  c=$(( $c + 1 ))
  if [ $res != 0 ]; then echo "$c - ERROR $res"; exit 1; else echo -n "."; fi
#  if [[ $? != 0 ]]; then
#    echo "Verifica fallita alla riga"
#    echo "$row"
#    exit -1
#  fi
done
rm $TEMP
echo
echo "Success, $c vectors matched"
echo "###########################"
# Note: IFS needs to be reset to default!
