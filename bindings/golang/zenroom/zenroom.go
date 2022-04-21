// Package zenroom is a CGO wrapper for the Zenroom virtual machine, which aims
// to make Zenroom easily usable from Go programs. Currently the C binary we
// wrap is only available for Linux.
package zenroom

// #cgo CFLAGS: -I${SRCDIR}/src
// #cgo LDFLAGS: -L${SRCDIR}/lib -Wl,-rpath=${SRCDIR}/lib -lzenroom
// #include <stdio.h>
// #include <stdlib.h>
// #include <string.h>
// #include "../../../src/zenroom.h"
// typedef int(*fun)(char*, char*, char*, char*, char*, size_t, char*, size_t);
//
// int wrapper(fun exec, char* script, char* conf, char* data, char* keys, char* stdout, size_t stdout_size, char* stderr, size_t stderr_size) {
//     return exec(script, conf, data, keys, stdout, stdout_size, stderr, stderr_size);
// }
import "C"

import (
	"unsafe"
)

// maxString is zenroom defined buffer MAX_STRING size
const BUFSIZE = 2 * 1024 * 1024

type ZenResult struct {
    output string;
    logs string;
}

// ZenroomExec is our primary public API method, and it is here that we call Zenroom's
// zenroom_exec_tobuf function. This method attempts to pass a required script,
// and some optional extra parameters to the Zenroom virtual machine, where
// cryptographic operations are performed with the result being returned to the
// caller. The method signature has been tweaked slightly from the original
// function defined by Zenroom; rather than making all parameters required,
// instead we have just included as a required parameter the input SCRIPT, while
// all other properties must be supplied via one of the previously defined
// Option helpers.
//
// Returns the output of the execution of the Zenroom virtual machine, or an
// error.
func ZenroomExec(script string, conf string, keys string, data string) (ZenResult, bool) {
	exec := C.fun(C.zenroom_exec_tobuf)
	return wrapper(exec, script, conf, keys, data)
}

func ZencodeExec(script string, conf string, keys string, data string) (ZenResult, bool) {
	exec := C.fun(C.zencode_exec_tobuf)
	return wrapper(exec, script, conf, keys, data)
}

func wrapper(fun C.fun, script string, conf string, keys string, data string) (ZenResult, bool) {
	var (
		cScript, cConf, cKeys, cData *C.char
	)

	cScript = C.CString(script)
	defer C.free(unsafe.Pointer(cScript))

	if conf != "" {
		cConf = C.CString(conf)
		defer C.free(unsafe.Pointer(cConf))
	} else {
		cConf = nil
	}


	if data != "" {
		cData = C.CString(data)
		defer C.free(unsafe.Pointer(cData))
	} else {
		cData = nil
	}

	if keys != "" {
		cKeys = C.CString(keys)
		defer C.free(unsafe.Pointer(cKeys))
	} else {
		cKeys = nil
	}

	// create empty strings to capture zenroom's output
	stdout := emptyString(BUFSIZE)
	stderr := emptyString(BUFSIZE)
	defer C.free(unsafe.Pointer(stdout))
	defer C.free(unsafe.Pointer(stderr))

	res := C.wrapper(
		fun,
		cScript,
		cConf, cKeys, cData,
		stdout, BUFSIZE,
		stderr, BUFSIZE,
	)

	zen_res := ZenResult{
		output: C.GoString(stdout),
		logs: C.GoString(stderr),
	}

	return zen_res, res == 0
}

// ZencodeExec is our primary public API method, and it is here that we call Zenroom's
// zencode_exec_tobuf function. This method attempts to pass a required script,
// and some optional extra parameters to the Zenroom virtual machine, where
// cryptographic operations are performed with the result being returned to the
// caller. The method signature has been tweaked slightly from the original
// function defined by Zenroom; rather than making all parameters required,
// instead we have just included as a required parameter the input SCRIPT, while
// all other properties must be supplied via one of the previously defined
// Option helpers.
//
// Returns the output of the execution of the Zenroom virtual machine, or an
// error.

// reimplementation of https://golang.org/src/strings/strings.go?s=13172:13211#L522
func emptyString(size int) *C.char {
	p := C.malloc(C.size_t(size))
	return (*C.char)(p)
}
