project(
    'zenroom',
    'c',
    version: '1.2',
    license: 'GPL3',
     meson_version: '>=0.49.2',
    default_options: [
        'c_std=c99',
        'warning_level=2',
    ],
)

add_project_arguments(
    '-DVERSION="' + meson.project_version() + '"',
    language: 'c'
)

if host_machine.system() == 'darwin'
    arch = 'OSX'
elif host_machine.system() == 'linux'
    arch = 'LINUX'
elif host_machine.system() == 'linux'
    arch = 'BSD'
endif
add_project_arguments(
    '-DARCH_' + arch,
    language: 'c'
)

ecdh_curve = get_option('ecdh_curve')
ecp_curve = get_option('ecp_curve')
zen_ecdh_factory = custom_target('generate_ecdh_factory',
    command: ['../build/codegen_ecdh_factory.sh', ecdh_curve, '@OUTPUT@'],
    output: 'zen_ecdh_factory.c',
    build_by_default: true
)
run_command('codegen_ecp_factory.sh', ecp_curve, check: true)

add_project_link_arguments(
    '-lm',
    'milagro-crypto-c/lib/libamcl_core.a',
    'milagro-crypto-c/lib/libamcl_curve_' + ecdh_curve + '.a',
    'milagro-crypto-c/lib/libamcl_pairing_' + ecp_curve + '.a',
    'milagro-crypto-c/lib/libamcl_curve_' + ecp_curve + '.a',
    language: 'c'
)

run_command('embed-lualibs', check: true)

zenroom_include_dirs = include_directories('../src')

lua_src = files(
    '../lib/lua53/src/lapi.c',
    '../lib/lua53/src/lcode.c',
    '../lib/lua53/src/lctype.c',
    '../lib/lua53/src/ldebug.c',
    '../lib/lua53/src/ldo.c',
    '../lib/lua53/src/ldump.c',
    '../lib/lua53/src/lfunc.c',
    '../lib/lua53/src/lgc.c',
    '../lib/lua53/src/llex.c',
    '../lib/lua53/src/lmem.c',
    '../lib/lua53/src/lobject.c',
    '../lib/lua53/src/lopcodes.c',
    '../lib/lua53/src/lparser.c',
    '../lib/lua53/src/lstate.c',
    '../lib/lua53/src/lstring.c',
    '../lib/lua53/src/ltable.c',
    '../lib/lua53/src/ltm.c',
    '../lib/lua53/src/lundump.c',
    '../lib/lua53/src/lvm.c',
    '../lib/lua53/src/lzio.c',
    '../lib/lua53/src/lauxlib.c',
    '../lib/lua53/src/lbaselib.c',
    '../lib/lua53/src/lcorolib.c',
    '../lib/lua53/src/ldblib.c',
    '../lib/lua53/src/lmathlib.c',
    '../lib/lua53/src/lstrlib.c',
    '../lib/lua53/src/ltablib.c',
    '../lib/lua53/src/lutf8lib.c',
    '../lib/lua53/src/lbitlib.c',
    '../lib/lua53/src/linit.c',
)

milagro_include_dirs = include_directories('../lib/milagro-crypto-c/build/include')
run_command(
    'build-milagro-crypto-c', ecp_curve, ecdh_curve,
    check: true,
)
milagro_generated_include_dirs = include_directories('milagro-crypto-c/build/include')

lua_include_dirs = include_directories('../lib/lua53/src')
lua_lib = static_library('lua',
    lua_src,
    include_directories: [
        lua_include_dirs,
        milagro_include_dirs,
        milagro_generated_include_dirs,
        zenroom_include_dirs
    ],
	c_args: ['-DLUA_COMPAT_5_3', '-DLUA_COMPAT_MODULE', '-DLUA_COMPAT_BITLIB']
)
lua_dep = declare_dependency(
    link_with: lua_lib,
    include_directories : lua_include_dirs
)

zenroom_src = [
    '../src/base58.c',
    '../src/cli.c',
    '../src/cortex_m.c',
    '../src/encoding.c',
    '../src/jutils.c',
    '../src/lua_functions.c',
    '../src/lualibs_detected.c',
    '../src/lua_modules.c',
    '../src/lua_shims.c',
    '../src/lwmem.c',
    '../src/randombytes.c',
    '../src/repl.c',
    '../src/zen_aes.c',
    '../src/zen_big.c',
    '../src/zen_config.c',
    '../src/zen_ecdh.c',
    '../src/zen_ecp2.c',
    '../src/zen_ecp.c',
    '../src/zen_error.c',
    '../src/zen_fp12.c',
    '../src/zen_hash.c',
    '../src/zen_io.c',
    '../src/zen_memory.c',
    '../src/zen_octet.c',
    '../src/zen_parse.c',
    '../src/zen_random.c',
    '../src/zenroom.c',
    zen_ecdh_factory,
]

both_libraries(
    'zenroom',
    zenroom_src,
    include_directories: [
        zenroom_include_dirs,
        milagro_include_dirs,
        milagro_generated_include_dirs,
    ],
    dependencies: [lua_dep]
)

executable(
    'zenroom',
    zenroom_src,
    include_directories: [
        zenroom_include_dirs,
        milagro_include_dirs,
        milagro_generated_include_dirs,
    ],
    dependencies: [lua_dep]
)

