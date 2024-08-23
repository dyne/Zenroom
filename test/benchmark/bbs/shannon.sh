#!/bin/sh

# shannon entropy benchmark of BBS+ - for info see:
# https://news.dyne.org/benchmark-of-the-bbs-signature-scheme-v06/

# 272 is the byte length of a BBS+ proof
set -e

export SAMPLES=500

ZENROOM=../../../src/zenroom
if ! [ -x ${ZENROOM} ]; then ZENROOM=`which zenroom`; fi
if ! [ -x ${ZENROOM} ]; then
	>&2 echo "Zenroom binary not found, please install from Zenroom.org"
	exit 1
fi
>&2 echo "Zenroom binary used: ${ZENROOM}"

gen_openssl() {
	local ds=${1:-10}
	local size=${2:-272}
	>&2 echo "Generating OpenSSL samples: $ds"
	echo -n '['
	for i in `seq ${ds}`; do
		echo -n "\"`openssl rand -hex ${size}`\","
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

render_shannon() {
	SAMPLES=${1:-10}
	FILE=shannon_samples${SAMPLES}
	cat <<EOF | gnuplot > ${FILE}.png
set title "Shannon entropy comparison on BBS+ unlinkable proofs (${SAMPLES} samples)"
set terminal pngcairo dashed rounded size 1024,768
set key left nobox
set style data points
set autoscale
set ylabel "entropy"
plot for[col=1:4] '${FILE}.txt' using 0:col with lines title columnheader
EOF

}

[ -r shannon_samples${SAMPLES}.txt ] \
	|| {
	seed_random_org     > random_org.json
	gen_openssl ${SAMPLES} 272 > shannon_openssl.json
	${ZENROOM} -l common.lua -a shannon_openssl.json -k random_org.json shannon.lua \
				  > shannon_samples${SAMPLES}.txt
}
render_shannon ${SAMPLES}
