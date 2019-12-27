// interface for language bindings
// see swig.org

#ifdef SWIGPYTHON
%include <pybuffer.i>

%pybuffer_mutable_binary(char *stdout_buf, size_t stdout_len);
%pybuffer_mutable_binary(char *stderr_buf, size_t stderr_len);

%begin %{
#define SWIG_PYTHON_STRICT_BYTE_CHAR
%}
%pythonbegin %{
import os
import platform
import sys 

python_version = '_'.join(map(str, sys.version_info[:3]))
system = platform.system()
zenroom_path = os.path.join(os.path.dirname(__file__), "libs", system, python_version)
sys.path.append(zenroom_path)
%}
#endif  /* SWIGPYTHON */

%module zenroom
%{
	extern int zencode_exec_tobuf(char *script, char *conf, char *keys, char *data,
	                       char *stdout_buf, size_t stdout_len,
	                       char *stderr_buf, size_t stderr_len);
	extern int zenroom_exec_tobuf(char *script, char *conf, char *keys, char *data,
	                       char *stdout_buf, size_t stdout_len,
	                       char *stderr_buf, size_t stderr_len);
	%}

extern int zencode_exec_tobuf(char *script, char *conf, char *keys, char *data,
                              char *stdout_buf, size_t stdout_len,
                              char *stderr_buf, size_t stderr_len);
extern int zenroom_exec_tobuf(char *script, char *conf, char *keys, char *data,
                              char *stdout_buf, size_t stdout_len,
                              char *stderr_buf, size_t stderr_len);
