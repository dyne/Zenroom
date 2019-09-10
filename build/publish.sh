#!/usr/bin/env zsh

BUILD_PATH="`dirname \"$0\"`"

activate_python () {
	. venv/bin/activate
}

publish_python () {
	cd $BUILD_PATH
	./python_build.sh
	cd ../bindings/python3
	python3 -m venv venv
	activate_python
	pip install --upgrade pip
	pip install -e .
	pip install wheel
	pip install twine
	python3 setup.py publish
}

publish_python
