## Initialize build defaults
include build/init.mk

JS_INIT_MEM :=8MB
JS_MAX_MEM := 1024MB
JS_STACK_SIZE := 7MB

# Add here any function used from JS
WASM_EXPORTS := '["_malloc","_free","_calloc","_realloc","_zenroom_exec","_zencode_exec","_zenroom_hash_init","_zenroom_hash_update","_zenroom_hash_final","_zencode_valid_input","_zencode_valid_code","_zencode_get_statements"]'

# EMSDK should point to installation of EMSDK i.e.: /opt/emsdk
EMSCRIPTEN ?= ${EMSDK}/upstream/emscripten
cc := ${EMSCRIPTEN}/emcc
cxx := ${EMSCRIPTEN}/em++
ar := ${EMSCRIPTEN}/emar
ld := ${cxx}
ranlib := ${EMSCRIPTEN}/emranlib

quantum_proof_cc := ${cc}
ed25519_cc := ${cc}
libcc_cc := ${cc}
lua_cc := ${cc}
zenroom_cc := ${cc}
zstd_cc := ${cc}
longfellow_cxx := ${cxx}
longfellow_cflags := -I ${pwd}/src -I. -I../zstd -fPIC -DLIBRARY -msimd128
zk-circuit-lang_cxxflags := -I ${pwd}/src -I. -I../zstd -fPIC -DLIBRARY -msimd128 -I ../lua54/src -I../longfellow-zk

system := Javascript
ld_emsdk_settings := -I ${EMSCRIPTEN}/system/include/libc -DLIBRARY
ld_emsdk_settings += -sMODULARIZE=1	-sSINGLE_FILE=1 --embed-file 'src/lua@/'
ld_emsdk_settings += -sMALLOC=dlmalloc --no-heap-copy -sALLOW_MEMORY_GROWTH=1
ld_emsdk_settings += -sINITIAL_MEMORY=${JS_INIT_MEM} -sMAXIMUM_MEMORY=${JS_MAX_MEM} -sSTACK_SIZE=${JS_STACK_SIZE} -sASSERTIONS
ld_emsdk_settings += -sINCOMING_MODULE_JS_API=print,printErr -s EXPORTED_FUNCTIONS=${WASM_EXPORTS} -s EXPORTED_RUNTIME_METHODS='["ccall","cwrap"]'
ld_emsdk_optimizations := -O2 -sSTRICT -flto -sUSE_SDL=0 -sEVAL_CTORS=1
cc_emsdk_settings := -DARCH_WASM -D'ARCH="WASM"'
cc_emsdk_optimizations := -O2 -sSTRICT -flto -fno-rtti -fno-exceptions
# lua_embed_opts := "compile"
ldflags += -lm ${ld_emsdk_optimizations} ${ld_emsdk_settings}
cflags += ${cc_emsdk_settings} ${cc_emsdk_optimizations}

all: ${BUILD_DEPS} zenroom.js zenroom.web.js

zenroom.js: ${ZEN_SOURCES}
	$(info === Linking Zenroom WASM for Javascript)
	${ld} ${cflags} ${ZEN_SOURCES} \
		-o $@ ${ldflags} ${ldadd}

zenroom.web.js: ${ZEN_SOURCES}
	$(info === Linking Zenroom WASM for the web)
	${ld} ${cflags} ${ZEN_SOURCES} \
		-o $@ ${ldflags} -sEXPORT_ES6 ${ldadd}

include build/deps.mk
