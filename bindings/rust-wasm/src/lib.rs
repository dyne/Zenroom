use std::ffi::{CStr, CString};
use std::fmt;
use std::sync::{Mutex, MutexGuard, Once};

mod c {
    #![allow(non_upper_case_globals)]
    #![allow(non_camel_case_types)]
    #![allow(non_snake_case)]
    #![allow(dead_code)]
    #![allow(deref_nullptr)]
    include!(concat!(env!("OUT_DIR"), "/bindings.rs"));
}

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

impl std::error::Error for ZenError {}

type ZenGIL = MutexGuard<'static, ()>;

fn aquire_zen_gil() -> ZenGIL {
    static mut MUTEX: *const Mutex<()> = std::ptr::null();
    static ONCE: Once = Once::new();
    let mutex: &Mutex<()> = unsafe {
        ONCE.call_once(|| {
            MUTEX = std::mem::transmute(Box::new(Mutex::new(())));
        });
        MUTEX.as_ref().unwrap()
    };
    mutex.lock().unwrap()
}

const BUF_SIZE: usize = 2 * 1024 * 1024;

// TODO: improve usize type using c_size_t
type Fun = unsafe extern "C" fn(
    *const ::std::os::raw::c_char,
    *const ::std::os::raw::c_char,
    *const ::std::os::raw::c_char,
    *const ::std::os::raw::c_char,
    *mut ::std::os::raw::c_char,
    usize,
    *mut ::std::os::raw::c_char,
    usize,
) -> ::std::os::raw::c_int;

pub fn zencode_exec(
    script: impl AsRef<str>,
    conf: impl AsRef<str>,
    keys: impl AsRef<str>,
    data: impl AsRef<str>,
) -> Result<ZenResult, ZenError> {
    exec_f(c::zencode_exec_tobuf, script, conf, keys, data)
}

pub fn zenroom_exec(
    script: impl AsRef<str>,
    conf: impl AsRef<str>,
    keys: impl AsRef<str>,
    data: impl AsRef<str>,
) -> Result<ZenResult, ZenError> {
    exec_f(c::zenroom_exec_tobuf, script, conf, keys, data)
}

fn exec_f(
    fun: Fun,
    script: impl AsRef<str>,
    conf: impl AsRef<str>,
    keys: impl AsRef<str>,
    data: impl AsRef<str>,
) -> Result<ZenResult, ZenError> {
    let mut stdout = Vec::<i8>::with_capacity(BUF_SIZE);
    let stdout_ptr = stdout.as_mut_ptr();
    let mut stderr = Vec::<i8>::with_capacity(BUF_SIZE);
    let stderr_ptr = stderr.as_mut_ptr();

    let lock = aquire_zen_gil();
    let exit_code = unsafe {
        fun(
            CString::new(script.as_ref())?.into_raw(),
            CString::new(conf.as_ref())?.into_raw(),
            CString::new(keys.as_ref())?.into_raw(),
            CString::new(data.as_ref())?.into_raw(),
            stdout_ptr,
            BUF_SIZE as usize,
            stderr_ptr,
            BUF_SIZE as usize,
        )
    };
    drop(lock);

    let res = ZenResult {
        output: unsafe { CStr::from_ptr(stdout_ptr) }
            .to_string_lossy()
            .into_owned(),
        logs: unsafe { CStr::from_ptr(stderr_ptr) }
            .to_string_lossy()
            .into_owned(),
    };

    if exit_code == 0 {
        Ok(res)
    } else {
        Err(ZenError::Execution(res))
    }
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

    #[test]
    fn simple_script() -> Result<(), ZenError> {
        let result = zencode_exec(SAMPLE_SCRIPT, "", "", "")?;

        let json: Value = serde_json::from_str(&result.output).unwrap();
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
