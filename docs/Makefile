.PHONY: website preview

all: api map website

# api output is _media/lua
api:
	make -C pages/ldoc clean
	make -C pages/ldoc

# output is website/site
# download js from our CI
website:
	@if ! [ -r _media/js/zenroom.js -o -r _media/js/zenroom.wasm ]; then curl https://sdk.dyne.org:4443/view/zenroom/job/zenroom-web/lastSuccessfulBuild/artifact/build/web/zenroom.wasm https://sdk.dyne.org:4443/view/zenroom/job/zenroom-web/lastSuccessfulBuild/artifact/build/web/zenroom.js https://sdk.dyne.org:4443/view/zenroom/job/zenroom-web/lastSuccessfulBuild/artifact/build/web/zenroom.data -o _media/js/zenroom.wasm -o _media/js/zenroom.js -o _media/js/zenroom.data; fi
	@ln -fs _media/js/zenroom.data .
	@mkdir -p _media/examples
	@cp -v ../examples/*.keys ../examples/*.data ../examples/*.lua examples/
	@cp -av ../test/zencode_coconut examples/
	@cp -v ../bindings/javascript/README.md pages/javascript.md
	@cp -v ../bindings/python3/README.md pages/python.md

zencode:
	@../build/zencode_scenario.sh dp3t
	@../build/zencode_scenario.sh simple

map:
	./_media/scripts/parse_zencode.sh _media/zencode_utterances.yaml

preview:
	docsify serve .

deploy: api map website
	cd website && ./mkdocs-dyne-theme/.deploy

clean:
	make -C pages/ldoc clean
	@rm -rf examples/zencode_simple
	@rm -rf examples/zencode_dp3t
	@rm -rf examples/zencode_coconut
	@rm -f  examples/*.data
	@rm -f  examples/*.keys
	@rm -f  examples/*.lua
	@rm -f _media/js/zenroom.*
	@rm -f _media/zencode_utterances.yaml
	@rm -f pages/javascript.md
	@rm -f pages/python.md
	@rm -f zenroom.data
	@echo "Zenroom docs cleaned up"
