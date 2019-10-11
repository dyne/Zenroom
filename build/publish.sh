#!/usr/bin/env zsh

BUILD_PATH="`dirname \"$0\"`"
cd $BUILD_PATH

OK='\033[1;32m'
NC='\033[0m' # No Color

activate_python () {
	. venv/bin/activate
}

activate_javascript () {
	git clone https://github.com/emscripten-core/emsdk.git
	cd emsdk
	./emsdk install sdk-1.38.31-64bit
	./emsdk activate --embedded sdk-1.38.31-64bit
	source ./emsdk_env.sh
	cd ..
}


parse_version () {
	make -pn -f ../src/Makefile > /tmp/make.db.txt 2>/dev/null
	while read var assign value; do
		if [[ ${var} = 'VERSION' ]] && [[ ${assign} = ':=' ]]; then
			VERSION="$value"
			echo $VERSION > ../bindings/VERSION
			break
		fi
	done </tmp/make.db.txt
	rm -f /tmp/make.db.txt
}

publish_python () {
	./python_build.sh
	cd ../bindings/python3
	python3 -m venv venv
	activate_python
	pip install --upgrade pip
	pip install -e .
	pip install wheel
	pip install twine
	python3 setup.py publish
	deactivate
}

publish_javascript () {
	cd ../bindings/javascript
	activate_javascript
	yarn
	yarn version --new-version $VERSION
	yarn transpile
	yarn run doc:api
	yarn release
	rm -rf emsdk
}

# parse_version
# echo -e "Publishing ${OK}${VERSION}${NC} for ${OK}Python${NC} over pypi.org"
# echo

# publish_python
# cd $BUILD_PATH

# echo -e "Publishing ${OK}${VERSION}${NC} for ${OK}Javascript${NC} over npm"
# echo

# publish_javascript
