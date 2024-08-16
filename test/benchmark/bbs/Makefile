
all: keygen.png sign_verify.png zkp.png entropy.png
	../../../src/zenroom -l common.lua sizes.lua

%.png: %.txt %.gnuplot
	sed 's/TERM/pngcairo dashed rounded size 1024,768/' \
		$(basename $@).gnuplot | gnuplot  > $(basename $@).png

%.eps: %.txt %.gnuplot
	sed 's/TERM/eps/' \
		$(basename $@).gnuplot | gnuplot  > $(basename $@).eps

%.txt:
	../../../src/zenroom -l common.lua ${basename $@}.lua | tee $@

clean:
	rm -f *.txt *.png *.eps
