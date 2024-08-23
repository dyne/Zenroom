#!/bin/sh

# entropy benchmark of BBS+ - for info see:
# https://news.dyne.org/benchmark-of-the-bbs-signature-scheme-v06/

# 272 is the byte length of a BBS+ proof

set -e # fail on any error

ZENROOM=../../../src/zenroom
if ! [ -x ${ZENROOM} ]; then ZENROOM=`which zenroom`; fi
if ! [ -x ${ZENROOM} ]; then
	>&2 echo "Zenroom binary not found, please install from Zenroom.org"
	exit 1
fi
>&2 echo "Zenroom binary used: ${ZENROOM}"

gen_openssl() {
	local ds=$(( ${1} * 2 ))
	>&2 echo "Generating OpenSSL samples: $ds"
	echo -n '['
	for i in `seq ${ds}`; do
		echo -n "\"`openssl rand -hex 272`\","
		>&2 echo -n '.'
	done
	>&2 echo '.'
	echo "\"00\"]"
}

seed_random_org() {
	>&2 echo "Getting a new seed from random.org"
	echo -n '{"seed":"'
	curl -sL "https://www.random.org/cgi-bin/randbyte?nbytes=64&format=h" \
		| sed 's/ //g;' | tr -d '\n'
	echo '"}'
}

calculate_hamming() {
	local SAMPLES=${1:-10}
	>&2 echo "Calculating hamming distance with samples: $SAMPLES"
	[ -r openssl${SAMPLES}.json ] || \
		gen_openssl ${SAMPLES} > openssl${SAMPLES}.json
	seed_random_org        > random_org.json
	>&2 cat random_org.json
	BBS_HAMMING_SAMPLES=${SAMPLES} \
					   ${ZENROOM} -l common.lua \
					   -a openssl${SAMPLES}.json -k random_org.json \
					   hamming.lua > "hamming_samples${SAMPLES}.txt"
	if [ $? != 0 ]; then
		>&2 echo "Calculation error: hamming_samples${SAMPLES}.txt"
		return 1
	fi
}

render_hamming() {
	SAMPLES=${1:-10}
	FILE=hamming_samples${SAMPLES}
	if ! [ -s ${FILE}.txt ]; then
		>&2 echo "Hamming samples file is empty: ${FILE}.txt"
	else
		>&2 echo "Rendering hamming distance with samples: $SAMPLES"
		cat <<EOF | gnuplot > ${FILE}.png
set title "Hamming distance between BBS+ unlinkable proofs (${SAMPLES} samples)"
set style fill transparent solid 0.25 border
set terminal pngcairo dashed rounded size 1024,768
set xlabel "hamming distance in bits"
set ylabel "frequency"
plot for[col=1:4] '${FILE}.txt' using 1:col title columnheader smooth frequency with fillsteps linetype col
EOF
	fi
}

[ -r hamming_samples10.txt ] || calculate_hamming 10
render_hamming 10

[ -r hamming_samples100.txt ] || calculate_hamming 100
render_hamming 100

[ -r hamming_samples1000.txt ] || calculate_hamming 1000
render_hamming 1000
