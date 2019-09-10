#!/usr/bin/env zsh

BUILD_PATH="`dirname \"$0\"`"
cd $BUILD_PATH

OK='\033[1;32m'
NC='\033[0m' # No Color

activate_python () {
	. venv/bin/activate
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
}

parse_version
echo -e "Publishing ${OK}${VERSION}${NC} for ${OK}Python${NC}"
echo

publish_python
