extern crate bindgen;
extern crate meson;

use std::env;
use std::path::PathBuf;

fn main() {
    let build_path = PathBuf::from(env::var("OUT_DIR").unwrap()).join("build");
    let build_path = build_path.join("build");
    let build_path = build_path.to_str().unwrap();
    meson::build("../../build", build_path);

    println!("cargo:rustc-link-lib=static=zenroom");
    println!("cargo:rustc-link-lib=static=lua");
    println!("cargo:rustc-link-lib=static=amcl_bls_BLS383");
    println!("cargo:rustc-link-lib=static=amcl_core");
    println!("cargo:rustc-link-lib=static=amcl_curve_BLS383");
    println!("cargo:rustc-link-lib=static=amcl_curve_SECP256K1");
    println!("cargo:rustc-link-lib=static=amcl_pairing_BLS383");
    println!("cargo:rustc-link-search={}", build_path);
    println!(
        "cargo:rustc-link-search={}/milagro-crypto-c/lib",
        build_path
    );

    println!("cargo:rerun-if-changed=wrapper.h");

    let bindings = bindgen::Builder::default()
        .header("wrapper.h")
        .clang_arg("-I../../src")
        .clang_arg(format!("-I{}", build_path))
        .parse_callbacks(Box::new(bindgen::CargoCallbacks))
        .generate()
        .expect("Unable to generate bindings");

    let out_path = PathBuf::from(env::var("OUT_DIR").unwrap());
    bindings
        .write_to_file(out_path.join("bindings.rs"))
        .expect("Couldn't write bindings!");
}
