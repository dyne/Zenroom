#!/bin/sh

# entropy benchmark of longfellow-zk

set -e # fail on any error

ZENROOM=../../../zenroom
if ! [ -x ${ZENROOM} ]; then ZENROOM=`which zenroom`; fi
if ! [ -x ${ZENROOM} ]; then
	>&2 echo "Zenroom binary not found, please install from Zenroom.org"
	exit 1
fi
>&2 echo "Zenroom binary used: ${ZENROOM}"

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
	seed_random_org        > random_org.json
	>&2 cat random_org.json
	LF_HAMMING_SAMPLES=${SAMPLES} \
					   ${ZENROOM} \
					   -k random_org.json \
					   -x longfellow_circuit1.b64 \
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
set title "Hamming distance between longfellow-zk unlinkable proofs (${SAMPLES} samples)"
set style fill transparent solid 0.25 border
set terminal pngcairo dashed rounded size 1024,768
set xlabel "hamming distance in bits"
set ylabel "frequency"
set format y "% .4s%c"
set format x "% .4s%c"
plot for[col=1:3] '${FILE}.txt' using 1:col title columnheader smooth frequency with fillsteps linetype col
EOF
# 		cat <<EOF | gnuplot > ${FILE}.png
# set title "Hamming distance between longfellow-zk unlinkable proofs (${SAMPLES} samples)"
# set style fill transparent solid 0.25 border
# set terminal pngcairo dashed rounded size 1024,768
# set yrange [0:4]
# set ytics 0, 1, 4
# set xlabel "hamming distance in bits"
# set ylabel "frequency"
# set style data histograms
# set boxwidth 0.8
# set format x "% .2s%c"
# # Combine all columns into a single stream and count frequencies
# plot '<(awk "{print \$1; print \$2; print \$3}" $FILE.txt | sort -n | uniq -c)' \
#      using 2:1 with boxes title "Frequency"
# EOF
	fi
}

[ -r longfellow_circuit1.b64 ] || {
	cat <<EOF  > generate_circuit.lua
ZK = require'crypto_longfellow'
print(ZK.generate_circuit(1).compressed:base64())
EOF
	${ZENROOM} generate_circuit.lua > longfellow_circuit1.b64
}

[ -r hamming_samples10.txt ] || calculate_hamming 10
render_hamming 10

[ -r hamming_samples100.txt ] || calculate_hamming 100
render_hamming 100

[ -r hamming_samples1000.txt ] || calculate_hamming 1000
render_hamming 1000

[ -r hamming_samples10000.txt ] || calculate_hamming 10000
render_hamming 10000
