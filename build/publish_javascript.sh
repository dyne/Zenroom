#!/usr/bin/env zsh

source ./publish.sh
# loads:
# - env vars: BUILD_PATH
# - parse_version

activate_javascript () {
	git clone https://github.com/emscripten-core/emsdk.git
	cd emsdk
	./emsdk install sdk-1.38.31-64bit
	./emsdk activate --embedded sdk-1.38.31-64bit
	source ./emsdk_env.sh
	cd ..
}

publish_javascript () {
	cd ../bindings/javascript
	# activate_javascript
	yarn
	yarn version --new-version $VERSION
	yarn transpile
	yarn run doc:api
	yarn release
	rm -rf emsdk
}

parse_version
echo -e "Publishing ${OK}${VERSION}${NC} for ${OK}Javascript${NC} over npm"
echo
publish_javascript
