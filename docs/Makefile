.PHONY: article
ARTICLE := Zenroom_Cryptolang_Whitepaper
DEST := pub

all: webnomad

readme:
	echo "<markdown>" > views/index.html
	cat ../README.md >> views/index.html
	echo "</markdown>" >> views/index.html

preview: DEST := test
preview: views api readme
	./webnomad/preview

webnomad: DEST := pub
webnomad: views api readme
	./webnomad/render

article: article/views
	mkdir -p ${DEST}/whitepaper
	cd article && ./writedown/render pdf
	cp article/pub/${ARTICLE}.pdf ${DEST}
	mkdir -p ${DEST}/whitepaper
	pdf2htmlEX ${DEST}/${ARTICLE}.pdf ${DEST}/whitepaper/index.html

api: zenroom-api.lua
	ldoc -d ${DEST}/api -p Zenroom -t "Zenroom API" -X zenroom-api.lua

upload: webnomad
	rsync -Pr pub/* assata.dyne.org:/srv/www/zenroom.dyne.org
