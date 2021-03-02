import fnmatch
import pathlib
import os

_CURRENT_SOURCE_PATH = pathlib.Path(__file__).parent.resolve()
parent_dir = _CURRENT_SOURCE_PATH.parent.resolve()
LIBZENROOM_LOC = os.path.join(parent_dir, fnmatch.filter(
                    os.listdir(parent_dir), "*.so")[0])
