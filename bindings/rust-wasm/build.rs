extern crate bindgen;

use std::env;
use std::path::PathBuf;

fn main() {
    cc::Build::new()
        .define("LIBRARY","1")
        .define("ARCH","\"WASM\"")
        .define("ARCH_LINUX","1")
        .define("LUA_USE_POSIX","1")

        .include("../../src")
        .include("../../lib/lua53/src")
        .include("../../lib/milagro-crypto-c/build/include")
        .include("../../lib/milagro-crypto-c/include")
        .include("../../lib/zstd")
        .include("../../lib/blake2")
        .include("../../lib/ed25519-donna")
        .include("../../lib/pqclean")

    // milagro
        .file("../../lib/milagro-crypto-c/src/rand.c")
        .file("../../lib/milagro-crypto-c/src/oct.c")
        .file("../../lib/milagro-crypto-c/src/hash.c")
        .file("../../lib/milagro-crypto-c/src/gcm.c")
        .file("../../lib/milagro-crypto-c/src/ecdh_support.c")
        .file("../../lib/milagro-crypto-c/src/aes.c")

    // lua
        .file("../../lib/lua53/src/lzio.c")
        .file("../../lib/lua53/src/lvm.c")
        .file("../../lib/lua53/src/lutf8lib.c")
        .file("../../lib/lua53/src/lundump.c")
        .file("../../lib/lua53/src/luac.c")
        .file("../../lib/lua53/src/lua.c")
        .file("../../lib/lua53/src/ltm.c")
        .file("../../lib/lua53/src/ltablib.c")
        .file("../../lib/lua53/src/ltable.c")
        .file("../../lib/lua53/src/lstrlib.c")
        .file("../../lib/lua53/src/lstring.c")
        .file("../../lib/lua53/src/lstate.c")
        .file("../../lib/lua53/src/lparser.c")
        .file("../../lib/lua53/src/lopcodes.c")
        .file("../../lib/lua53/src/lobject.c")
        .file("../../lib/lua53/src/loadlib.c")
        .file("../../lib/lua53/src/lmem.c")
        .file("../../lib/lua53/src/lmathlib.c")
        .file("../../lib/lua53/src/llex.c")
        .file("../../lib/lua53/src/linit.c")
        .file("../../lib/lua53/src/lgc.c")
        .file("../../lib/lua53/src/lfunc.c")
        .file("../../lib/lua53/src/ldump.c")
        .file("../../lib/lua53/src/ldo.c")
        .file("../../lib/lua53/src/ldebug.c")
        .file("../../lib/lua53/src/ldblib.c")
        .file("../../lib/lua53/src/lctype.c")
        .file("../../lib/lua53/src/lcorolib.c")
        .file("../../lib/lua53/src/lcode.c")
        .file("../../lib/lua53/src/lbitlib.c")
        .file("../../lib/lua53/src/lbaselib.c")
        .file("../../lib/lua53/src/lauxlib.c")
        .file("../../lib/lua53/src/lapi.c")

// zenroom
        .file("../../src/base58.c")
        .file("../../src/zen_random.c")
        .file("../../src/zen_qp.c")
        .file("../../src/zen_parse.c")
        .file("../../src/zen_memory.c")
        .file("../../src/zen_io.c")
        .file("../../src/zen_hash.c")
        .file("../../src/zen_fp12.c")
        .file("../../src/zen_float.c")
        .file("../../src/zen_error.c")
        .file("../../src/zen_ed.c")
        .file("../../src/zen_ecp.c")
        .file("../../src/zen_ecp2.c")
        .file("../../src/zen_ecdh.c")
        .file("../../src/zen_config.c")
        .file("../../src/zen_aes.c")
        .file("../../src/segwit_addr.c")
        .file("../../src/rmd160.c")
        .file("../../src/randombytes.c")
        .file("../../src/mutt_sprintf.c")
        .file("../../src/lua_shims.c")
        .file("../../src/lua_modules.c")
        .file("../../src/zen_octet.c")
        .file("../../src/zen_big.c")
        .file("../../src/encoding.c")
        .file("../../src/zenroom.c")
        .file("../../src/lua_functions.c")
        .file("../../src/zen_ecdh_factory.c")
        .file("../../src/lualibs_detected.c")
        .compile("zenroom");
    println!("cargo:rerun-if-changed=../../src/*");

    let bindings = bindgen::Builder::default()
        .header("wrapper.h")
        .clang_arg("-I../../src")
        .parse_callbacks(Box::new(bindgen::CargoCallbacks))
        .generate()
        .expect("Unable to generate bindings");

    let out_path = PathBuf::from(env::var("OUT_DIR").unwrap());
    bindings
        .write_to_file(out_path.join("bindings.rs"))
        .expect("Couldn't write bindings!");
}
