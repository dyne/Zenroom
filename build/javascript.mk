# TODO: improve flags according to
# https://github.com/kripken/emscripten/blob/master/src/settings.js

MAX_STRING := 8000 # 512000 # 128000

load-emsdk:
	EMSCRIPTEN="${pwd}/emsdk/upstream/emscripten" \
	${pwd}/emsdk/emsdk construct_env ${pwd}/build/emsdk_env.sh
	@echo "run: ${pwd}/build/emsdk_env.sh"

javascript-demo: cflags  += -DARCH_WASM -D'ARCH=\"WASM\"' -D MAX_STRING=128000
javascript-demo: ldflags += -s WASM=1 \
	-s ASSERTIONS=1 \
	--shell-file ${website}/demo/shell_minimal.html
javascript-demo: ${BUILDS}
	CC="${gcc}" CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
	JSEXT="--preload-file lua@/" \
	JSOUT="${website}/demo/index.html" \
	make -C src js

javascript-web: cflags  += -O3 -fno-exceptions -fno-rtti
javascript-web: cflags  += -DARCH_WASM -D'ARCH=\"WASM\"' \
	-s WASM_OBJECT_FILES=0
javascript-web: ldflags += -s WASM=1 -s ASSERTIONS=1 \
	-s TOTAL_MEMORY=65536000 \
	-s WASM_OBJECT_FILES=0 --llvm-lto 0 \
	-s DISABLE_EXCEPTION_CATCHING=1
javascript-web: ${BUILDS}
	CC="${gcc}" CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
	JSEXT="--preload-file lua@/" \
	make -C src js
	@mkdir -p build/web
	@cp -v src/zenroom.js   build/web/
	@cp -v src/zenroom.data build/web/
	@cp -v src/zenroom.wasm build/web/
	@mkdir -p ${website}/js
	@cp -v build/web/* ${website}/js/
	@cp -v build/web/zenroom.data ${website}/

javascript-wasm: cflags  += -DARCH_WASM -D'ARCH=\"WASM\"' -D MAX_STRING=128000
javascript-wasm: ldflags += -s \
	-s MODULARIZE=1 \
	-s ALLOW_MEMORY_GROWTH=1 \
	-s WARN_UNALIGNED=1 \
	-s FILESYSTEM=1 \
	-s ASSERTIONS=1 \
	--no-heap-copy
javascript-wasm: ${BUILDS}
	CC="${gcc}" CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
	JSEXT="--embed-file lua@/" \
	make -C src js
	@mkdir -p build/wasm
	@cp -v src/zenroom.js build/wasm/
	@cp -v src/zenroom.wasm build/wasm/

javascript-npm: cflags  += -O3
javascript-npm: cflags  += -DARCH_WASM -D'ARCH=\"WASM\"'
javascript-npm: ldflags += -s \
	-s MODULARIZE=1 \
	-s SINGLE_FILE=1 \
	-s ALLOW_MEMORY_GROWTH=1 \
	--no-heap-copy
javascript-npm: ${BUILDS}
	CC="${gcc}" CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
	JSEXT="--embed-file lua@/" \
	make -C src js
	@mkdir -p build/npm
	@cp -v src/zenroom.js      build/npm/

javascript-rn: cflags += -DARCH_JS -D'ARCH=\"JS\"' -D MAX_STRING=128000
javascript-rn: ldflags += -s WASM=0 \
	-s ENVIRONMENT=\"'shell'\" \
	-s MODULARIZE=1 \
	-s LEGACY_VM_SUPPORT=1 \
	-s ASSERTIONS=1 \
	-s EXIT_RUNTIME=1 \
	--memory-init-file 0
javascript-rn: ${BUILDS}
	CC="${gcc}" CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
	JSEXT="--embed-file lua@/" \
	make -C src js
	sed -i 's/require("crypto")/require(".\/crypto")/g' src/zenroom.js
	sed -i 's/require("[^\.]/console.log("/g' src/zenroom.js
	sed -i 's/console.warn.bind/console.log.bind/g' src/zenroom.js
	@mkdir -p build/rnjs
	@cp -v src/zenroom.js 	  build/rnjs/

