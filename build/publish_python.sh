#!/usr/bin/env zsh

BUILD_PATH="`dirname \"$0\"`"
cd $BUILD_PATH

OK='\033[1;32m'
NC='\033[0m' # No Color

activate_python () {
	. venv/bin/activate
}

publish_python () {
#	./python_build.sh
	cd ../bindings
	wget https://sdk.dyne.org:4443/view/zenroom/job/zenroom-python/lastSuccessfulBuild/artifact/build/zenroom-python3.tar.gz
	tar xzvf zenroom-python3.tar.gz  python3/zenroom/libs/Linux/
	cd ../bindings/python3
	python3.7 -m venv venv
	activate_python
	pip install --upgrade pip
	pip install -e .
	pip install wheel
	pip install twine
	python3.7 setup.py publish
#	deactivate
}

echo -e "Publishing ${OK}${VERSION}${NC} for ${OK}Python${NC} over pypi.org"
echo

publish_python

