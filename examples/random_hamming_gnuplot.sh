#!/usr/bin/env bash
#
# Zenroom benchmark script by Jaromil (2018)

graphtitle="Hamming distance frequency of random ECP points"
echo "Plot random benchmarks measuring hamming distance"
echo " on randomly generated ECP/2 points by Zenroom"
R=random_hamming_gnuplot

samples=1000
methods="mult mod_mult mod_mapit hashtopoint"

function render() {	dst=$1
	if ! [ -r $R/${dst}.data ]; then
		echo
		echo "rendering method $dst"		
		time ./src/zenroom-shared $R/${dst}.lua > $R/${dst}.data 2>/dev/null
		echo "---"
	else echo "skip $dst"; fi }
mkdir -p $R
function script() {
	cat <<EOF > $R/$1.lua
rng = RNG.new()
g1 = ECP.generator()
o = ECP.order()
local new = $2
local old
for i=$samples,1,-1 do
   old = new
   new = $2
   ham = OCTET.hamming(old:octet(),new:octet())
   print(ham)
end
EOF
}

script mult        "INT.new(rng) * g1"
script mod_mult    "INT.new(rng,o) * g1"
script mod_mapit   "ECP.mapit(INT.new(rng,o):octet())"
script hashtopoint "ECP.hashtopoint(rng:octet(64))"

c=0
for i in $methods; do
	render $i
	if [ $c == 0 ]; then
		title=`echo $i | sed 's/_/ /g'`
		cat <<EOF > $R/steps.gnu
set title "$graphtitle ($samples samples)"
set style fill transparent solid 0.25 border
# set style fill pattern
set terminal png rounded
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
