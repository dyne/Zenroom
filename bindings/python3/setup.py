"""Setup"""

from setuptools import setup
import pathlib

current_source_location = pathlib.Path(__file__).parent.resolve()
long_description = ((current_source_location / 'README')
                    .read_text(encoding='utf-8'))

setup(
    name='zenroom',
    version='0.0.1',
    long_description=long_description,
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
    package_data={'zenroom': ['libzenroom.so']},
    package_dir={'': '.'},
    packages=['zenroom'],
    python_requires='>=3.6, <4',
    extras_require={
        'dev': [],
        'test': ['pytest', 'schema'],
    },
)
