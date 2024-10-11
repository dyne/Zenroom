ZENROOM ?= ../../../zenroom

all: keygen.png sign_verify.png zkp.png entropy.png

sizes:
	@echo '{"total":200,"step":5,"fraction":4,"size":64}' > params.json
	@$(ZENROOM) -l common.lua -a params.json sizes.lua > sizes.txt
	@rm -f params.json
	sed 's/TERM/pngcairo dashed rounded size 1024,768/' \
		$(basename $@).gnuplot | gnuplot  > $(basename $@).png

%.png: %.txt %.gnuplot
	sed 's/TERM/pngcairo dashed rounded size 1024,768/' \
		$(basename $@).gnuplot | gnuplot  > $(basename $@).png

%.eps: %.txt %.gnuplot
	sed 's/TERM/eps/' \
		$(basename $@).gnuplot | gnuplot  > $(basename $@).eps

%.txt:
	$(ZENROOM) -l common.lua ${basename $@}.lua | tee $@

clean:
	rm -f *.txt *.png *.eps
