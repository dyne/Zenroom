npm:
	cd javascript && yarn && yarn transpile && cd -
	mkdir zenroom-npm
	cp -v javascript/index.js zenroom-npm
	cp -v javascript/package.json zenroom-npm
	cp -v javascript/README.md zenroom-npm
	cp -ra javascript/dist zenroom-npm
	tar cvfz zenroom-npm.tar.gz zenroom-npm
	rm -rf zenroom-npm

clean:
	rm -f VERSION
	rm -rf javascript/emsdk/
	rm -rf javascript/dist/lib/

