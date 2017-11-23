all:
	gcc jutils.c decode-exec.c -O3 -Wall -o decode-exec \
	 -I. -I../lib/lua_sandbox/include \
	 ../lib/lua_sandbox/src/libluasandbox.a \
	 ../lib/lua_sandbox/src/util/libluasandboxutil.a -lm -ldl \
	 -o decode-exec


musl:
	/usr/local/musl/bin/musl-gcc jutils.c decode-exec.c -Os -o decode-exec -DDEBUG=1 -Wall \
		-I. -I/usr/local/musl/include -I../lib/lua_sandbox/include \
		/usr/local/musl/lib/libc.a \
		../lib/lua_sandbox/src/libluasandbox.a \
		../lib/lua_sandbox/src/util/libluasandboxutil.a -lm \
		-static -o decode-exec

debug:
	gcc jutils.c decode-exec.c -ggdb -o decode-exec -DDEBUG=1 -Wall \
	 -I. -I../lib/lua_sandbox/include \
	 ../lib/lua_sandbox/src/libluasandbox.a \
	 ../lib/lua_sandbox/src/util/libluasandboxutil.a -lm -ldl \
	 -ggdb -o decode-exec
