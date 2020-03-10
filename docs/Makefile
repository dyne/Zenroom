.PHONY: website preview

all: api map website

# api output is _media/lua
api:
	make -C pages/ldoc

# output is website/site
# download js from our CI
website:
	@if ! [ -r _media/js/zenroom.js -o -r _media/js/zenroom.wasm ]; then curl https://sdk.dyne.org:4443/view/zenroom/job/zenroom-web/lastSuccessfulBuild/artifact/build/web/zenroom.wasm https://sdk.dyne.org:4443/view/zenroom/job/zenroom-web/lastSuccessfulBuild/artifact/build/web/zenroom.js https://sdk.dyne.org:4443/view/zenroom/job/zenroom-web/lastSuccessfulBuild/artifact/build/web/zenroom.data -o _media/js/zenroom.wasm -o _media/js/zenroom.js -o _media/js/zenroom.data; fi
	@ln -s _media/js/zenroom.data .
	@cp -v ../examples/*.keys ../examples/*.data ../examples/*.lua _media/examples/

map:
	./_media/scripts/parse_zencode.sh _media/zencode_utterances.yaml

preview:
	docsify serve .

deploy: api map website
	cd website && ./mkdocs-dyne-theme/.deploy

clean:
	make -C pages/ldoc clean
	@rm _media/examples/*.data
	@rm _media/examples/*.keys
	@rm _media/examples/*.lua
	@rm _media/js/zenroom.*
	@rm _media/zencode_utterances.yaml
	@rm zenroom.data
	@echo "Zenroom docs cleaned up"
