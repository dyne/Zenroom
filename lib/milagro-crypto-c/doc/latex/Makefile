## Makefile
#
#

###############################################################################
# File lists

DISTFILES = *.aux *.log *~ *.blg *.bbl *.dvi *.toc *.glg *.gls  *.glo *.idx *.ist *.brf *.out
CLEANFILES = $(DISTFILES) *.ps *.pdf *.zip *.tar.gz

###############################################################################
# Build rules

all: amcl.pdf 

amcl.pdf: amcl.tex amcl.bib
	latex amcl
	bibtex amcl
	latex amcl
	latex amcl
	dvips -Ppdf -G0 amcl.dvi
	ps2pdf amcl.ps

###############################################################################
# Clean-up rules

clean:
	-rm -f $(CLEANFILES)

distclean:
	-rm -f $(DISTFILES)

