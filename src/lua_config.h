#ifndef __LUA_CONFIG_H__
#define __LUA_CONFIG_H__

lua_State* load_zen_config(const char *cfg, lsb_logger *logger);
int read_config(lua_State *lua);
size_t get_size(lua_State *lua, int idx, const char *item);
void copy_table(lua_State *sb, lua_State *cfg, lsb_logger *logger);

#endif
