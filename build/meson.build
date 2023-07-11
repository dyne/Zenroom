project(
    'zenroom',
    'c',
    version: run_command('meson_version.sh', capture:true, check: true).stdout().strip(),
    license: 'GPL3',
     meson_version: '>=0.49.2',
    default_options: [
        'c_std=c99',
        'warning_level=2',
    ],
)

if run_command(['git','describe'], check:false).returncode() == 0
    commit_hash = run_command(['git', 'rev-parse', '--short', 'HEAD'], capture: true, check : true).stdout().strip()
else
    commit_hash = run_command(['awk', 'NR==3', '../git_utils'], capture: true, check : true).stdout().strip()
endif
current_year = run_command(['date','+%Y'],capture:true, check:true).stdout().strip()

add_project_arguments(
    '-DVERSION="' + meson.project_version() +'"',
    '-DCURRENT_YEAR="' + current_year +'"',
    '-DCOMMIT="' + commit_hash +'"',
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
    '-lpthread',
    '-lm',
    'milagro-crypto-c/lib/libamcl_core.a',
    'milagro-crypto-c/lib/libamcl_curve_' + ecdh_curve + '.a',
    'milagro-crypto-c/lib/libamcl_pairing_' + ecp_curve + '.a',
    'milagro-crypto-c/lib/libamcl_curve_' + ecp_curve + '.a',
    'liblua.a',
    'libqpz.a',
    'libed25519.a',
	'libblake2.a',
    'libmimalloc-static.a',
    language: 'c'
)

zenroom_include_dirs = include_directories('../src')

milagro_include_dirs = include_directories('../lib/milagro-crypto-c/include')

milagro_generated_include_dirs = include_directories('milagro-crypto-c/include')

mimalloc_include_dirs = include_directories('../lib/mimalloc/include')

lua_include_dirs = include_directories('../lib/lua53/src')

ed25519_include_dirs = include_directories('../lib/ed25519-donna')

blake2_include_dirs = include_directories('../lib/blake2')

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
    '../src/api_hash.c',
    '../src/zen_aes.c',
    '../src/zen_big.c',
    '../src/zen_float.c',
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
	ed25519_include_dirs,
	blake2_include_dirs,
        lua_include_dirs,
	mimalloc_include_dirs,
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
	ed25519_include_dirs,
	blake2_include_dirs,
        lua_include_dirs,
	mimalloc_include_dirs,
    ],
)

install_headers('../src/zenroom.h', subdir: 'zenroom')

zenroom_exe = executable(
    'zenroom',
    '../src/cli-zenroom.c',
    dependencies: zenroom_dep,
    install: true,
)

zencode_exe = executable(
    'zencode-exec',
    '../src/zencode-exec.c',
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


## BATS tests in test/determinism
test_dir = meson.source_root() + '/../test/'
bats_bin = find_program(test_dir+'bats/bin/bats')
tests = [ 'determinism' ]
foreach test_suite : tests
    test('random_'+test_suite.underscorify(),
	 bats_bin,
	 args: [test_dir+test_suite],
         timeout: 60)
endforeach

## BATS tests in vectors
test_dir = meson.source_root() + '/../test/'
bats_bin = find_program(test_dir+'bats/bin/bats')
tests = [ 'sha', 'aes', 'hmac', 'blake2' ]
foreach test_suite : tests
    test('vectors_'+test_suite.underscorify(),
	 bats_bin,
	 args: [test_dir+'vectors/'+test_suite+'.bats'],
         timeout: 60)
endforeach

## BATS tests in test/lua
test_dir = meson.source_root() + '/../test/'
bats_bin = find_program(test_dir+'bats/bin/bats')
tests = [ 'lowmem', 'himem', 'primitives', 'crypto' ]
foreach test_suite : tests
    test('lua_'+test_suite.underscorify(),
	 bats_bin,
	 args: [test_dir+'lua/'+test_suite+'.bats'],
         timeout: 60)
endforeach

## BATS tests in test/zencode
test_dir = meson.source_root() + '/../test/'
bats_bin = find_program(test_dir+'bats/bin/bats')
tests = [
'and', 'array', 'bbs_sha', 'bbs_shake', 'bbs_zkp', 'bbs_zkp_shake', 'bitcoin', 'branching',
'credential', 'dictionary', 'dp3t', 'ecdh', 'ethereum', 'float', 'foreach', 'generic_bbs',
'generic_dilithium', 'generic_ecdh', 'generic_eddsa', 'generic_schnorr', 'given', 'hash',
'http', 'keys', 'kyber', 'ntrup', 'numbers', 'output', 'pack', 'parser', 'planetmint', 'pvss',
'random', 'reflow', 'rules', 'secshare', 'then', 'w3c', 'w3c_did', 'when', 'zenswarm',
'zkp', 'zkp_multi_petitions', 'zencode_exec'
]
foreach test_suite : tests
    test('zencode_'+test_suite.underscorify(),
	 bats_bin,
	 args: [test_dir+'zencode/'+test_suite+'.bats'],
         timeout: 60)
endforeach

## BATS tests in test/api
test_dir = meson.source_root() + '/../test/'
bats_bin = find_program(test_dir+'bats/bin/bats')
tests = [ 'hash' ]
foreach test_suite : tests
    test('api_'+test_suite.underscorify(),
	 bats_bin,
	 args: [test_dir+'api/'+test_suite+'.bats'],
         timeout: 60)
endforeach
