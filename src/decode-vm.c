#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <luasandbox.h>


#define MODULE_PATH "."

int main(int argc, char **argv) {
	lsb_lua_sandbox *lua;
	lsb_err_value res;
	char *p;
	lua = lsb_create(NULL, argv[1], MODULE_PATH, NULL);
	res = lsb_init(lua, "decode-vm.pid");
	// do stuff
	lsb_pcall_teardown(lua);
	lsb_stop_sandbox_clean(lua);
	// lua_gc(lua, LUA_GCCOLLECT, 0);
	p = lsb_destroy(lua);
	if(p) {
		// error
		free(p);
		}	
}
