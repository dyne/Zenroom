import setuptools
import os
import sys

with open(os.path.join('../..', 'VERSION')) as version_file:
    VERSION = version_file.read().strip()

if sys.argv[-1] == "publish":
    #os.system(f"git tag -a {VERSION}")
    #os.system(f"git push origin {VERSION}")
    os.system("python setup.py sdist bdist_wheel")
    os.system("twine upload dist/*")
    sys.exit()

setuptools.setup(version=VERSION)
