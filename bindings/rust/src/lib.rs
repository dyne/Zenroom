use base64::{engine::general_purpose, Engine as _};
use std::fmt;
use std::io::prelude::*;
use std::process::{Command, Stdio};

#[derive(Clone, Debug)]
pub struct ZenResult {
    pub output: String,
    pub logs: String,
}

#[derive(Clone, Debug)]
pub enum ZenError {
    Execution(ZenResult),
    InvalidInput(std::ffi::NulError),
}

impl From<std::ffi::NulError> for ZenError {
    fn from(err: std::ffi::NulError) -> Self {
        Self::InvalidInput(err)
    }
}

impl fmt::Display for ZenError {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        match self {
            Self::Execution(err) => f.write_fmt(format_args!("Execution Error:\n{}", err.logs)),
            Self::InvalidInput(err) => f.write_fmt(format_args!("Invalid input: {}", err)),
        }
    }
}

pub fn zencode_exec_extra(
    script: &str,
    conf: &str,
    keys: &str,
    data: &str,
    extra: &str,
    context: &str,
) -> Result<ZenResult, ZenError> {
    let mut zen_input: String = "".to_owned();

    zen_input.push_str(conf);
    zen_input.push_str("\n");

    zen_input.push_str(&general_purpose::STANDARD.encode(script));
    zen_input.push_str("\n");

    zen_input.push_str(&general_purpose::STANDARD.encode(&keys));
    zen_input.push_str("\n");

    zen_input.push_str(&general_purpose::STANDARD.encode(&data));
    zen_input.push_str("\n");

    zen_input.push_str(&general_purpose::STANDARD.encode(&extra));
    zen_input.push_str("\n");

    zen_input.push_str(&general_purpose::STANDARD.encode(&context));
    zen_input.push_str("\n");

    let mut child = Command::new("zencode-exec")
        .stdin(Stdio::piped())
        .stderr(Stdio::piped())
        .stdout(Stdio::piped())
        .spawn()
        .unwrap();
    let mut stdin = child.stdin.take().unwrap();

    std::thread::spawn(move || {
        stdin
            .write_all(zen_input.as_bytes())
            .expect("Failed to write to stdin");
    });

    let output = child.wait_with_output().expect("Failed to read stdout");
    Ok(ZenResult {
        output: String::from_utf8_lossy(&output.stdout).to_string(),
        logs: String::from_utf8_lossy(&output.stderr).to_string(),
    })
}

pub fn zencode_exec(
    script: &str,
    conf: &str,
    keys: &str,
    data: &str,
) -> Result<ZenResult, ZenError> {
    zencode_exec_extra(script, conf, keys, data, "", "")
}

/*pub fn zenroom_exec(
    script: impl AsRef<str>,
    conf: impl AsRef<str>,
    keys: impl AsRef<str>,
    data: impl AsRef<str>,
) -> Result<ZenResult, ZenError> {
    exec_f(c::zenroom_exec_tobuf, script, conf, keys, data)
}*/

#[cfg(test)]
mod tests {
    use crate::*;
    use serde_json::Value;

    const SAMPLE_SCRIPT: &str = r#"
    Scenario 'ecdh': Create the keypair
    Scenario 'schnorr'
    Given that I am known as 'Alice'
    When I create the ecdh key
    and I create the schnorr key
    Then print my 'keyring'
    "#;

    const EXTRA_USAGE: &str = r#"Scenario 'ecdh': Create the keypair
Given I have a 'string' named 'keys'
Given I have a 'string' named 'data'
Given I have a 'string' named 'extra'
Then print data
"#;
    #[test]
    fn simple_script() -> Result<(), ZenError> {
        let result = zencode_exec(SAMPLE_SCRIPT, "", "", "")?;

        let json: Value = serde_json::from_str(&result.output).unwrap();
        println!("{}", result.output);
        let keypair = json
            .as_object()
            .unwrap()
            .get("Alice")
            .unwrap()
            .get("keyring")
            .unwrap();
        assert!(keypair.get("ecdh").is_some());
        assert!(keypair.get("schnorr").is_some());

        Ok(())
    }

    #[test]
    fn extra_usage() -> Result<(), ZenError> {
        let result = zencode_exec_extra(
            EXTRA_USAGE,
            "",
            "{\"keys\": \"keys\"}",
            "{\"data\": \"data\"}",
            "{\"extra\": \"extra\"}",
            "",
        )?;

        let json: Value = serde_json::from_str(&result.output).unwrap();
        assert!(json.get("data").unwrap() == "data");
        assert!(json.get("extra").unwrap() == "extra");
        assert!(json.get("keys").unwrap() == "keys");

        Ok(())
    }

    #[test]
    fn threaded_exec() -> Result<(), ZenError> {
        const NUM_THREADS: usize = 5;
        let mut threads = Vec::new();
        for _ in 0..NUM_THREADS {
            threads.push(std::thread::spawn(|| {
                zencode_exec(SAMPLE_SCRIPT, "", "", "")
            }));
        }
        for thread in threads {
            thread.join().expect("thread should not panic")?;
        }
        Ok(())
    }
}
