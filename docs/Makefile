all: sitemap

# api output is _media/lua
api:
	make -C pages/ldoc clean
	make -C pages/ldoc

sitemap:
	@bash ./build_sitemap.sh _sidebar.md
