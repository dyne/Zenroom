// interface for language bindings
// see swig.org
%include <pybuffer.i>
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
	extern int zenroom_exec_rng_tobuf(char *script, char *conf, char *keys,
	                                  char *data, int verbosity,
	                                  char *stdout_buf, size_t stdout_len,
	                                  char *stderr_buf, size_t stderr_len,
	                                  char *random_seed, size_t random_seed_len);
	extern int zencode_exec_rng_tobuf(char *script, char *conf, char *keys,
	                                  char *data, int verbosity,
	                                  char *stdout_buf, size_t stdout_len,
	                                  char *stderr_buf, size_t stderr_len,
	                                  char *random_seed, size_t random_seed_len);
	extern void set_debug(int lev);
	%}

extern int zencode_exec(char *script, char *conf, char *keys,
                        char *data, int verbosity);
%pybuffer_mutable_binary(char *stdout_buf, size_t stdout_len);
%pybuffer_mutable_binary(char *stderr_buf, size_t stderr_len);
extern int zencode_exec_tobuf(char *script, char *conf, char *keys,
                              char *data, int verbosity,
                              char *stdout_buf, size_t stdout_len,
                              char *stderr_buf, size_t stderr_len);
extern int zenroom_exec(char *script, char *conf, char *keys,
                        char *data, int verbosity);
%pybuffer_mutable_binary(char *stdout_buf, size_t stdout_len);
%pybuffer_mutable_binary(char *stderr_buf, size_t stderr_len);
extern int zenroom_exec_tobuf(char *script, char *conf, char *keys,
                              char *data, int verbosity,
                              char *stdout_buf, size_t stdout_len,
                              char *stderr_buf, size_t stderr_len);
%pybuffer_mutable_binary(char *stdout_buf, size_t stdout_len);
%pybuffer_mutable_binary(char *stderr_buf, size_t stderr_len);
%pybuffer_mutable_binary(char *random_seed, size_t random_seed_len);
extern int zenroom_exec_rng_tobuf(char *script, char *conf, char *keys,
                                  char *data, int verbosity,
                                  char *stdout_buf, size_t stdout_len,
                                  char *stderr_buf, size_t stderr_len,
                                  char *random_seed, size_t random_seed_len);
%pybuffer_mutable_binary(char *stdout_buf, size_t stdout_len);
%pybuffer_mutable_binary(char *stderr_buf, size_t stderr_len);
%pybuffer_mutable_binary(char *random_seed, size_t random_seed_len);
extern int zencode_exec_rng_tobuf(char *script, char *conf, char *keys,
                                  char *data, int verbosity,
                                  char *stdout_buf, size_t stdout_len,
                                  char *stderr_buf, size_t stderr_len,
                                  char *random_seed, size_t random_seed_len);

extern void set_debug(int lev);

