#!/usr/bin/env bash
#
# Zenroom benchmark script by Jaromil (2018)
#
# uses BLS383 curve with point length of 97 bytes (776 bits)

graphtitle="Hamming distance frequency of random values in Zenroom"
echo "Plot random benchmarks measuring hamming distance"
echo " on randomly generated ECP/2 points by Zenroom"
R=random_hamming_gnuplot


samples=10000
methods=""

function render() {
	dst=$1
	if ! [ -r $R/${dst}.data ]; then
		echo
		echo "rendering method $dst"		
		time ../src/zenroom $R/${dst}.lua > $R/${dst}.data 2>/dev/null
		echo "---"
	else echo "skip $dst"; fi
}
mkdir -p $R
function script() {
	cat <<EOF > $R/$1.lua
g1 = ECP.generator()
o = ECP.order()
local new = $2
local old
for i=$samples,1,-1 do
   old = new
   new = $2
   ham = $3
   print(ham)
end
EOF
	methods="$methods $1"
}

# ECP points are 97 bytes long

# script mult        "INT.new(rng) * g1"
# script mod_mapit   "ECP.mapit(sha512(rng:octet(32)))"
# script hash2point_popcount  "ECP.hashtopoint(O.random(64))" "popcount_hamming"

script random  "O.random(97)" "O.hamming(old,new)"
script Gmult  "INT.modrand(o) * g1" "O.hamming(old:octet(),new:octet())"
script mapit512  "ECP.mapit(O.random(64))" "O.hamming(old:octet(),new:octet())"
script hash2point  "ECP.hashtopoint(O.random(97))" "O.hamming(old:octet(),new:octet())"

# script hashtp32    "ECP.hashtopoint(rng:octet(32))"
# script hashtp16    "ECP.hashtopoint(rng:octet(16))"
# script hashtp8    "ECP.hashtopoint(rng:octet(8))"
# script hashtp4    "ECP.hashtopoint(rng:octet(4))"
# script hashtp2    "ECP.hashtopoint(rng:octet(2))"

c=0
for i in $methods; do
	render $i
	if [[ $c == 0 ]]; then
		title=`echo $i | sed 's/_/ /g'`
		cat <<EOF > $R/steps.gnu
set title "$graphtitle ($samples samples)"
set style fill transparent solid 0.25 border
# set style fill pattern
set terminal png rounded size 1024,768
set xlabel "hamming distance in bits"
set ylabel "frequency"
plot '$R/${i}.data' u 1 title '$title' smooth frequency with fillsteps, \\
EOF
	else
		title=`echo $i | sed 's/_/ /g'`
		echo "     '$R/${i}.data' title '$title' smooth frequency with fillsteps, \\" >> $R/steps.gnu
	fi
	c=$(( $c + 1 ))
done
echo >> $R/steps.gnu
gnuplot -c $R/steps.gnu > $R/$R.png
