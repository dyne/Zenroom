use zenroom;
use std::time::Instant;
use std::env;
use std::path::PathBuf;
use std::io::prelude::*;
use std::fs::File;
use encoding::{Encoding, DecoderTrap};
use encoding::all::ISO_8859_1;
fn main() {
    // TODO: improve reading of command line arguments (clap library)
    let mut final_path = PathBuf::from("/");
    for arg in env::args() {
        final_path.push(PathBuf::from(arg));
    }
    let final_path = final_path.to_str().unwrap();

    // read file
    let mut f = File::open(final_path).unwrap();
    let mut buffer = Vec::new();
    f.read_to_end(&mut buffer).unwrap();

    let script = String::from_utf8(buffer.clone()).or_else(
        |_| ISO_8859_1.decode(&buffer, DecoderTrap::Strict)).unwrap();


    println!("[RS] zenroom_exec {}", final_path);
    let now = Instant::now();
    let result = zenroom::zenroom_exec(script, "", "", "");
    let elapsed_time = now.elapsed();
    println!("{:?}", result);
    println!("--- {} seconds ---", elapsed_time.as_secs() as f32
             + elapsed_time.subsec_micros() as f32 * 1e-6);
    println!("@ {} @", (0..40).map(|_| "=").collect::<String>());
}

