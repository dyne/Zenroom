import os
import subprocess
import time
from setuptools import Extension, setup

ECP_CURVE = 'BLS383'
ECDH_CURVE = 'SECP256K1'

if os.path.exists('bindings'):
    ZENROOM_ROOT = os.getcwd()
else:
    ZENROOM_ROOT = os.path.dirname(os.path.dirname(os.getcwd()))


ZENROOM_LIB_ROOT = os.path.join(ZENROOM_ROOT, 'src')

LUA_ROOT = os.path.join(ZENROOM_ROOT, 'lib/lua53/src')
MILAGRO_INCLUDE_DIR = os.path.join(ZENROOM_ROOT,
                                   'lib/milagro-crypto-c/include')


def get_zenroom_version():
    zenroom_version = '1.0.0'
    hash = subprocess.run(['git', 'rev-parse', '--short', 'HEAD'],
                          cwd=ZENROOM_ROOT,
                          stdout=subprocess.PIPE).stdout.decode('utf-8')
    # Last char in hash is a newline
    return zenroom_version + '+' + hash[:-1]


def get_python_version():
    zenroom_version = '2.0.0'
    current_time = ''
    try:
        with open(os.path.join(ZENROOM_ROOT, 'current_time')) as f:
            current_time = f.read()
    except IOError:
        current_time = str(int(time.time()))
    # Last char in hash is a newline
    return zenroom_version + '.dev' + current_time


ZENROOM_SOURCES = [
    'base58.c',
    'cli.c',
    'cortex_m.c',
    'encoding.c',
    'jutils.c',
    'lua_functions.c',
    'lualibs_detected.c',
    'lua_modules.c',
    'lua_shims.c',
    'lwmem.c',
    'mutt_sprintf.c',
    'randombytes.c',
    'repl.c',
    'zen_aes.c',
    'zen_big.c',
    'zen_config.c',
    'zen_ecdh.c',
    'zen_ecp2.c',
    'zen_ecp.c',
    'zen_error.c',
    'zen_fp12.c',
    'zen_hash.c',
    'zen_io.c',
    'zen_memory.c',
    'zen_octet.c',
    'zen_parse.c',
    'zen_random.c',
    'zenroom.c',
]

LUA_SOURCES = [
    'lapi.c',
    'lcode.c',
    'lctype.c',
    'ldebug.c',
    'ldo.c',
    'ldump.c',
    'lfunc.c',
    'lgc.c',
    'llex.c',
    'lmem.c',
    'lobject.c',
    'lopcodes.c',
    'lparser.c',
    'lstate.c',
    'lstring.c',
    'ltable.c',
    'ltm.c',
    'lundump.c',
    'lvm.c',
    'lzio.c',
    'lauxlib.c',
    'lbaselib.c',
    'lcorolib.c',
    'ldblib.c',
    'lmathlib.c',
    'lstrlib.c',
    'ltablib.c',
    'lutf8lib.c',
    'lbitlib.c',
    'linit.c',
]

# Add meson build variables to the environment
build_root = os.path.join(ZENROOM_ROOT, 'bindings/python3/')
source_root = os.path.join(ZENROOM_ROOT, 'build')
env = dict(os.environ,
           MESON_SOURCE_ROOT=source_root,
           MESON_BUILD_ROOT=build_root)

os.chdir(ZENROOM_ROOT)
zenroom_ecdh_factory = 'zenroom_ecdh_factory.c'
subprocess.check_call(["build/codegen_ecdh_factory.sh",
                      ECDH_CURVE, 'bindings/python3/' + zenroom_ecdh_factory])
subprocess.check_call(["build/codegen_ecp_factory.sh", ECP_CURVE],
                      env=env)
subprocess.check_call("build/embed-lualibs")

# Build milagro-lib
subprocess.check_call(["build/build-milagro-crypto-c",
                      ECP_CURVE, ECDH_CURVE],
                      env=env)

os.chdir("bindings/python3/")

zenroom_lib = Extension('zenroom',
                        sources=[
                            os.path.join(ZENROOM_LIB_ROOT, src)
                            for src in ZENROOM_SOURCES
                        ] + [zenroom_ecdh_factory] + [
                            os.path.join(LUA_ROOT, src)
                            for src in LUA_SOURCES
                        ],
                        include_dirs=[
                            os.getcwd(),
                            ZENROOM_LIB_ROOT,
                            LUA_ROOT,
                            MILAGRO_INCLUDE_DIR,
                            'milagro-crypto-c/include',
                        ],
                        extra_compile_args=[
                            '-DVERSION="' + get_zenroom_version() + '"',
                            '-DLUA_COMPAT_5_3',
                            '-DLUA_COMPAT_MODULE',
                            '-DLUA_COMPAT_BITLIB'
                        ],
                        extra_objects=[
                            'milagro-crypto-c/lib/libamcl_core.a',
                            'milagro-crypto-c/lib/libamcl_curve_' + ECDH_CURVE + '.a',
                            'milagro-crypto-c/lib/libamcl_pairing_' + ECP_CURVE + '.a',
                            'milagro-crypto-c/lib/libamcl_curve_' + ECP_CURVE + '.a',
                        ],
                        extra_link_args=['-lm']
                        )


def get_readme():
    try:
        with open(os.path.join(ZENROOM_ROOT, 'docs/pages/python.md')) as f:
            return f.read()
    except IOError:
        pass


setup(
    name='zenroom',
    description='Zenroom for Python: Bindings of Zenroom library for Python.',
    version=get_python_version(),
    long_description=get_readme(),
    long_description_content_type='text/markdown',
    license = 'AGPLv3',
    keywords = 'zenroom crypto-language-processing virtual-machine blockchain crypto ecc dyne ecdh ecdsa zero-knowledge-proofs javascript npm ecp2 miller-loop hamming-distance elgamal aes-gcm aead seccomp goldilocks'.split(),
    url='https://github.com/dyne/Zenroom',
    author='Danilo Spinella, David Dashyan, Puria Nafisi Azizi',
    author_email='danyspin@dyne.org, mail@davie.li, puria@dyne.org',
    classifiers=[
        'Development Status :: 3 - Alpha',
        'Intended Audience :: Developers',
        'License :: OSI Approved :: GNU Affero General Public License v3',
        'Operating System :: POSIX :: Linux',
        'Operating System :: MacOS :: MacOS X',
        'Programming Language :: Python :: 3',
        'Programming Language :: Python :: 3.6',
        'Programming Language :: Python :: 3.7',
        'Programming Language :: Python :: 3.8',
        'Programming Language :: Python :: 3.9',
        'Programming Language :: Python :: 3 :: Only',
        'Topic :: Security',
    ],
    project_urls={
        'Source Code': 'https://github.com/dyne/Zenroom',
        'Documentation': 'https://dev.zenroom.org/',
        'DECODE': 'https://decodeproject.eu',
        'DYNE': 'https://dyne.org',
        'ZENROOM': 'https://zenroom.org',
    },
    packages=['zenroom'],
    ext_modules=[zenroom_lib],
    python_requires='>=3.6, <4',
    extras_require={
        'dev': [],
        'test': ['pytest', 'schema'],
    },
)
