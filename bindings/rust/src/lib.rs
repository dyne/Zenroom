#![allow(non_upper_case_globals)]
#![allow(non_camel_case_types)]
#![allow(non_snake_case)]

use std::ffi::CString;

mod c {
    include!(concat!(env!("OUT_DIR"), "/bindings.rs"));
}

pub struct ZenResult {
    pub output: String,
    pub logs: String,
}

const BUF_SIZE: usize = 2 * 1024 * 1024;

type Fun = unsafe extern "C" fn(
    *mut ::std::os::raw::c_char,
    *mut ::std::os::raw::c_char,
    *mut ::std::os::raw::c_char,
    *mut ::std::os::raw::c_char,
    *mut ::std::os::raw::c_char,
    ::std::os::raw::c_ulong,
    *mut ::std::os::raw::c_char,
    ::std::os::raw::c_ulong,
) -> ::std::os::raw::c_int;

pub fn zencode_exec(
    script: CString,
    conf: CString,
    keys: CString,
    data: CString,
) -> (ZenResult, bool) {
    exec_f(c::zencode_exec_tobuf, script, conf, keys, data)
}

pub fn zenroom_exec(
    script: CString,
    conf: CString,
    keys: CString,
    data: CString,
) -> (ZenResult, bool) {
    exec_f(c::zenroom_exec_tobuf, script, conf, keys, data)
}

fn exec_f(
    fun: Fun,
    script: CString,
    conf: CString,
    keys: CString,
    data: CString,
) -> (ZenResult, bool) {
    let mut stdout = Vec::<i8>::with_capacity(BUF_SIZE);
    let stdout_ptr = stdout.as_mut_ptr();
    std::mem::forget(stdout);
    let mut stderr = Vec::<i8>::with_capacity(BUF_SIZE);
    let stderr_ptr = stderr.as_mut_ptr();
    std::mem::forget(stderr);

    let res = unsafe {
        fun(
            script.into_raw(),
            conf.into_raw(),
            keys.into_raw(),
            data.into_raw(),
            stdout_ptr,
            BUF_SIZE as u64,
            stderr_ptr,
            BUF_SIZE as u64,
        )
    };

    (
        ZenResult {
            output: unsafe { CString::from_raw(stdout_ptr) }
                .into_string()
                // Do not fail on errors in output
                .unwrap_or_else(|_| String::from("")),
            logs: unsafe { CString::from_raw(stderr_ptr) }
                .into_string()
                .unwrap(),
        },
        res == 0,
    )
}

#[cfg(test)]
mod tests {
    use crate::*;
    use serde_json::Value;

    #[test]
    fn simple_script() {
        let script = CString::new(
            r#"
Scenario 'ecdh': Create the keypair
Given that I am known as 'Alice'
When I create the keypair
Then print my data
"#,
        )
        .unwrap();
        let (result, success) = zencode_exec(
            script,
            CString::new("").unwrap(),
            CString::new("").unwrap(),
            CString::new("").unwrap(),
        );

        assert!(success);

        let json: Value = serde_json::from_str(&result.output).unwrap();
        let keypair = json
            .as_object()
            .unwrap()
            .get("Alice")
            .unwrap()
            .get("keypair")
            .unwrap();
        assert!(keypair.get("private_key").is_some());
        assert!(keypair.get("public_key").is_some());
    }
}
