import os
import subprocess
import time
from setuptools import Extension, setup

ECP_CURVE = 'BLS381'
ECDH_CURVE = 'SECP256K1'

PYTHON_ROOT = os.getcwd()
ZENROOM_ROOT = os.path.join( os.getcwd(), 'src')

ZENROOM_LIB_ROOT_REL= 'src/src'
LUA_ROOT = os.path.join(ZENROOM_ROOT, 'lib/lua53/src')
MILAGRO_INCLUDE_DIR = os.path.join(ZENROOM_ROOT, 'lib/milagro-crypto-c/include')
QP_ROOT = os.path.join(ZENROOM_ROOT, 'lib/pqclean')
ZSTD_INCLUDE_DIR = os.path.join(ZENROOM_ROOT, 'lib/zstd')
ED25519_INCLUDE_DIR = os.path.join(ZENROOM_ROOT, 'lib/ed25519-donna')
BLAKE2_INCLUDE_DIR = os.path.join(ZENROOM_ROOT, 'lib/blake2')
MIMALLOC_INCLUDE_DIR = os.path.join(ZENROOM_ROOT, 'lib/mimalloc/include')

def get_versions():
    with open(os.path.join(ZENROOM_ROOT, 'git_utils')) as f:
        zenroom_version = f.readline().strip('\n')
        python_version = f.readline().strip('\n')
    return python_version, zenroom_version


ZENROOM_SOURCES = [
    'rmd160.c',
    'base58.c',
    'segwit_addr.c',
    'cortex_m.c',
    'encoding.c',
    'lua_functions.c',
    'lualibs_detected.c',
    'lua_modules.c',
    'lua_shims.c',
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
    'zen_qp.c',
    'zen_float.c',
    'zen_ed.c',
    'zen_random.c',
    'zenroom.c',
    'zen_ecdh_factory.c'
]

# Add meson build variables to the environment
# source_root = os.path.join(ZENROOM_ROOT, 'build')
meson_root = os.path.join(ZENROOM_ROOT, 'meson')
# env = dict(os.environ,
#            MESON_SOURCE_ROOT=source_root,
#            MESON_BUILD_ROOT=PYTHON_ROOT)

os.chdir(ZENROOM_ROOT)
subprocess.check_call(['make', 'clean'])
subprocess.check_call(['make', 'meson'])
python_version, zenroom_version = get_versions()
os.chdir(PYTHON_ROOT)

zenroom_lib = Extension('zenroom',
                        sources=[
                            os.path.join(ZENROOM_LIB_ROOT_REL, src)
                            for src in ZENROOM_SOURCES
                        ],
                        #  + [zenroom_ecdh_factory] + [
                        #     os.path.join(LUA_ROOT, src)
                        #     for src in LUA_SOURCES
                        # ],
                        include_dirs=[
                            os.getcwd(),
                            ZENROOM_LIB_ROOT_REL,
                            LUA_ROOT,
                            MILAGRO_INCLUDE_DIR,
                            ZSTD_INCLUDE_DIR,
                            ED25519_INCLUDE_DIR,
                            BLAKE2_INCLUDE_DIR,
                            MIMALLOC_INCLUDE_DIR,
                            os.path.join(meson_root, 'milagro-crypto-c/include'),
                            os.path.join(meson_root, 'milagro-crypto-c/include'),
                            # os.path.join(QP_ROOT, 'dilithium2'),
                            # os.path.join(QP_ROOT, 'kyber512'),
                            # os.path.join(QP_ROOT, 'sntrup761'),
                        ],

                        extra_compile_args=[
                            '-DVERSION="' + zenroom_version + '"',
                            # '-DLUA_COMPAT_5_3',
                            # '-DLUA_COMPAT_MODULE',
                            # '-DLUA_COMPAT_BITLIB'
                        ],
                        extra_objects=[
                            os.path.join(meson_root, 'milagro-crypto-c/lib/libamcl_core.a'),
                            os.path.join(meson_root, 'milagro-crypto-c/lib/libamcl_core.a'),
                            os.path.join(meson_root, 'milagro-crypto-c/lib/libamcl_curve_' + ECDH_CURVE + '.a'),
                            os.path.join(meson_root, 'milagro-crypto-c/lib/libamcl_pairing_' + ECP_CURVE + '.a'),
                            os.path.join(meson_root, 'milagro-crypto-c/lib/libamcl_curve_' + ECP_CURVE + '.a'),
                            os.path.join(meson_root, 'libqpz.a'),
                            os.path.join(meson_root, 'libzstd.a'),
                            os.path.join(meson_root, 'liblua.a'),
                            os.path.join(meson_root, 'libed25519.a'),
                            os.path.join(meson_root, 'libblake2.a'),
                            os.path.join(meson_root, 'libmimalloc-static.a'),
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
    version=python_version,
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
        'Programming Language :: Python :: 3.8',
        'Programming Language :: Python :: 3.9',
        'Programming Language :: Python :: 3.10',
        'Programming Language :: Python :: 3.11',
        'Programming Language :: Python :: 3 :: Only',
        'Topic :: Security',
    ],
    project_urls={
        'Homepage': 'https://zenroom.org',
        'Source Code': 'https://github.com/dyne/Zenroom',
        'Documentation': 'https://dev.zenroom.org/',
    },
    packages=['zenroom'],
    include_package_data=True,
    ext_modules=[zenroom_lib],
    python_requires='>=3.8, <4',
    extras_require={
        'dev': [],
        'test': ['pytest', 'schema'],
    },
)
