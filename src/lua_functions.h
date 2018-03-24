/*  Zenroom (DECODE project)
 *
 *  (c) Copyright 2017-2018 Dyne.org foundation
 *  designed, written and maintained by Denis Roio <jaromil@dyne.org>
 *
 * This source code is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Public License as published
 * by the Free Software Foundation; either version 3 of the License,
 * or (at your option) any later version.
 *
 * This source code is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * Please refer to the GNU Public License for more details.
 *
 * You should have received a copy of the GNU Public License along with
 * this source code; if not, write to:
 * Free Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#include <zenroom.h>
#include <lauxlib.h>

typedef struct lsb_lua_sandbox {
	lua_State         *lua;
	void              *parent;
	char              *lua_file;
	char              *state_file;
	size_t mem_usage;
	size_t mem_max;
	size_t op_usage;
	size_t op_max;
	char              error_message[MAX_STRING];
} lsb_lua_sandbox;

typedef struct zen_extension_t {
	const char         *name;
	const unsigned int *size;
	const char         *code;
} zen_extension_t;


// #define LSB_SHUTTING_DOWN     "shutting down"
// #define LSB_CONFIG_TABLE      "lsb_config"
#define LSB_THIS_PTR          "lsb_this_ptr"
// #define LSB_MEMORY_LIMIT      "memory_limit"
// #define LSB_INSTRUCTION_LIMIT "instruction_limit"
// #define LSB_INPUT_LIMIT       "input_limit"
// #define LSB_OUTPUT_LIMIT      "output_limit"
// #define LSB_LOG_LEVEL         "log_level"
// #define LSB_LUA_PATH          "path"
// #define LSB_LUA_CPATH         "cpath"
// #define LSB_NIL_ERROR         "<nil error message>"

lsb_lua_sandbox *zen_init();
int zen_exec_line(lsb_lua_sandbox *lsb, const char *line);
int zen_exec_script(lsb_lua_sandbox *lsb, const char *script);
int zen_teardown(lsb_lua_sandbox *lsb);

int get_debug();

int zen_load_string(lua_State *L, const char *code,
                    size_t size,  const char *name);
int zen_add_package(lua_State *L, char *name, lua_CFunction func);
void zen_add_function(lsb_lua_sandbox *lsb,
                      lua_CFunction func,
                      const char *func_name);
void zen_add_class(lua_State *L, char *name,
                   const luaL_Reg *class, const luaL_Reg *methods);

void lsb_setglobal_string(lsb_lua_sandbox *lsb, char *key, char *val);
void lsb_load_extensions(lsb_lua_sandbox *lsb);
void lsb_add_function(lsb_lua_sandbox *lsb, lua_CFunction func,
                      const char *func_name);
int output_print(lua_State *lua);

// See Identify your Errors better with char[]
// http://accu.org/index.php/journals/2184
typedef const char lsb_err_id[];
typedef const char *lsb_err_value;
#define lsb_err_string(s) s ? s : "<no error>"

