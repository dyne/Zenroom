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

lsb_lua_sandbox *zen_init(const char *conf);
int zen_exec_line(lsb_lua_sandbox *lsb, const char *line);
int zen_exec_script(lsb_lua_sandbox *lsb, const char *script);
int zen_teardown(lsb_lua_sandbox *lsb);

typedef struct zen_output_buffer {
  char          *buf;
  size_t        maxsize;
  size_t        size;
  size_t        pos;
} zen_output_buffer;

struct lsb_lua_sandbox {
	lua_State         *lua;
	void              *parent;
	char              *lua_file;
	char              *state_file;
	lsb_logger        logger;
	lsb_state         state;
	zen_output_buffer output;
	size_t            usage[LSB_UT_MAX][LSB_US_MAX];
	char              error_message[LSB_ERROR_SIZE];
};



int get_debug();

void lsb_setglobal_string(lsb_lua_sandbox *lsb, char *key, char *val);
void lsb_load_extensions(lsb_lua_sandbox *lsb);
int output_print(lua_State *lua);

// See Identify your Errors better with char[]
// http://accu.org/index.php/journals/2184
typedef const char lsb_err_id[];
typedef const char *lsb_err_value;
#define lsb_err_string(s) s ? s : "<no error>"

typedef void (*lsb_logger_cb)(void *context,
                              const char *component,
                              int level,
                              const char *fmt,
                              ...);
