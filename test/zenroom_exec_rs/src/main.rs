extern crate zenroom;
use std::time::Instant;
use std::env;
use std::path::PathBuf;
use std::io::prelude::*;
use std::fs::File;
use encoding::{Encoding, DecoderTrap};
use encoding::all::ISO_8859_1;
fn main() {
    // TODO: improve reading of command line arguments (clap library)
    let args: Vec<String> = env::args().collect();
    let script_path = &args[1];
    let script_name = &args[2];
    let final_path = PathBuf::from(script_path).join(script_name);
    let final_path = final_path.to_str().unwrap();

    // read file
    let mut f = File::open(final_path).unwrap();
    let mut buffer = Vec::new();
    f.read_to_end(&mut buffer).unwrap();

    let script = String::from_utf8(buffer.clone()).or_else(
        |_| ISO_8859_1.decode(&buffer, DecoderTrap::Strict)).unwrap();


    println!("[RS] zenroom_exec {}", script_name);
    let now = Instant::now();
    let result = zenroom::zenroom_exec(script, "", "", "");
    let elapsed_time = now.elapsed();
    println!("{:?}", result);
    println!("--- {} seconds ---", elapsed_time.as_secs());
    println!("@ {} @", (0..40).map(|_| "=").collect::<String>());
}

