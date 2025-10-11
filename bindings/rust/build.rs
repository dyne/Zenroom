use std::env;
use std::path::PathBuf;
use std::process::Command;

fn main() {
    let zenroom_root = PathBuf::from(env::var("CARGO_MANIFEST_DIR").unwrap())
        .parent()
        .unwrap()
        .parent()
        .unwrap()
        .to_path_buf();

    let target_os = env::var("CARGO_CFG_TARGET_OS").unwrap();
    let target_arch = env::var("CARGO_CFG_TARGET_ARCH").unwrap();
    let target_env = env::var("CARGO_CFG_TARGET_ENV").unwrap_or_default();

    let bundled = env::var("CARGO_FEATURE_BUNDLED").is_ok();
    let buildtime_bindgen = env::var("CARGO_FEATURE_BUILDTIME_BINDGEN").is_ok();
    let use_static = bundled || env::var("ZENROOM_STATIC").map_or(false, |v| v != "0");

    println!("cargo:rerun-if-changed=../../src/zenroom.h");
    println!("cargo:rerun-if-changed=../../src/zenroom.c");
    println!("cargo:rerun-if-env-changed=ZENROOM_STATIC");

    let config = detect_platform(&target_os, &target_arch, &target_env, use_static);

    if bundled {
        println!("cargo:warning=Building Zenroom from source (bundled feature)");
        build_library(&zenroom_root, &config);
    } else {
        let lib_file = zenroom_root.join(&config.lib_name);
        if !lib_file.exists() {
            panic!(
                "Zenroom library not found: {}\n\
                \n\
                Options:\n\
                1. Use --features bundled to build from source\n\
                2. Build library manually: cd {} && make {}\n\
                3. Install system package (if available)",
                lib_file.display(),
                zenroom_root.display(),
                config.make_target
            );
        }
    }

    println!("cargo:rustc-link-search=native={}", zenroom_root.display());
    configure_linker(&config);

    if buildtime_bindgen {
        println!("cargo:warning=Generating bindings at build time");
        generate_bindings(&zenroom_root);
    } else if !has_pregenerated_bindings(&target_os, &target_arch, &target_env) {
        println!("cargo:warning=No pre-generated bindings, using bindgen");
        generate_bindings(&zenroom_root);
    }

    println!("cargo:warning=Configured for {} ({})",
        config.description,
        if config.is_static { "static" } else { "dynamic" }
    );
}

struct PlatformConfig {
    make_target: String,
    lib_name: String,
    is_static: bool,
    needs_cpp: bool,
    description: String,
}

fn detect_platform(target_os: &str, target_arch: &str, target_env: &str, use_static: bool) -> PlatformConfig {
    match target_os {
        "macos" | "linux" => {
            let (dylib_ext, make_target) = if target_os == "macos" {
                ("dylib", "osx-lib")
            } else {
                ("so", "linux-lib")
            };

            PlatformConfig {
                make_target: make_target.to_string(),
                lib_name: if use_static {
                    "libzenroom.a".to_string()
                } else {
                    format!("libzenroom.{}", dylib_ext)
                },
                is_static: use_static,
                needs_cpp: use_static,
                description: format!("{} {}", target_os, target_arch),
            }
        }
        "ios" => {
            // App Store policy requires static linking
            let is_sim = target_env == "sim" || target_arch == "x86_64";
            PlatformConfig {
                make_target: if is_sim { "ios-sim" } else { "ios-arm64" }.to_string(),
                lib_name: if is_sim {
                    "zenroom-ios-sim.a"
                } else {
                    "zenroom-ios-arm64.a"
                }.to_string(),
                is_static: true,
                needs_cpp: true,
                description: format!("iOS {} {}", if is_sim { "Simulator" } else { "Device" }, target_arch),
            }
        }
        _ => panic!(
            "Unsupported target OS: {}. Supported: macOS, Linux, iOS.",
            target_os
        ),
    }
}

fn build_library(zenroom_root: &PathBuf, config: &PlatformConfig) {
    let status = Command::new("make")
        .current_dir(zenroom_root)
        .arg(&config.make_target)
        .status();

    match status {
        Ok(exit_status) if exit_status.success() => {
            println!("cargo:warning=Built library using make {}", config.make_target);
        }
        Ok(_) => {
            panic!(
                "Failed to build Zenroom with 'make {}'. \
                \n\nRequired tools: make, gcc/clang, cmake\
                \n\nSee: https://github.com/dyne/Zenroom#build",
                config.make_target
            );
        }
        Err(e) => {
            panic!("Failed to execute make: {}. Ensure make is installed.", e);
        }
    }

    if config.is_static && !config.make_target.starts_with("ios") {
        create_static_archive(zenroom_root, config);
    }
}

fn create_static_archive(zenroom_root: &PathBuf, config: &PlatformConfig) {
    println!("cargo:warning=Creating static archive for bundled build");

    let mut ar_inputs = Vec::new();

    for obj in &[
        "src/zenroom.o", "src/zen_error.o", "src/lua_functions.o",
        "src/lua_modules.o", "src/lualibs_detected.o", "src/lua_shims.o",
        "src/encoding.o", "src/base58.o", "src/rmd160.o", "src/segwit_addr.o",
        "src/zen_memory.o", "src/mutt_sprintf.o", "src/varint.o", "src/zen_varint.o",
        "src/zen_io.o", "src/zen_parse.o", "src/zen_config.o", "src/zen_octet.o",
        "src/zen_ecp.o", "src/zen_ecp2.o", "src/zen_big.o", "src/zen_fp12.o",
        "src/zen_random.o", "src/zen_hash.o", "src/zen_ecdh_factory.o", "src/zen_ecdh.o",
        "src/zen_x509.o", "src/zen_aes.o", "src/zen_qp.o", "src/zen_ed.o",
        "src/zen_float.o", "src/zen_time.o", "src/api_hash.o", "src/api_sign.o",
        "src/randombytes.o", "src/zen_fuzzer.o", "src/cortex_m.o", "src/p256-m.o",
        "src/zen_p256.o", "src/zen_rsa.o", "src/zen_bbs.o", "src/zen_longfellow.o",
    ] {
        let path = zenroom_root.join(obj);
        if path.exists() {
            ar_inputs.push(path);
        }
    }

    for lib in &[
        "lib/lua54/src/liblua.a",
        "lib/milagro-crypto-c/build/lib/libamcl_core.a",
        "lib/milagro-crypto-c/build/lib/libamcl_curve_BLS381.a",
        "lib/milagro-crypto-c/build/lib/libamcl_pairing_BLS381.a",
        "lib/milagro-crypto-c/build/lib/libamcl_curve_SECP256K1.a",
        "lib/milagro-crypto-c/build/lib/libamcl_rsa_2048.a",
        "lib/milagro-crypto-c/build/lib/libamcl_rsa_4096.a",
        "lib/milagro-crypto-c/build/lib/libamcl_x509.a",
        "lib/ed25519-donna/libed25519.a",
        "lib/pqclean/libqpz.a",
        "lib/mlkem/test/build/libmlkem.a",
        "lib/longfellow-zk/liblongfellow-zk.a",
        "lib/zstd/libzstd.a",
    ] {
        let path = zenroom_root.join(lib);
        if path.exists() {
            ar_inputs.push(path);
        }
    }

    if ar_inputs.is_empty() {
        panic!("No object files found for static archive. Build may have failed.");
    }

    let lib_path = zenroom_root.join(&config.lib_name);

    if config.make_target == "osx-lib" {
        let mut cmd = Command::new("libtool");
        cmd.arg("-static").arg("-o").arg(&lib_path);
        for input in &ar_inputs {
            cmd.arg(input);
        }

        let status = cmd.status().expect("Failed to run libtool");
        if !status.success() {
            panic!("Failed to create static archive with libtool");
        }
    } else {
        let mut cmd = Command::new("ar");
        cmd.arg("rcs").arg(&lib_path);
        for input in &ar_inputs {
            cmd.arg(input);
        }

        let status = cmd.status().expect("Failed to run ar");
        if !status.success() {
            panic!("Failed to create static archive with ar");
        }
    }

    println!("cargo:warning=Created static archive: {}", lib_path.display());

    // Linker prefers dylib over .a when both exist
    let dylib_ext = if config.make_target == "osx-lib" { "dylib" } else { "so" };
    let dylib_path = zenroom_root.join(format!("libzenroom.{}", dylib_ext));
    if dylib_path.exists() {
        std::fs::remove_file(&dylib_path).ok();
        println!("cargo:warning=Removed {} (using static link)", dylib_path.display());
    }
}

fn configure_linker(config: &PlatformConfig) {
    if config.is_static {
        println!("cargo:rustc-link-lib=static=zenroom");
        if config.needs_cpp {
            println!("cargo:rustc-link-lib=c++");
        }
    } else {
        println!("cargo:rustc-link-lib=dylib=zenroom");
    }
}

fn generate_bindings(_zenroom_root: &PathBuf) {
    #[cfg(feature = "buildtime_bindgen")]
    {
        let bindings = bindgen::Builder::default()
            .header(_zenroom_root.join("src/zenroom.h").to_str().unwrap())
            .allowlist_function("zencode_exec")
            .allowlist_function("zencode_exec_tobuf")
            .allowlist_function("zenroom_exec")
            .allowlist_function("zenroom_exec_tobuf")
            .allowlist_function("zen_init")
            .allowlist_function("zen_init_extra")
            .allowlist_function("zen_exec_zencode")
            .allowlist_function("zen_exec_lua")
            .allowlist_function("zen_teardown")
            .allowlist_var("SUCCESS")
            .allowlist_var("ERR_GENERIC")
            .allowlist_var("ERR_EXEC")
            .allowlist_var("ERR_PARSE")
            .allowlist_var("ERR_INIT")
            .use_core()
            .generate()
            .expect("Unable to generate bindings. Ensure clang/llvm is installed.");

        let out_path = PathBuf::from(env::var("OUT_DIR").unwrap());
        bindings
            .write_to_file(out_path.join("bindings.rs"))
            .expect("Couldn't write bindings");
    }

    #[cfg(not(feature = "buildtime_bindgen"))]
    {
        panic!(
            "No pre-generated bindings for this platform.\n\
            Use: cargo build --features buildtime_bindgen"
        );
    }
}

fn has_pregenerated_bindings(target_os: &str, target_arch: &str, target_env: &str) -> bool {
    matches!(
        (target_os, target_arch, target_env),
        ("macos", "aarch64", _) |
        ("ios", "aarch64", "sim") |
        ("ios", "aarch64", "") |
        ("linux", "x86_64", _) |
        ("linux", "aarch64", _)
    )
}
