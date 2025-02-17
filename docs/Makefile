all: sitemap onepage

# api output is _media/lua
api:
	make -C pages/ldoc clean
	make -C pages/ldoc

sitemap:
	@bash ./build_sitemap.sh _sidebar.md

onepage:
	@bash ./build_onepage.sh _sidebar.md
