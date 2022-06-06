# this-party pqclean build with meson+ninja for zenroom
#
# TODO: import CFLAGS from zenroom (profiling, debug, optimize..)

project(
    'qpz',
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

kyber512_src = files('kyber512/cbd.c', 'kyber512/indcpa.c',
                     'kyber512/kem.c', 'kyber512/ntt.c',
                     'kyber512/poly.c', 'kyber512/polyvec.c',
                     'kyber512/reduce.c',
                     'kyber512/symmetric-shake.c',
                     'kyber512/verify.c')

dilithium2_src = files('dilithium2/ntt.c', 'dilithium2/packing.c',
                       'dilithium2/poly.c', 'dilithium2/polyvec.c',
                       'dilithium2/reduce.c', 'dilithium2/rounding.c',
                       'dilithium2/sign.c',
                       'dilithium2/symmetric-shake.c')

sntrup761_src = files('sntrup761/crypto_core_inv3sntrup761.c',
                      'sntrup761/crypto_core_invsntrup761.c',
                      'sntrup761/crypto_core_mult3sntrup761.c',
                      'sntrup761/crypto_core_multsntrup761.c',
                      'sntrup761/crypto_core_scale3sntrup761.c',
                      'sntrup761/crypto_core_weightsntrup761.c',
                      'sntrup761/crypto_core_wforcesntrup761.c',
                      'sntrup761/crypto_decode_761x1531.c',
                      'sntrup761/crypto_decode_761x3.c',
                      'sntrup761/crypto_decode_761x4591.c',
                      'sntrup761/crypto_decode_761xint16.c',
                      'sntrup761/crypto_decode_761xint32.c',
                      'sntrup761/crypto_encode_761x1531.c',
                      'sntrup761/crypto_encode_761x1531round.c',
                      'sntrup761/crypto_encode_761x3.c',
                      'sntrup761/crypto_encode_761x4591.c',
                      'sntrup761/crypto_encode_761xfreeze3.c',
                      'sntrup761/crypto_encode_761xint16.c',
                      'sntrup761/crypto_encode_int16.c',
                      'sntrup761/crypto_sort_int32.c',
                      'sntrup761/crypto_sort_uint32.c',
                      'sntrup761/crypto_verify_1039.c',
                      'sntrup761/kem.c', )

qpz_lib = static_library(
  'qpz',
  sources: [
    'fips202.c', 'sha2.c',
    kyber512_src,
    dilithium2_src,
    sntrup761_src
  ],
  include_directories: [ '.', '../../src/', 'kyber512', 'dilithium2' ],
)
