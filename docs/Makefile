.PHONY: article website preview
ARTICLE := Zenroom_Cryptolang_Whitepaper
DEST := pub

all: api website

# api output is website/docs/lua
api:
	make -C ldoc

# output is website/site
# download js from our CI
# import wiki pages
# import changelog
website:
	@if ! [ -r website/docs/js/zenroom.js -o -r website/docs/js/zenroom.wasm ]; then curl https://sdk.dyne.org:4443/view/zenroom/job/zenroom-web/lastSuccessfulBuild/artifact/build/web/zenroom.wasm https://sdk.dyne.org:4443/view/zenroom/job/zenroom-web/lastSuccessfulBuild/artifact/build/web/zenroom.js https://sdk.dyne.org:4443/view/zenroom/job/zenroom-web/lastSuccessfulBuild/artifact/build/web/zenroom.data -o website/docs/js/zenroom.wasm -o website/docs/js/zenroom.js -o website/docs/js/zenroom.data; fi
	@mkdir -p website/docs/encrypt && cp -v website/docs/js/zenroom.data website/docs/encrypt/
	@mkdir -p website/docs/wiki
	@cp -v wiki/Build.md website/docs/wiki/how-to-build.md
	@cp -v wiki/Execute.md website/docs/wiki/how-to-exec.md
	@cp -v wiki/Embed.md website/docs/wiki/how-to-embed.md
	@cp -v ../ChangeLog.md website/docs/changelog.md
	../build/esh website/petition.esh R=../test/zencode_coconut > \
		../test/zencode_coconut/README.txt
	../build/esh website/zencode.esh > website/docs/zencode.md
	@cd website && mkdocs build

map:
	./parse_zencode.sh | json2yaml -

preview:
	cd website && ./mkdocs-dyne-theme/.preview

deploy: api website
	cd website && ./mkdocs-dyne-theme/.deploy

clean:
	@rm -rf website/docs/lua
	@rm -rf website/docs/wiki
	@rm -rf website/site
	@echo "Zenroom website cleaned up"
