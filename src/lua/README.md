The files in this directory are "pure" LUA extensions statically
compiled as binaries and loaded inside zenroom as strings. This is
because the Zenroom cannot access the filesystem.

The extensions are compiled into C headers by the Makefile target
`embed-lua` which needs to be run manually in case of addition of new
extensions. Then zmake embed-luaz will create `lualib_*.c` files inside
the src/ directory. To complete inclusion they should be added at the
beginning of the lua_functions.c files (inside the #include directive
as if they'd be headers) and at the end of the file by the
lsb_load_string() taking them as string arguments.

