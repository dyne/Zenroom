# Zenroom Rust Bindings

Rust FFI bindings for [Zenroom](https://zenroom.org/), a cryptographic VM for smart contracts and zero-knowledge proofs.

## Features

- Pre-generated FFI bindings (no clang/llvm dependency)
- Static or dynamic linking
- Cross-platform: macOS, Linux, iOS
- Direct C library calls via FFI

## Quick Start

```toml
[dependencies]
zenroom = { version = "0.3", features = ["bundled"] }
```

```rust
use zenroom::zencode_exec;

let script = r#"
    Scenario 'ecdh': Create the keypair
    Given that I am known as 'Alice'
    When I create the ecdh key
    Then print my 'keyring'
"#;

match zencode_exec(script, "", "", "") {
    Ok(result) => println!("{}", result.output),
    Err(e) => eprintln!("Error: {}", e),
}
```

## Build Configuration

### Bundled Build

The `bundled` feature builds Zenroom from source and statically links it, producing self-contained binaries with no runtime library dependencies.

```bash
cargo build --features bundled
```

Requires: make, gcc/clang, cmake

### System Library

Without the `bundled` feature, links against an existing `libzenroom.dylib` or `libzenroom.so`.

```bash
# Build the library first
cd /path/to/zenroom && make osx-lib

# Then build your project
cargo build
```

For development with system library on macOS:

```bash
DYLD_FALLBACK_LIBRARY_PATH=/path/to/zenroom cargo test --lib -- --test-threads=1
```

## API

### zencode_exec

```rust
pub fn zencode_exec(
    script: &str,
    conf: &str,
    keys: &str,
    data: &str,
) -> Result<ZenResult, ZenError>
```

### zencode_exec_extra

```rust
pub fn zencode_exec_extra(
    script: &str,
    conf: &str,
    keys: &str,
    data: &str,
    extra: &str,
    context: &str,
) -> Result<ZenResult, ZenError>
```

### Error Handling

```rust
match zencode_exec(script, "", "", "") {
    Ok(result) => {
        println!("Output: {}", result.output);
        println!("Logs: {}", result.logs);
    }
    Err(ZenError::Execution(result)) => {
        eprintln!("Failed: {}", result.logs);
    }
    Err(ZenError::InvalidInput(err)) => {
        eprintln!("Invalid input: {}", err);
    }
}
```

## Platform Support

Pre-generated bindings are available for:
- macOS ARM64 (aarch64-apple-darwin)
- iOS device (aarch64-apple-ios)
- iOS simulator (aarch64-apple-ios-sim, x86_64-apple-ios)
- Linux x86_64 (x86_64-unknown-linux-gnu)
- Linux ARM64 (aarch64-unknown-linux-gnu)

Other platforms will automatically generate bindings at build time using bindgen (requires clang/llvm).

### iOS

```bash
rustup target add aarch64-apple-ios
cargo build --target aarch64-apple-ios --features bundled --release
```

iOS always uses static linking.

## Thread Safety

Zenroom uses global state and is not thread-safe. Concurrent execution will cause crashes.

Safe:
```rust
for script in scripts {
    zencode_exec(script, "", "", "")?;
}
```

Unsafe:
```rust
std::thread::scope(|s| {
    for script in scripts {
        s.spawn(|| zencode_exec(script, "", "", ""));  // will crash
    }
});
```

For concurrent operations, use process isolation.

## Features

### bundled

Build Zenroom from source and statically link it.

```bash
cargo build --features bundled
```

### buildtime_bindgen

Generate FFI bindings at build time instead of using pre-generated ones.

```bash
cargo build --features buildtime_bindgen
```

Requires clang/llvm. Useful for unsupported platforms or when updating bindings.

## Environment Variables

### ZENROOM_STATIC

Force static linking without the bundled feature:

```bash
ZENROOM_STATIC=1 cargo build
```

Requires `libzenroom.a` to exist.

## Development

### Running Tests

```bash
cargo test --features bundled --lib -- --test-threads=1
```

The `--test-threads=1` flag is required due to Zenroom's global state.

### Regenerating Bindings

```bash
./regenerate_bindings.sh
```

The script will automatically detects your platform and generates the appropriate bindings file(s).

## Troubleshooting

### Library not found

Use the `bundled` feature to embed the library in your binary:

```toml
zenroom = { version = "0.3", features = ["bundled"] }
```

### Bindgen errors

Install clang/llvm or use pre-generated bindings by removing the `buildtime_bindgen` feature.

```bash
# macOS
xcode-select --install

# Linux
sudo apt-get install llvm-dev libclang-dev clang
```


## License

AGPL-3.0