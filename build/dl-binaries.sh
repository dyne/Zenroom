#!/usr/bin/env zsh

[[ -r zip-binaries.sh ]] || {
	print "usage: run from the build/ directory"
	return 1 }

push() { mkdir -p $1 && pushd $1 }

push python2
wget https://sdk.dyne.org:4443/view/decode/job/zenroom-python/lastSuccessfulBuild/artifact/build/python2/_zenroom.so
popd

push python3
wget https://sdk.dyne.org:4443/view/decode/job/zenroom-python/lastSuccessfulBuild/artifact/build/python3/_zenroom.so
popd

# javascript-demo
push demo
wget https://sdk.dyne.org:4443/view/decode/job/zenroom-demo/lastSuccessfulBuild/artifact/docs/demo/index.data
wget https://sdk.dyne.org:4443/view/decode/job/zenroom-demo/lastSuccessfulBuild/artifact/docs/demo/index.html
wget https://sdk.dyne.org:4443/view/decode/job/zenroom-demo/lastSuccessfulBuild/artifact/docs/demo/index.js
wget https://sdk.dyne.org:4443/view/decode/job/zenroom-demo/lastSuccessfulBuild/artifact/docs/demo/index.wasm
popd
# rnjs
push reactnative
wget https://sdk.dyne.org:4443/view/decode/job/zenroom-react/lastSuccessfulBuild/artifact/build/rnjs/zenroom.js
popd
# asmjs
push asmjs
wget https://sdk.dyne.org:4443/view/decode/job/zenroom-asmjs/lastSuccessfulBuild/artifact/build/asmjs/zenroom.js
wget https://sdk.dyne.org:4443/view/decode/job/zenroom-asmjs/lastSuccessfulBuild/artifact/build/asmjs/zenroom.js.mem
popd
# wasm
push wasm
wget https://sdk.dyne.org:4443/view/decode/job/zenroom-wasm/lastSuccessfulBuild/artifact/build/wasm/zenroom.js
wget https://sdk.dyne.org:4443/view/decode/job/zenroom-wasm/lastSuccessfulBuild/artifact/build/wasm/zenroom.wasm
popd

# linux	
wget https://sdk.dyne.org:4443/view/decode/job/zenroom-shared-android-arm/lastSuccessfulBuild/artifact/src/zenroom.so
mv zenroom.so zenroom-armhf.so
wget https://sdk.dyne.org:4443/view/decode/job/zenroom-static-armhf/lastSuccessfulBuild/artifact/src/zenroom-static
mv zenroom-static zenroom.armhf
wget https://sdk.dyne.org:4443/view/decode/job/zenroom-static-amd64/lastSuccessfulBuild/artifact/src/zenroom-static
mv zenroom-static zenroom.x86
