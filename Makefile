all:
	./build/apply-patches
	cd lib/lua_sandbox && cmake .
	make -C lib/lua_sandbox
