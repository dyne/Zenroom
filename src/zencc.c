/* This file is part of Zenroom
 *
 * Copyright (C) 2024 Dyne.org foundation
 * designed, written and maintained by Denis Roio <jaromil@dyne.org>
 * Thanks to Fabrice Bellard and Puria Nafisi Azizi
 *
 * This program is free software: you can redistribute it and/or
 * modify it under the terms of the GNU Affero General Public License
 * as published by the Free Software Foundation, either version 3 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public
 * License along with this program.  If not, see
 * <https://www.gnu.org/licenses/>.
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

#include <cflag.h>
#include <libtcc.h>
#include <zenroom.h>

// Zenroom's context free print and error messages
extern void _out(const char *fmt, ...);
extern void _err(const char *fmt, ...);
void handle_error(void *n, const char *m) { (void)n; _err("%s",m); }
// aux internal at bottom
long  file_size(const char *filename);
char* file_load(const char *filename);

int errors = 0;
bool verbose = false;
const char *libtcc_path = 0x0;
const char *include_path = 0x0;
const char *libs_path = 0x0;
const char *progname = "zencc";
const char *syntax = "[options] code.c";

int dl_zenroom(TCCState *TCC) {
	int c=0;
	// main API
	tcc_add_symbol(TCC, "zenroom_exec", zenroom_exec); c++;
	tcc_add_symbol(TCC, "zencode_exec", zencode_exec); c++;
	// in memory API
	tcc_add_symbol(TCC, "zenroom_exec_tobuf", zenroom_exec_tobuf); c++;
	tcc_add_symbol(TCC, "zencode_exec_tobuf", zencode_exec_tobuf); c++;
	// zencode validation API
	tcc_add_symbol(TCC, "zencode_valid_input", zencode_valid_input); c++;
	tcc_add_symbol(TCC, "zencode_valid_code", zencode_valid_code); c++;
	// hash API
	tcc_add_symbol(TCC, "zenroom_hash_init", zenroom_hash_init); c++;
	tcc_add_symbol(TCC, "zenroom_hash_update", zenroom_hash_update); c++;
	tcc_add_symbol(TCC, "zenroom_hash_final", zenroom_hash_final); c++;
	// internal API
	tcc_add_symbol(TCC, "zen_init", zen_init); c++;
	tcc_add_symbol(TCC, "zen_init_extra", zen_init_extra); c++;
	tcc_add_symbol(TCC, "zen_exec_lua", zen_exec_lua); c++;
	tcc_add_symbol(TCC, "zen_exec_zencode", zen_exec_zencode); c++;
	tcc_add_symbol(TCC, "zen_teardown", zen_teardown); c++;
	return(c);
}

int main(int argc, char **argv) {
    TCCState *TCC;

    static const struct cflag options[] = {
	    CFLAG(bool, "verbose", 'v', &verbose,
		  "Verbosely show progress"),
	    CFLAG(bool, "version", 'V', &verbose,
		  "Show build version"),
	    CFLAG(string, "libtcc", 'B', &libtcc_path,
		  "Path to dir containing the libtcc1.a library"),
	    CFLAG(string, "include", 'I', &include_path,
		  "Path to header files to include"),
	    CFLAG(string, "libs", 'L', &libs_path,
		  "Path to library files to link"),
	    CFLAG_HELP,
	    CFLAG_END
    };
    cflag_apply(options, syntax, &argc, &argv);
    if(!argv[0]) {
	    cflag_usage(options, progname, syntax, stderr);
	    exit(1);
    }
    const char *code_path = argv[0];

    _err("Zencc to execute code: %s",code_path);
    TCC = tcc_new();
    if (!TCC) {
        _err("Could not initialize tcc");
        exit(1); }

    /* set custom error/warning printer */
    tcc_set_error_func(TCC, stderr, handle_error);

    //// TCC DEFAULT PATHS
    tcc_set_lib_path(TCC,"lib/tinycc"); // inside zenroom source
    tcc_add_library_path(TCC,"/lib/x86_64-linux-musl"); // devuan default
    tcc_add_include_path(TCC,"/usr/include/x86_64-linux-musl"); // devuan
    tcc_add_include_path(TCC,"src"); // devuan
    // custom paths given on commandline
    if(libtcc_path) {
	    _err("Path to libtcc1.a library: %s",libtcc_path);
	    tcc_set_lib_path(TCC,libtcc_path);
    }
    if(include_path) {
	    _err("Path to headers included: %s",include_path);
	    tcc_add_library_path(TCC,include_path);
    }
    if(libs_path) {
	    _err("Path to libraries linked: %s",libs_path);
	    tcc_add_library_path(TCC,libs_path);
    }

    // set output in memory for just in time execution
    tcc_set_output_type(TCC, TCC_OUTPUT_MEMORY);
    char *code = file_load(code_path);
    if (tcc_compile_string(TCC, code) == -1) return 1;
    free(code); // safe: bytecode compiled is in TCC now

    tcc_add_symbol(TCC, "_out", _out);
    tcc_add_symbol(TCC, "_err", _err);
    tcc_add_symbol(TCC, "exit", exit);
    tcc_add_symbol(TCC, "stdout", stdout);
    tcc_add_symbol(TCC, "stderr", stderr);
    tcc_add_symbol(TCC, "fprintf", fprintf);
    _err("load zenroom symbols: %u",dl_zenroom(TCC));

    // relocate the code
    if (tcc_relocate(TCC) < 0) exit(1);

    // get entry symbol
    int (*_main)(int, char**);
    _main = tcc_get_symbol(TCC, "main");
    if (!_main) exit(1);

    // run the code
    int res = _main(argc, argv);

    // free TCC
    tcc_delete(TCC);

    return res;
}

// Function to get the length of a file in bytes
long file_size(const char *filename) {
    FILE *file = fopen(filename, "rb");
    if (file == NULL) {
        perror("Error opening file");
        return -1;
    }
    fseek(file, 0, SEEK_END);
    long length = ftell(file);
    fclose(file);
    return length;
}

char* file_load(const char *filename) {
    long length = file_size(filename);
    if (length == -1) {
        return NULL;
    }

    FILE *file = fopen(filename, "rb");
    if (file == NULL) {
        perror("Error opening file");
        return NULL;
    }

    char *contents = (char*)malloc((length + 1) * sizeof(char));
    if (contents == NULL) {
        perror("Error allocating memory");
        fclose(file);
        return NULL;
    }

    fread(contents, 1, length, file);
    contents[length] = '\0'; // Null-terminate the string
    fclose(file);

    return contents;
}
