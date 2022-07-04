project(
    'zenroom',
    'c',
    version: '3.0.0-devel',
    license: 'GPL3',
     meson_version: '>=0.49.2',
    default_options: [
        'c_std=c99',
        'warning_level=2',
    ],
)

add_project_arguments(
    '-DVERSION="' + meson.project_version() + '"',
    '-D_POSIX_C_SOURCE=200112L',
    '-D_DARWIN_C_SOURCE',
    language: 'c'
)

if host_machine.system() == 'darwin'
    arch = 'OSX'
elif host_machine.system() == 'linux'
    arch = 'LINUX'
else
    arch = 'BSD'
endif
add_project_arguments(
    '-DARCH_' + arch,
    language: 'c'
)

ecdh_curve = get_option('ecdh_curve')
ecp_curve = get_option('ecp_curve')

add_project_link_arguments(
    '-lm',
    'milagro-crypto-c/lib/libamcl_core.a',
    'milagro-crypto-c/lib/libamcl_curve_' + ecdh_curve + '.a',
    'milagro-crypto-c/lib/libamcl_pairing_' + ecp_curve + '.a',
    'milagro-crypto-c/lib/libamcl_curve_' + ecp_curve + '.a',
    'liblua.a',
    'libzstd.a',
    'libqpz.a',
    'libed25519.a',
    language: 'c'
)

zenroom_include_dirs = include_directories('../src')

milagro_include_dirs = include_directories('../lib/milagro-crypto-c/include')

milagro_generated_include_dirs = include_directories('milagro-crypto-c/include')

zstd_include_dirs = include_directories('../lib/zstd')

lua_include_dirs = include_directories('../lib/lua53/src')

ed25519_include_dirs = include_directories('../lib/ed25519-donna')

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
    '../src/zen_qp.c',
    '../src/zen_ed.c',
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
    '../src/zen_ecdh_factory.c',
]

zenroom_lib = library(
    'zenroom',
    zenroom_src,
    include_directories: [
        zenroom_include_dirs,
        milagro_include_dirs,
        milagro_generated_include_dirs,
        zstd_include_dirs,
	ed25519_include_dirs,
        lua_include_dirs,
    ],
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
	ed25519_include_dirs,
        lua_include_dirs,
    ],
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
    'test/crypto_nist/aes_gcm.lua',
    'test/crypto_nist/aes_cbc.lua',
    'test/crypto_nist/aes_ctr.lua',
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
    'zencode_random',
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
    'zencode_eddsa',
    'zencode_credential',
    'zencode_petition',
    'zencode_bitcoin',
    'zencode_ethereum',
    'zencode_schnorr',
    'zencode_w3c',
    'zencode_reflow',
    'zencode_cookbook',
    'zencode_dp3t',
    'zencode_qp',
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

crypto_tests = [
  'crypto_nist',
  'crypto_json',
  'crypto_ecdh',
  'crypto_eddsa',
]
foreach crypto_test : crypto_tests
    test_script = find_program(test_dir + crypto_test + '/run.sh')
    test(crypto_test, test_script, env: [
            'ZENROOM=' + zenroom_exe.full_path(),
        ], workdir: test_dir + crypto_test)
endforeach


# cookbook compared with different print routines
zencode_cookbook_script = find_program(test_dir + 'zencode_cookbook/run-all.sh')
test( 'zencode_cookbook print=sys', zencode_cookbook_script,
    env: [ 'ZENROOM=' + zenroom_exe.full_path(), 'PRINT=mutt' ],
    workdir: test_dir + 'zencode_cookbook')
test( 'zencode_cookbook print=mutt', zencode_cookbook_script,
    env: [ 'ZENROOM=' + zenroom_exe.full_path(), 'PRINT=mutt' ],
    workdir: test_dir + 'zencode_cookbook')
test( 'zencode_cookbook print=stb', zencode_cookbook_script,
    env: [ 'ZENROOM=' + zenroom_exe.full_path(), 'PRINT=mutt' ],
    workdir: test_dir + 'zencode_cookbook')


# test( 'zencode_cookbook memmanager=lw', zencode_cookbook_script,
#     env: [ 'ZENROOM=' + zenroom_exe.full_path(), 'MEMMANAGER=lw' ],
#     workdir: test_dir + 'zencode_cookbook')
# test( 'zencode_cookbook print=stb', zencode_cookbook_script,
#     env: [ 'ZENROOM=' + zenroom_exe.full_path(), 'PRINT=stb' ],
#     workdir: test_dir + 'zencode_cookbook')
