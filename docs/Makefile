.PHONY: article
ARTICLE := Zenroom_Cryptolang_Whitepaper
DEST := pub

all: webnomad api

readme:
	echo "<markdown>" > views/index.html
	cat ../README.md >> views/index.html
	echo "</markdown>" >> views/index.html

preview: DEST := test
preview: views readme
	./webnomad/preview

webnomad: DEST := pub
webnomad: views readme
	./webnomad/render

article: article/views
	mkdir -p ${DEST}/whitepaper
	cd article && ./writedown/render pdf
	cp article/pub/${ARTICLE}.pdf ${DEST}
	mkdir -p ${DEST}/whitepaper
	pdf2htmlEX ${DEST}/${ARTICLE}.pdf ${DEST}/whitepaper/index.html

api:
	make -C ldoc

upload:
	rsync -Pr pub/* files.dyne.org:/srv/www/zenroom.dyne.org
	rsync -Pr demo files.dyne.org:/srv/www/zenroom.dyne.org/
