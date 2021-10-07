project(
    'zenroom',
    'c',
    version: '2.0.0',
    license: 'GPL3',
     meson_version: '>=0.49.2',
    default_options: [
        'c_std=c99',
        'warning_level=2',
    ],
)

add_project_arguments(
    '-DVERSION="' + meson.project_version() + '"',
    '-D_POSIX_C_SOURCE=199309',
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
    command: ['/bin/sh', '@SOURCE_ROOT@/codegen_ecdh_factory.sh', ecdh_curve, '@OUTPUT@', '@SOURCE_ROOT@'],
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
    'libzstd.a',
    language: 'c'
)

run_command('embed-lualibs', check: true)

run_command('meson-build-zstd')

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

milagro_include_dirs = include_directories('../lib/milagro-crypto-c/include')
run_command(
    'build-milagro-crypto-c', ecp_curve, ecdh_curve,
    check: true,
)
milagro_generated_include_dirs = include_directories('milagro-crypto-c/include')

zstd_include_dirs = include_directories('../lib/zstd')

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
    '../src/rmd160.c',
    '../src/segwit_addr.c',
    '../src/cortex_m.c',
    '../src/encoding.c',
    '../src/lua_functions.c',
    '../src/lualibs_detected.c',
    '../src/lua_modules.c',
    '../src/lua_shims.c',
    '../src/mutt_sprintf.c',
    '../src/randombytes.c',
    '../src/repl.c',
    '../src/zen_aes.c',
    '../src/zen_big.c',
    '../src/zen_config.c',
    '../src/zen_ecdh.c',
    '../src/zen_pq.c',
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

    '../lib/pqclean/fips202.c',

    '../lib/pqclean/dilithium2/ntt.c',
    '../lib/pqclean/dilithium2/packing.c',
    '../lib/pqclean/dilithium2/poly.c',
    '../lib/pqclean/dilithium2/polyvec.c',
    '../lib/pqclean/dilithium2/reduce.c',
    '../lib/pqclean/dilithium2/rounding.c',
    '../lib/pqclean/dilithium2/sign.c',
    '../lib/pqclean/dilithium2/symmetric-shake.c',

    '../lib/pqclean/kyber512/cbd.c',
    '../lib/pqclean/kyber512/indcpa.c',
    '../lib/pqclean/kyber512/kem.c',
    '../lib/pqclean/kyber512/ntt.c',
    '../lib/pqclean/kyber512/poly.c',
    '../lib/pqclean/kyber512/polyvec.c',
    '../lib/pqclean/kyber512/reduce.c',
    '../lib/pqclean/kyber512/symmetric-shake.c',
    '../lib/pqclean/kyber512/verify.c', 
]

zenroom_lib = library(
    'zenroom',
    zenroom_src,
    include_directories: [
        zenroom_include_dirs,
        milagro_include_dirs,
        milagro_generated_include_dirs,
        zstd_include_dirs,
    ],
    dependencies: [lua_dep],
    install: true,
)

pkg = import('pkgconfig')
pkg.generate(zenroom_lib)

zenroom_dep = declare_dependency(
    link_with: zenroom_lib,
    include_directories: [
        zenroom_include_dirs,
        milagro_include_dirs,
        milagro_generated_include_dirs,
        zstd_include_dirs,
    ],
    dependencies: [lua_dep]
)

install_headers('../src/zenroom.h', subdir: 'zenroom')

zenroom_exe = executable(
    'zenroom',
    '../src/cli.c',
    dependencies: zenroom_dep,
    install: true,
)

docdir = get_option('datadir') / 'doc' / 'zenroom'
if get_option('docs')
    install_subdir('../docs', install_dir: docdir, strip_directory: true)
endif

if get_option('examples')
    install_subdir('../examples', install_dir: docdir, strip_directory: false)
endif

lua_tests = [
    # himem
    'test/sort.lua',
    'test/literals.lua',
    'test/pm.lua',
    'test/nextvar.lua',
    'test/gc.lua',
    'test/calls.lua',
    'test/constructs.lua',
    'test/json.lua',

    # lowmem
    'test/vararg.lua',
    'test/utf8.lua',
    'test/tpack.lua',
    'test/strings.lua',
    'test/math.lua',
    'test/goto.lua',
    'test/events.lua',
    'test/code.lua',
    'test/locals.lua',

    # crypto
    'test/octet.lua',
    'test/octet_conversion.lua',
    'test/hash.lua',
    'test/ecdh.lua',
    'test/dh_session.lua',
    'test/nist/aes_gcm.lua',
    'test/nist/aes_cbc.lua',
    'test/nist/aes_ctr.lua',
    'test/ecp_generic.lua',
    'test/elgamal.lua',
    'test/bls_pairing.lua',
    'test/coconut_test.lua',
    'test/crypto_credential.lua',
    'test/mnemonic_encoding.lua'
]

# test_dir = meson.source_root() + '/../'
foreach test_file : lua_tests
    test(test_file.underscorify(), zenroom_exe, args: ['../'+test_file])
endforeach

test_dir = meson.source_root() + '/../test/'

zencode_tests = [
    'zencode_numbers',
    'zencode_array',
    'zencode_branching',
    'zencode_given',
    'zencode_then',
    'zencode_dictionary',
    'zencode_hash',
    'zencode_http',
    'zencode_keys',
    'zencode_secshare',
    'zencode_ecdh',
    'zencode_credential',
    'zencode_petition',
    'zencode_bitcoin',
    'zencode_ethereum',
    'zencode_schnorr',
    'zencode_w3c',
    'zencode_reflow',
    'zencode_cookbook',
    'zencode_dp3t',
]

foreach zencode_test : zencode_tests
    test_script = find_program(test_dir + zencode_test + '/run.sh')
    test(
        zencode_test,
        test_script,
        env: [
            'ZENROOM=' + zenroom_exe.full_path(),
        ],
        workdir: test_dir + zencode_test
    )
endforeach

zencode_cookbook_script = find_program(test_dir + 'zencode_cookbook/run.sh')
# test( 'zencode_cookbook memmanager=lw', zencode_cookbook_script,
#     env: [ 'ZENROOM=' + zenroom_exe.full_path(), 'MEMMANAGER=lw' ],
#     workdir: test_dir + 'zencode_cookbook')
# test( 'zencode_cookbook print=stb', zencode_cookbook_script,
#     env: [ 'ZENROOM=' + zenroom_exe.full_path(), 'PRINT=stb' ],
#     workdir: test_dir + 'zencode_cookbook')
test( 'zencode_cookbook print=mutt', zencode_cookbook_script,
    env: [ 'ZENROOM=' + zenroom_exe.full_path(), 'PRINT=mutt' ],
    workdir: test_dir + 'zencode_cookbook')

