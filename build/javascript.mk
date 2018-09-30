# TODO: improve flags according to
# https://github.com/kripken/emscripten/blob/master/src/settings.js
javascript-node: cflags += -DARCH_JS -D'ARCH=\"JS\"' -D MAX_STRING=128000 --memory-init-file 1
javascript-node: ldflags += --memory-init-file 1 -s WASM=0
javascript-node: apply-patches lua53 milagro lpeglabel
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
	make -C src js
	@mkdir -p build/nodejs
	@cp -v src/zenroom.js 	  build/nodejs/
	@cp -v src/zenroom.js.mem build/nodejs/

javascript-rn: cflags += -DARCH_JS -D'ARCH=\"JS\"' --memory-init-file 0 -D MAX_STRING=128000
javascript-rn: ldflags += -s WASM=0 --memory-init-file 0 -s MEM_INIT_METHOD=0 -s ASSERTIONS=1 -s NO_EXIT_RUNTIME=0 -s LEGACY_VM_SUPPORT=1 -s MODULARIZE=1
javascript-rn: apply-patches lua53 milagro lpeglabel
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
	make -C src js
	@mkdir -p build/rnjs
	sed -i 's/require("crypto")/require(".\/crypto")/g' src/zenroom.js
	sed -i 's/require("[^\.]/console.log("/g' src/zenroom.js
	sed -i 's/console.warn.bind/console.log.bind/g' src/zenroom.js
	sed -i 's/;ENVIRONMENT_IS_SHELL=[^;]*;/;ENVIRONMENT_IS_SHELL=true;/g' src/zenroom.js
	sed -i 's/;ENVIRONMENT_IS_NODE=[^;]*;/;ENVIRONMENT_IS_NODE=false;/g' src/zenroom.js
	sed -i 's/;ENVIRONMENT_IS_WORKER=[^;]*;/;ENVIRONMENT_IS_WORKER=false;/g' src/zenroom.js
	sed -i 's/;ENVIRONMENT_IS_WEB=[^;]*;/;ENVIRONMENT_IS_WEB=false;/g' src/zenroom.js
	@cp -v src/zenroom.js 	  build/rnjs/

javascript-demo: cflags  += -DARCH_WASM -D'ARCH=\"WASM\"' -D MAX_STRING=128000
javascript-demo: ldflags += -s WASM=1 -s ASSERTIONS=1 --shell-file ${extras}/shell_minimal.html -s NO_EXIT_RUNTIME=1
javascript-demo: apply-patches lua53 milagro lpeglabel
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
	make -C src js-demo
	@mkdir -p build/wasm
	@cp -v docs/demo/index.* build/wasm/
