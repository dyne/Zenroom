## Initialize build defaults
include build/init.mk

# Add here any function used from JS
WASM_EXPORTS := '["_malloc","_zenroom_exec","_zencode_exec","_zenroom_hash_init","_zenroom_hash_update","_zenroom_hash_final","_zencode_valid_input","_zencode_valid_code"]'

# EMSDK should point to installation of EMSDK i.e.: /opt/emsdk
EMSCRIPTEN ?= ${EMSDK}/upstream/emscripten
cc := ${EMSCRIPTEN}/emcc
ar := ${EMSCRIPTEN}/emar
ld := ${cc}
ranlib := ${EMSCRIPTEN}/emranlib
system := Javascript
ld_emsdk_settings := -I ${EMSCRIPTEN}/system/include/libc -DLIBRARY
ld_emsdk_settings += -sMODULARIZE=1	-sSINGLE_FILE=1 --embed-file 'src/lua@/'
ld_emsdk_settings += -sMALLOC=dlmalloc --no-heap-copy -sALLOW_MEMORY_GROWTH=1
ld_emsdk_settings += -sINITIAL_MEMORY=${JS_INIT_MEM} -sMAXIMUM_MEMORY=${JS_MAX_MEM} -sSTACK_SIZE=${JS_STACK_SIZE}
ld_emsdk_settings += -sINCOMING_MODULE_JS_API=print,printErr -s EXPORTED_FUNCTIONS=${WASM_EXPORTS} -s EXPORTED_RUNTIME_METHODS='["ccall","cwrap"]'
ld_emsdk_optimizations := -O2 -sSTRICT -flto -sUSE_SDL=0 -sEVAL_CTORS=1
cc_emsdk_settings := -DARCH_WASM -D'ARCH="WASM"'
cc_emsdk_optimizations := -O2 -sSTRICT -flto -fno-rtti -fno-exceptions
# lua_embed_opts := "compile"
ldflags += -lm ${ld_emsdk_optimizations} ${ld_emsdk_settings}
cflags += -DLIBCMALLOC ${cc_emsdk_settings} ${cc_emsdk_optimizations}

all: ${BUILD_DEPS} zenroom.js

zenroom.js: ${ZEN_SOURCES}
	$(info === Linking Zenroom WASM for Javascript)
	${cc} ${cflags} ${ZEN_SOURCES} \
		-o $@ ${ldflags} ${ldadd}

include build/deps.mk
