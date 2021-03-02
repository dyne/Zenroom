"""Zenroom bindings for python 3.6+"""

import io
import json
import ctypes as ct
from dataclasses import dataclass, field

from zenroom._config import LIBZENROOM_LOC
from zenroom._redirect import redirect_sys_stream


_LIBZENROOM = ct.CDLL(str(LIBZENROOM_LOC))


@dataclass
class ZenResult():
    output: str = field()
    error: str = field()

    def __post_init__(self):
        try:
            self.result = json.loads(self.output)
        except json.JSONDecodeError:
            self.result = None


def _char_p(x):
    return ct.c_char_p(None if x is None else x.encode())


def _apply_call(call, script, conf, keys, data):
    outbuf = io.BytesIO()
    errbuf = io.BytesIO()
    with redirect_sys_stream(True, outbuf), redirect_sys_stream(False, errbuf):
        call(
            _char_p(script),
            _char_p(conf),
            _char_p(keys),
            _char_p(data)
        )
    return ZenResult(
        outbuf.getvalue().decode().strip(),
        errbuf.getvalue().decode().strip(),
    )


def zenroom_exec(script, conf=None, keys=None, data=None):
    return _apply_call(_LIBZENROOM.zenroom_exec, script, conf, keys, data)


def zencode_exec(script, conf=None, keys=None, data=None):
    return _apply_call(_LIBZENROOM.zencode_exec, script, conf, keys, data)
