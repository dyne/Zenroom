// Package zenroom is a CGO wrapper for the Zenroom virtual machine, which aims
// to make Zenroom easily usable from Go programs. Currently the C binary we
// wrap is only available for Linux.
package zenroom

// #cgo CFLAGS: -IC:${SRCDIR}
// #cgo LDFLAGS: -L${SRCDIR}/lib -Wl,-rpath=${SRCDIR}/lib -lzenroomgo
// #include <stdio.h>
// #include <stdlib.h>
// #include <string.h>
// #include "zenroom.h"
import (
	"C"
)

import (
	"fmt"
	"unsafe"

	// dummy import to include binary in dependencies
	_ "github.com/dyne/Zenroom/bindings/golang/zenroom/lib"
)

// maxString is zenroom defined buffer MAX_STRING size
const maxString = 1048576

// config is an unexported config struct used to handle the functional variadic
// configuration options defined below.
type config struct {
	Keys      []byte
	Data      []byte
	Conf      string
	Verbosity int
}

// Option is a type alias we use to supply optional configuration to the primary
// Exec method this library exposes. Option is a functional configuration type
// alias for a function that takes as a parameter an unexported configuration
// object. Callers can supply keys, data, conf and verbosity via an Option using
// one of the WithXXX helper functions.
type Option func(*config)

// WithKeys is a configuration helper that allows the caller to pass in a value
// for the KEYS parameter that Zenroom supports. The value of KEYS is typically
// a string, often JSON formatted, that contains one or more keys that the
// primary script requires in order to operate. These are passed separately from
// the main script as they will typically have different security requirements
// than the main script contents. Keys must be passed in to the helper in a byte
// slice.
func WithKeys(keys []byte) Option {
	return func(c *config) {
		c.Keys = keys
	}
}

// WithData is a configuration helper that allows the caller to pass in a value
// for the DATA parameter that Zenroom supports. The value of KEYS is a string,
// often but not required to be JSON formatted, containing data over which the
// script should operate. As with the KEYS property, DATA is passed separately
// from either the SCRIPT or the KEYS as these different values will often have
// different security requirements or may come from different sources. DATA must
// be passed as a byte slice.
func WithData(data []byte) Option {
	return func(c *config) {
		c.Data = data
	}
}

// WithConf is a configuration helper that allows the caller to pass in a value
// for the CONF parameter that Zenroom supports. The default for this value if
// not supplied is an empty string.
func WithConf(conf string) Option {
	return func(c *config) {
		c.Conf = conf
	}
}

// WithVerbosity is a configuration helper that allows the caller to specify how
// verbose Zenroom should be with its output. The value of this configuration
// must be an integer from 1 to 3, where 1 is the least verbose, and 3 is the
// most. The default if this value is not supplied is 1.
func WithVerbosity(verbosity int) Option {
	return func(c *config) {
		c.Verbosity = verbosity
	}
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
func ZenroomExec(script []byte, options ...Option) ([]byte, error) {
	var (
		cScript                   *C.char
		optKeys, optData, optConf *C.char
	)

	// capture the required script parameter
	if script == nil {
		return nil, fmt.Errorf("missing required script to process")
	}
	cScript = (*C.char)(unsafe.Pointer(&script[0]))

	// set up our default config
	conf := &config{
		Conf:      "",
		Verbosity: 1,
	}

	// and now we iterate through our options, to update our config object
	for _, option := range options {
		option(conf)
	}

	if conf.Keys != nil {
		optKeys = (*C.char)(unsafe.Pointer(&conf.Keys[0]))
	}

	if conf.Data != nil {
		optData = (*C.char)(unsafe.Pointer(&conf.Data[0]))
	}

	if conf.Conf != "" {
		optConf = C.CString(conf.Conf)
		defer C.free(unsafe.Pointer(optConf))
	}

	// create empty strings to capture zenroom's output
	stdout := emptyString(maxString)
	stderr := emptyString(maxString)
	defer C.free(unsafe.Pointer(stdout))
	defer C.free(unsafe.Pointer(stderr))

	res := C.zenroom_exec_tobuf(
		cScript,
		optConf, optKeys, optData, C.int(conf.Verbosity),
		stdout, maxString,
		stderr, maxString,
	)

	if res != 0 {
		return nil, fmt.Errorf("error calling zenroom: %s ", C.GoString(stderr))
	}

	return C.GoBytes(unsafe.Pointer(stdout), C.int(C.strlen(stdout))), nil
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
func ZencodeExec(script []byte, options ...Option) ([]byte, error) {
	var (
		cScript                   *C.char
		optKeys, optData, optConf *C.char
	)

	// capture the required script parameter
	if script == nil {
		return nil, fmt.Errorf("missing required script to process")
	}
	cScript = (*C.char)(unsafe.Pointer(&script[0]))

	// set up our default config
	conf := &config{
		Conf:      "",
		Verbosity: 1,
	}

	// and now we iterate through our options, to update our config object
	for _, option := range options {
		option(conf)
	}

	if conf.Keys != nil {
		optKeys = (*C.char)(unsafe.Pointer(&conf.Keys[0]))
	}

	if conf.Data != nil {
		optData = (*C.char)(unsafe.Pointer(&conf.Data[0]))
	}

	if conf.Conf != "" {
		optConf = C.CString(conf.Conf)
		defer C.free(unsafe.Pointer(optConf))
	}

	// create empty strings to capture zenroom's output
	stdout := emptyString(maxString)
	stderr := emptyString(maxString)
	defer C.free(unsafe.Pointer(stdout))
	defer C.free(unsafe.Pointer(stderr))

	res := C.zencode_exec_tobuf(
		cScript,
		optConf, optKeys, optData, C.int(conf.Verbosity),
		stdout, maxString,
		stderr, maxString,
	)

	if res != 0 {
		return nil, fmt.Errorf("error calling zenroom: %s ", C.GoString(stderr))
	}

	return C.GoBytes(unsafe.Pointer(stdout), C.int(C.strlen(stdout))), nil
}

// reimplementation of https://golang.org/src/strings/strings.go?s=13172:13211#L522
func emptyString(size int) *C.char {
	p := C.malloc(C.size_t(size + 1))
	// largest array size that can be used on all architectures
	pp := (*[1 << 30]byte)(p)
	bp := copy(pp[:], " ")
	for bp < size {
		copy(pp[bp:], pp[:bp])
		bp *= 2
	}
	pp[size] = 0
	return (*C.char)(p)
}
