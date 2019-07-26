# TODO: improve flags according to
# https://github.com/kripken/emscripten/blob/master/src/settings.js

javascript-demo: cflags  += -DARCH_WASM -D'ARCH=\"WASM\"' -D MAX_STRING=128000
javascript-demo: ldflags += -s WASM=1 \
	-s ASSERTIONS=1 \
	--shell-file ${extras}/shell_minimal.html
javascript-demo: apply-patches lua53 milagro embed-lua
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
	make -C src js-demo
	@mkdir -p build/demo
	@cp -v docs/demo/index.* build/demo/
	@cp -v docs/demo/*.js build/demo/

javascript-asmjs: cflags += -DARCH_JS -D'ARCH=\"JS\"' -D MAX_STRING=128000
javascript-asmjs: ldflags += -s WASM=0 \
	-s ASSERTIONS=1 \
	--memory-init-file 1
javascript-asmjs: apply-patches lua53 milagro embed-lua
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
	make -C src js
	@mkdir -p build/asmjs
	@cp -v src/zenroom.js 	  build/asmjs/
	@cp -v src/zenroom.js.mem build/asmjs/

javascript-wasm: cflags  += -DARCH_WASM -D'ARCH=\"WASM\"' -D MAX_STRING=128000
javascript-wasm: ldflags += -s WASM=1 \
	-s INVOKE_RUN=0 \
	-s EXIT_RUNTIME=1 \
	-s NODEJS_CATCH_EXIT=0 \
	-s MODULARIZE=1 \
	-s ALLOW_MEMORY_GROWTH=1 \
	-s WARN_UNALIGNED=1 \
	-s EXPORT_NAME="'ZR'" \
	-s ASSERTIONS=1 \
	--no-heap-copy
javascript-wasm: apply-patches lua53 milagro embed-lua
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
	make -C src js
	@mkdir -p build/wasm
	@cp -v src/zenroom.js build/wasm/
	@cp -v src/zenroom.wasm build/wasm/

javascript-rn: cflags += -DARCH_JS -D'ARCH=\"JS\"' -D MAX_STRING=128000
javascript-rn: ldflags += -s WASM=0 \
	-s ENVIRONMENT=\"'shell'\" \
	-s MODULARIZE=1 \
	-s LEGACY_VM_SUPPORT=1 \
	-s ASSERTIONS=1 \
	-s EXIT_RUNTIME=1 \
	--memory-init-file 0
javascript-rn: apply-patches lua53 milagro embed-lua
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
	make -C src js
	sed -i 's/require("crypto")/require(".\/crypto")/g' src/zenroom.js
	sed -i 's/require("[^\.]/console.log("/g' src/zenroom.js
	sed -i 's/console.warn.bind/console.log.bind/g' src/zenroom.js
	@mkdir -p build/rnjs
	@cp -v src/zenroom.js 	  build/rnjs/

javascript-npm: javascript-wasm
	@mkdir -p build/npm
	@cp -v build/wasm/zenroom.js build/npm/
	@cp -v build/wasm/zenroom.wasm build/npm/
	@echo "module.exports = ZR();" >> build/npm/zenroom.js

javascript-wasm-web: cflags  += -DARCH_WASM -D'ARCH=\"WASM\"' -D MAX_STRING=128000
javascript-wasm-web: ldflags += -s WASM=1 \
	-s ENVIRONMENT=\"'web'\" \
	-s INVOKE_RUN=0 \
	-s EXIT_RUNTIME=1 \
	-s NODEJS_CATCH_EXIT=0 \
	-s MODULARIZE=1 \
	-s ALLOW_MEMORY_GROWTH=1 \
	-s WARN_UNALIGNED=1 \
	-s EXPORT_NAME="'ZR'" \
	--no-heap-copy
javascript-wasm-web: apply-patches lua53 milagro embed-lua
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
	make -C src js
	@mkdir -p build/wasm-web
	@cp -v src/zenroom.js build/wasm-web/
	@cp -v src/zenroom.wasm build/wasm-web/
