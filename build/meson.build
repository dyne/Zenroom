project(
    'zenroom',
    'c',
    version: run_command('meson_version.sh', capture:true, check: true).stdout().strip(),
    license: 'GPL3',
     meson_version: '>=1.1',
    default_options: [
        'c_std=c99',
        'warning_level=2',
    ],
)

suite = get_option('tests')
# if my_array.contains('desired_value')

root_dir = meson.project_source_root() + '/../'
test_dir = meson.project_source_root() + '/../test/'
bats_bin = find_program(test_dir+'bats/bin/bats')
find_program(root_dir+'zenroom')
if suite.contains('zencode-exec')
  find_program(root_dir+'zencode-exec')
endif

## BATS tests in test/determinism
if suite.contains('determinism')
  tests = [ 'determinism' ]
  foreach test_suite : tests
    test('random_'+test_suite.underscorify(),
		 bats_bin,
		 args: [test_dir+test_suite],
		 timeout: 60
		)
  endforeach
endif

## BATS tests in vectors
if suite.contains('vectors')
  tests = [ 'aes', 'ecdsa_p256', 'hmac', 'eddsa', 'sha', 'rsa', 'qp' ]
  foreach test_suite : tests
    test('vectors_'+test_suite.underscorify(),
		 bats_bin,
		 args: [test_dir+'vectors/'+test_suite+'.bats'],
		 timeout: 60
		)
  endforeach
endif

## BATS tests in test/lua
if suite.contains('lua')
tests = [ 'native', 'primitives', 'crypto' ]
foreach test_suite : tests
    test('lua_'+test_suite.underscorify(),
	 bats_bin,
	 args: [test_dir+'lua/'+test_suite+'.bats'],
     timeout: 240
		)
endforeach
endif

## BATS tests in test/zencode
if suite.contains('zencode')
tests = [
'and', 'array', 'bbs_sha', 'bbs_shake', 'bbs_zkp', 'bbs_zkp_shake',
'bitcoin', 'branching', 'cookbook_debug', 'cookbook_dictionaries',
'cookbook_ecdh', 'cookbook_ecdh_encrypt_json', 'cookbook_given',
'cookbook_intro', 'cookbook_then', 'cookbook_when', 'credential',
'dictionary', 'dp3t', 'ecdh', 'educational', 'float', 'foreach', 'fsp',
'generic_bbs', 'generic_dilithium', 'generic_ecdh', 'generic_eddsa',
'generic_es256', 'generic_mldsa44', 'generic_schnorr', 'given',
'hash', 'http', 'keys', 'kyber', 'mlkem512', 'ntrup', 'numbers',
'output', 'pack', 'parser', 'planetmint', 'pvss', 'random',
'reflow','rules', 'scope', 'sd_jwt', 'secshare', 'table', 'then', 'time',
'w3c', 'w3c_did', 'when', 'zenswarm', 'zkp', 'zkp_multi_petitions'
]
# non-portable: 'cookbook_hash_pdf'
# too slow: 'rsa'
foreach test_suite : tests
    test('zencode_'+test_suite.underscorify(),
	 bats_bin,
	 args: [test_dir+'zencode/'+test_suite+'.bats'],
     timeout: 60
		)
endforeach
endif


if suite.contains('bindings')
benches = [ 'bindings_exec', 'bindings_logfmt' ]
foreach test_suite: benches
    benchmark('zencode_'+test_suite.underscorify(),
        bats_bin,
        args: [test_dir+'zencode/'+test_suite+'.bats'],
        timeout: 120
			 )
endforeach
endif

if suite.contains('blockchain')
benches = [ 'ethereum' ]
foreach test_suite: benches
    benchmark('zencode_'+test_suite.underscorify(),
        bats_bin,
        args: [test_dir+'zencode/'+test_suite+'.bats'],
        timeout: 120
			 )
endforeach
endif

if suite.contains('benchmark')
benches = [ 'and', 'array', 'bbs_sha', 'bbs_shake', 'bbs_zkp',
'bbs_zkp_shake', 'bitcoin', 'branching', 'cookbook_dictionaries',
'cookbook_ecdh', 'cookbook_given', 'cookbook_intro', 'cookbook_then',
'cookbook_when', 'credential', 'dictionary', 'ecdh', 'float',
'foreach', 'generic_bbs', 'generic_dilithium', 'generic_ecdh',
'generic_eddsa', 'generic_schnorr', 'given', 'hash', 'kyber', 'ntrup',
'numbers', 'output', 'pack', 'parser', 'planetmint', 'pvss', 'random',
'reflow', 'sd_jwt', 'secshare', 'table', 'then', 'time', 'w3c', 'w3c_did',
'when', 'zencode_exec', 'zenswarm', 'zkp', 'zkp_multi_petitions',
'fsp' ]
foreach test_suite: benches
    benchmark('zencode_'+test_suite.underscorify(),
        bats_bin,
        args: [test_dir+'zencode/'+test_suite+'.bats'],
        timeout: 120
			 )
endforeach
endif

if suite.contains('api')
## BATS tests in test/api
tests = [ 'hash', 'sign' ]
foreach test_suite : tests
    test('api_'+test_suite.underscorify(),
	 bats_bin,
	 args: [test_dir+'api/'+test_suite+'.bats'],
     timeout: 60
		)
endforeach
endif
