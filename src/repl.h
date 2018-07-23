#ifndef __REPL_H__
#define __REPL_H__

int repl_read(lua_State *lua);
int repl_flush(lua_State *lua);
int repl_write(lua_State *lua);
int repl_loop(zenroom_t *Z);


#endif
