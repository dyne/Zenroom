import os
import subprocess
from setuptools import Extension, setup

ECP_CURVE = 'BLS383'
ECDH_CURVE = 'SECP256K1'

ZENROOM_ROOT = '../../'
ZENROOM_LIB_ROOT = os.path.join(ZENROOM_ROOT, 'src')

LUA_ROOT = os.path.join(ZENROOM_ROOT, 'lib/lua53/src')
MILAGRO_ROOT = os.path.join(ZENROOM_ROOT, 'lib/milagro-crypto-c')
MILAGRO_INCLUDE_DIR = os.path.join(MILAGRO_ROOT, 'include')


def get_version():
    zenroom_version = '1.0.0'
    hash = subprocess.run(['git', 'rev-parse', '--short', 'HEAD'],
                          cwd=ZENROOM_ROOT, text=True,
                          capture_output=True).stdout
    # Last char in hash is a newline
    return zenroom_version + '+' + hash[:-1]


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
current_cwd = os.getcwd()
env = dict(os.environ, MESON_SOURCE_ROOT=current_cwd + '/../',
           MESON_BUILD_ROOT=current_cwd)

zenroom_ecdh_factory = 'zenroom_ecdh_factory.c'
subprocess.check_call(["../../build/codegen_ecdh_factory.sh",
                      ECDH_CURVE, zenroom_ecdh_factory])
subprocess.check_call(["../../build/codegen_ecp_factory.sh", ECP_CURVE],
                      env=env)
os.chdir('../../')
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
                            current_cwd,
                            ZENROOM_LIB_ROOT,
                            LUA_ROOT,
                            MILAGRO_INCLUDE_DIR,
                            'milagro-crypto-c/include',
                        ],
                        extra_compile_args=[
                            '-DVERSION="' + get_version() + '"',
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
        with open(ZENROOM_ROOT + 'README') as f:
            return f.read()
    except IOError:
        pass


setup(
    name='zenroom',
    description='Zenroom for Python: '
                'Bindings of Zenroom library for Python.',
    version=get_version(),
    long_description=get_readme(),
    long_description_content_type='text/org',
    url='https://github.com/dyne/Zenroom',
    author='David Dashyan',
    author_email='mail@davie.li',
    classifiers=[
        'Development Status :: 3 - Alpha',
        'Intended Audience :: Developers',
        'License :: OSI Approved :: MIT License',
        'Programming Language :: Python :: 3',
        'Programming Language :: Python :: 3.6',
        'Programming Language :: Python :: 3.7',
        'Programming Language :: Python :: 3.8',
        'Programming Language :: Python :: 3 :: Only',
    ],
    packages=['zenroom'],
    ext_modules=[zenroom_lib],
    python_requires='>=3.6, <4',
    extras_require={
        'dev': [],
        'test': ['pytest', 'schema'],
    },
)
