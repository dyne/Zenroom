import setuptools
import os
import sys

VERSION="1.0.7rc2"

if sys.argv[-1] == "publish":
    #os.system(f"git tag -a {VERSION}")
    #os.system(f"git push origin {VERSION}")
    os.system("python setup.py sdist bdist_wheel")
    os.system("twine upload dist/*")
    sys.exit()

setuptools.setup(version=VERSION)
