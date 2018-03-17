#include <zenroom.h>
#include <jutils.h>


#include <luasandbox.h>
#include <luasandbox/lua.h>
#include <luasandbox/lualib.h>
#include <luasandbox/lauxlib.h>


int read_config(lua_State *lua)
{
	luaL_checkstring(lua, 1);
	luaL_argcheck(lua, lua_gettop(lua) == 1, 0, "too many arguments");
	lua_getfield(lua, LUA_REGISTRYINDEX, LSB_CONFIG_TABLE);
	if (lua_type(lua, -1) == LUA_TTABLE) {
		lua_getfield(lua, -1, lua_tostring(lua, 1));
	} else {
		lua_pushnil(lua);
	}
	return 1;
}



size_t get_size(lua_State *lua, int idx, const char *item)
{
	lua_getfield(lua, idx, item);
	size_t size = (size_t)lua_tonumber(lua, -1);
	lua_pop(lua, 1);
	return size;
}


static int check_string(lua_State *L, int idx, const char *name,
                        const char *dflt)
{
	lua_getfield(L, idx, name);
	int t = lua_type(L, -1);
	switch (t) {
	case LUA_TSTRING:
		break;
	case LUA_TNIL:
		if (dflt) {
			lua_pushstring(L, dflt); // add the default to the config
			lua_setglobal(L, name);
		}
		break;
	default:
		lua_pushfstring(L, "%s must be set to a string", name);
		return 1;
	}
	return 0;
}


static int check_unsigned(lua_State *L, int idx, const char *name, unsigned val)
{
	lua_getfield(L, idx, name);
	double d;
	switch (lua_type(L, -1)) {
	case LUA_TNUMBER:
		d = lua_tonumber(L, -1);
		if (d < 0 || d > UINT_MAX) {
			lua_pushfstring(L, "%s must be an unsigned int", name);
			return 1;
		}
		break;
	case LUA_TNIL: // add the default to the config
		lua_pushnumber(L, (lua_Number)val);
		lua_setglobal(L, name);
		break; // use the default
	default:
		lua_pushfstring(L, "%s must be set to a number", name);
		return 1;
	}
	lua_pop(L, 1);
	return 0;
}


static int check_size(lua_State *L, int idx, const char *name, size_t val)
{
	lua_getfield(L, idx, name);
	double d;
	switch (lua_type(L, -1)) {
	case LUA_TNUMBER:
		d = lua_tonumber(L, -1);
		if (d < 0 || d > SIZE_MAX) {
			lua_pushfstring(L, "%s must be a size_t", name);
			return 1;
		}
		break;
	case LUA_TNIL: // add the default to the config
		lua_pushnumber(L, (lua_Number)val);
		lua_setglobal(L, name);
		break; // use the default
	default:
		lua_pushfstring(L, "%s must be set to a number", name);
		return 1;
	}
	lua_pop(L, 1);
	return 0;
}


lua_State* load_zen_config(const char *cfg, lsb_logger *logger)
{
	lua_State *L = luaL_newstate();
	if (!L) {
		if (logger->cb) logger->cb(logger->context, __func__, 3,
		                           "lua_State creation failed");
		return NULL;
	}

	if (!cfg) cfg = ""; // use the default settings

	int ret = luaL_dostring(L, cfg);
	if (ret) goto cleanup;

	ret = check_size(L, LUA_GLOBALSINDEX, LSB_INPUT_LIMIT, 64 * 1024);
	if (ret) goto cleanup;

	ret = check_size(L, LUA_GLOBALSINDEX, LSB_OUTPUT_LIMIT, 64 * 1024);
	if (ret) goto cleanup;

	ret = check_size(L, LUA_GLOBALSINDEX, LSB_MEMORY_LIMIT, 8 * 1024 * 1024);
	if (ret) goto cleanup;

	ret = check_size(L, LUA_GLOBALSINDEX, LSB_INSTRUCTION_LIMIT, 1000000);
	if (ret) goto cleanup;

	ret = check_unsigned(L, LUA_GLOBALSINDEX, LSB_LOG_LEVEL, 3);
	if (ret) goto cleanup;

	ret = check_string(L, LUA_GLOBALSINDEX, LSB_LUA_PATH, NULL);
	if (ret) goto cleanup;

	ret = check_string(L, LUA_GLOBALSINDEX, LSB_LUA_CPATH, NULL);
	if (ret) goto cleanup;

cleanup:
	if (ret) {
		if (logger->cb) {
			logger->cb(logger->context, __func__, 3, "config error: %s",
			           lua_tostring(L, -1));
		}
		lua_close(L);
		return NULL;
	}
	return L;
}


void copy_table(lua_State *sb, lua_State *cfg, lsb_logger *logger)
{
	lua_newtable(sb);
	lua_pushnil(cfg);
	while (lua_next(cfg, -2) != 0) {
		int kt = lua_type(cfg, -2);
		int vt = lua_type(cfg, -1);
		switch (kt) {
		case LUA_TNUMBER:
		case LUA_TSTRING:
			switch (vt) {
			case LUA_TSTRING:
			{
				size_t len;
				const char *tmp = lua_tolstring(cfg, -1, &len);
				if (tmp) {
					lua_pushlstring(sb, tmp, len);
					if (kt == LUA_TSTRING) {
						lua_setfield(sb, -2, lua_tostring(cfg, -2));
					} else {
						lua_rawseti(sb, -2, (int)lua_tointeger(cfg, -2));
					}
				}
			}
			break;
			case LUA_TNUMBER:
				lua_pushnumber(sb, lua_tonumber(cfg, -1));
				if (kt == LUA_TSTRING) {
					lua_setfield(sb, -2, lua_tostring(cfg, -2));
				} else {
					lua_rawseti(sb, -2, (int)lua_tointeger(cfg, -2));
				}
				break;
			case LUA_TBOOLEAN:
				lua_pushboolean(sb, lua_toboolean(cfg, -1));
				if (kt == LUA_TSTRING) {
					lua_setfield(sb, -2, lua_tostring(cfg, -2));
				} else {
					lua_rawseti(sb, -2, (int)lua_tointeger(cfg, -2));
				}
				break;
			case LUA_TTABLE:
				copy_table(sb, cfg, logger);
				break;
			default:
				if (logger->cb) {
					logger->cb(logger->context, __func__, 4,
					           "skipping config value type: %s", lua_typename(cfg, vt));
				}
				break;
			}
			break;
		default:
			if (logger->cb) {
				logger->cb(logger->context, __func__, 4, "skipping config key type: %s",
				           lua_typename(cfg, kt));
			}
			break;
		}
		lua_pop(cfg, 1);
	}

	switch (lua_type(cfg, -2)) {
	case LUA_TSTRING:
		lua_setfield(sb, -2, lua_tostring(cfg, -2));
		break;
	case LUA_TNUMBER:
		lua_rawseti(sb, -2, (int)lua_tointeger(cfg, -2));
		break;
	}
}
