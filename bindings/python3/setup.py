import os
from setuptools import Extension, setup

PYTHON_ROOT = os.getcwd()
ZENROOM_ROOT = os.path.join(os.getcwd(), 'src')

def get_versions():
    with open(os.path.join(ZENROOM_ROOT, 'git_utils')) as f:
        zenroom_version = f.readline().strip('\n')
        python_version = f.readline().strip('\n')
    return python_version, zenroom_version


os.chdir(ZENROOM_ROOT)
python_version, zenroom_version = get_versions()
os.chdir(PYTHON_ROOT)


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
    license='AGPLv3',
    keywords='zenroom crypto-language-processing virtual-machine blockchain crypto ecc dyne ecdh ecdsa zero-knowledge-proofs javascript npm ecp2 miller-loop hamming-distance elgamal aes-gcm aead seccomp goldilocks'.split(),
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
    python_requires='>=3.8, <4',
    extras_require={
        'dev': [],
        'test': ['pytest', 'schema'],
    },
)
