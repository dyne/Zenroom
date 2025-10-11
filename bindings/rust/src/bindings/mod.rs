// Platform-specific FFI bindings (pre-generated or from bindgen)

#[cfg(all(
    not(feature = "buildtime_bindgen"),
    target_arch = "aarch64",
    target_os = "macos"
))]
include!("macos_arm64.rs");

#[cfg(all(
    not(feature = "buildtime_bindgen"),
    target_arch = "aarch64",
    target_os = "ios",
    not(target_env = "sim")
))]
include!("ios_arm64.rs");

#[cfg(all(
    not(feature = "buildtime_bindgen"),
    target_arch = "aarch64",
    target_os = "ios",
    target_env = "sim"
))]
include!("ios_sim_arm64.rs");

#[cfg(all(
    not(feature = "buildtime_bindgen"),
    target_arch = "x86_64",
    target_os = "linux"
))]
include!("linux_x86_64.rs");

#[cfg(all(
    not(feature = "buildtime_bindgen"),
    target_arch = "aarch64",
    target_os = "linux"
))]
include!("linux_aarch64.rs");

// Fallback to runtime bindgen if no pre-generated bindings match
#[cfg(any(
    feature = "buildtime_bindgen",
    not(any(
        all(target_arch = "aarch64", target_os = "macos"),
        all(target_arch = "aarch64", target_os = "ios"),
        all(target_arch = "x86_64", target_os = "linux"),
        all(target_arch = "aarch64", target_os = "linux")
    ))
))]
include!(concat!(env!("OUT_DIR"), "/bindings.rs"));
