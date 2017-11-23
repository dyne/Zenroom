all:
	gcc decode-vm.c -I../lib/lua_sandbox/include \
					  ../lib/lua_sandbox/src/libluasandbox.a \
					  ../lib/lua_sandbox/src/util/libluasandboxutil.a -lm -ldl \
	 -ggdb -o decode-vm
