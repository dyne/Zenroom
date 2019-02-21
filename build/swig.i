// interface for language bindings
// see swig.org
%module zenroom
%{
	extern int zencode_exec(char *script, char *conf, char *keys,
	                 char *data, int verbosity);
	extern int zencode_exec_tobuf(char *script, char *conf, char *keys,
	                       char *data, int verbosity,
	                       char *stdout_buf, size_t stdout_len,
	                       char *stderr_buf, size_t stderr_len);
	extern int zenroom_exec(char *script, char *conf, char *keys,
	                 char *data, int verbosity);
	extern int zenroom_exec_tobuf(char *script, char *conf, char *keys,
	                       char *data, int verbosity,
	                       char *stdout_buf, size_t stdout_len,
	                       char *stderr_buf, size_t stderr_len);
	extern int zenroom_parse_ast(char *script, int verbosity,
	                      char *stdout_buf, size_t stdout_len,
	                      char *stderr_buf, size_t stderr_len);
	extern void set_debug(int lev);
	%}

extern int zencode_exec(char *script, char *conf, char *keys,
                        char *data, int verbosity);
extern int zencode_exec_tobuf(char *script, char *conf, char *keys,
                              char *data, int verbosity,
                              char *stdout_buf, size_t stdout_len,
                              char *stderr_buf, size_t stderr_len);
extern int zenroom_exec(char *script, char *conf, char *keys,
                        char *data, int verbosity);
extern int zenroom_exec_tobuf(char *script, char *conf, char *keys,
                              char *data, int verbosity,
                              char *stdout_buf, size_t stdout_len,
                              char *stderr_buf, size_t stderr_len);
extern int zenroom_parse_ast(char *script, int verbosity,
                             char *stdout_buf, size_t stdout_len,
                             char *stderr_buf, size_t stderr_len);
extern void set_debug(int lev);

