.PHONY: article website preview
ARTICLE := Zenroom_Cryptolang_Whitepaper
DEST := pub

all: api website

website:
	@if ! [ -r website/docs/js/zenroom.js -o -r website/docs/js/zenroom.wasm ]; then curl https://sdk.dyne.org:4443/view/zenroom/job/zenroom-web/lastSuccessfulBuild/artifact/build/web/zenroom.wasm https://sdk.dyne.org:4443/view/zenroom/job/zenroom-web/lastSuccessfulBuild/artifact/build/web/zenroom.js https://sdk.dyne.org:4443/view/zenroom/job/zenroom-web/lastSuccessfulBuild/artifact/build/web/zenroom.data -o website/docs/js/zenroom.wasm -o website/docs/js/zenroom.js -o website/docs/js/zenroom.data; fi
	@mkdir -p website/docs/encrypt && cp -v website/docs/js/* website/docs/encrypt/
	@cd website && mkdocs build

# @cp -v ../examples/zencode_crypt_web/index.html website/docs/encrypt.html
# @cp -v ../examples/zencode_crypt_web/index.js website/docs/encrypt.js

preview:
	cd website && ./mkdocs-dyne-theme/.preview

deploy:
	cd website && ./mkdocs-dyne-theme/.deploy

api:
	make -C ldoc
