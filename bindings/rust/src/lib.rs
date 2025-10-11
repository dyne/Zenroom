use std::ffi::{CString, NulError};
use std::fmt;
use libc::{c_char, size_t};

// Platform-specific FFI bindings (pre-generated or from build.rs)
#[allow(non_upper_case_globals)]
#[allow(non_camel_case_types)]
#[allow(non_snake_case)]
#[allow(dead_code)]
mod bindings;

// Re-export bindings as ffi for internal use
use bindings as ffi;

// Buffer size matching Android implementation (1MB for large crypto outputs)
const OUTPUT_BUFFER_SIZE: usize = 1024 * 1024;

#[derive(Clone, Debug)]
pub struct ZenResult {
    pub output: String,
    pub logs: String,
}

#[derive(Clone, Debug)]
pub enum ZenError {
    Execution(ZenResult),
    InvalidInput(NulError),
}

impl From<NulError> for ZenError {
    fn from(err: NulError) -> Self {
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

/// Convert C buffer to Rust String, handling null-termination
fn buffer_to_string(buf: &[u8]) -> String {
    // Find null terminator (C strings are null-terminated)
    let null_pos = buf.iter()
        .position(|&c| c == 0)
        .unwrap_or(buf.len());

    String::from_utf8_lossy(&buf[..null_pos]).to_string()
}

pub fn zencode_exec_extra(
    script: &str,
    conf: &str,
    keys: &str,
    data: &str,
    extra: &str,
    context: &str,
) -> Result<ZenResult, ZenError> {
    let c_script = CString::new(script)?;
    let c_conf = if conf.is_empty() {
        CString::new("")?
    } else {
        CString::new(conf)?
    };
    let c_keys = if keys.is_empty() {
        CString::new("")?
    } else {
        CString::new(keys)?
    };
    let c_data = if data.is_empty() {
        CString::new("")?
    } else {
        CString::new(data)?
    };
    let c_extra = if extra.is_empty() {
        CString::new("")?
    } else {
        CString::new(extra)?
    };
    let c_context = if context.is_empty() {
        CString::new("")?
    } else {
        CString::new(context)?
    };

    let mut stdout_buf = vec![0u8; OUTPUT_BUFFER_SIZE];
    let mut stderr_buf = vec![0u8; OUTPUT_BUFFER_SIZE];

    let ret_code = unsafe {
        ffi::zencode_exec_tobuf(
            c_script.as_ptr(),
            c_conf.as_ptr(),
            c_keys.as_ptr(),
            c_data.as_ptr(),
            c_extra.as_ptr(),
            c_context.as_ptr(),
            stdout_buf.as_mut_ptr() as *mut c_char,
            stdout_buf.len() as size_t,
            stderr_buf.as_mut_ptr() as *mut c_char,
            stderr_buf.len() as size_t,
        )
    };

    let result = ZenResult {
        output: buffer_to_string(&stdout_buf),
        logs: buffer_to_string(&stderr_buf),
    };

    if ret_code == 0 {
        Ok(result)
    } else {
        Err(ZenError::Execution(result))
    }
}

pub fn zencode_exec(
    script: &str,
    conf: &str,
    keys: &str,
    data: &str,
) -> Result<ZenResult, ZenError> {
    zencode_exec_extra(script, conf, keys, data, "", "")
}

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
    fn invalid_script_error() {
        let invalid_script = r#"
        Scenario 'ecdh'
        Given I have a 'nonexistent' named 'foo'
        "#;

        let result = zencode_exec(invalid_script, "", "", "");
        assert!(result.is_err());

        if let Err(ZenError::Execution(err)) = result {
            assert!(!err.logs.is_empty());
        } else {
            panic!("Expected Execution error");
        }
    }

    #[test]
    fn null_byte_input_error() {
        let script_with_null = "test\0script";
        let result = zencode_exec(script_with_null, "", "", "");

        assert!(result.is_err());
        assert!(matches!(result, Err(ZenError::InvalidInput(_))));
    }
}
