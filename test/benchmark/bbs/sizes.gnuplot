set notitle
set terminal TERM
set key left nobox
set style data points
set autoscale
set xlabel "credentials"
set ylabel "bytes"
plot for [col=2:4] "sizes.txt" using 0:col:xticlabels(1) with lines linetype 8 dashtype col title columnheader
