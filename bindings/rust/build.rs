extern crate bindgen;

use std::env;
use std::path::PathBuf;

fn main() {
    println!("cargo:rustc-link-lib=static=zenroom");
    println!("cargo:rustc-link-lib=static=lua");
    println!("cargo:rustc-link-lib=static=qpz");
    println!("cargo:rustc-link-lib=static=amcl_bls_BLS381");
    println!("cargo:rustc-link-lib=static=amcl_core");
    println!("cargo:rustc-link-lib=static=amcl_curve_BLS381");
    println!("cargo:rustc-link-lib=static=amcl_curve_SECP256K1");
    println!("cargo:rustc-link-lib=static=amcl_pairing_BLS381");
    println!("cargo:rustc-link-lib=static=ed25519");
    println!("cargo:rustc-link-lib=static=zstd");
    println!("cargo:rustc-link-search=native=clib");

    println!("cargo:rerun-if-changed=wrapper.h");

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
