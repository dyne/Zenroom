extern crate bindgen;

use std::env;
use std::path::PathBuf;
use std::process::Command;

fn main() {
    // let mut cmd = Command::new("make");
    // cmd.args(&["-C", "../..", "meson"]);
    // let status = cmd.status().expect("failed to run meson");
    // let status = cmd.status().exit_ok();
    // TODO: use status.exit_ok() when it gets to stable
    // assert!(status.success());
    let build_path = PathBuf::from(env::current_dir().unwrap());
    let build_path = build_path.join("..").join("..").join("meson");
    let build_path = build_path.to_str().unwrap();

    println!("cargo:rustc-link-lib=static=zenroom");
    println!("cargo:rustc-link-lib=static=lua");
    println!("cargo:rustc-link-lib=static=qpz");
    println!("cargo:rustc-link-lib=static=amcl_bls_BLS381");
    println!("cargo:rustc-link-lib=static=amcl_core");
    println!("cargo:rustc-link-lib=static=amcl_curve_BLS381");
    println!("cargo:rustc-link-lib=static=amcl_curve_SECP256K1");
    println!("cargo:rustc-link-lib=static=amcl_pairing_BLS381");
    println!("cargo:rustc-link-lib=static=zstd");
    println!("cargo:rustc-link-search={}", build_path);
    println!("cargo:rustc-link-search={}/milagro-crypto-c/lib",build_path);

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
