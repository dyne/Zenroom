set title "Hamming distance between unlinkable proofs"
set style fill transparent solid 0.25 border
# set style fill pattern
set terminal TERM
set xlabel "hamming distance in bits"
set ylabel "frequency"
plot for[col=1:2] 'entropy.txt' using 1:col title columnheader smooth frequency with fillsteps linetype col
