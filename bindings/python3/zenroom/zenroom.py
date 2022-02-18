"""Zenroom bindings for python 3.6+"""

import io
import json
import ctypes as ct
from dataclasses import dataclass, field

from zenroom._config import LIBZENROOM_LOC


_LIBZENROOM = ct.CDLL(str(LIBZENROOM_LOC))


@dataclass
class ZenResult():
    output: str = field()
    logs: str = field()

    def __post_init__(self):
        try:
            self.result = json.loads(self.output)
        except json.JSONDecodeError:
            self.result = None


def _char_p(x):
    return ct.c_char_p(None if x is None else x.encode())


def _apply_call(call, script, conf, keys, data):
    # 2MB
    stdout_len = 2 * 1024 * 1024
    stdout_buf = ct.create_string_buffer(stdout_len)
    # 64kB
    stderr_len = 64 * 1024
    stderr_buf = ct.create_string_buffer(stderr_len)
    call(
        _char_p(script),
        _char_p(conf),
        _char_p(keys),
        _char_p(data),
        stdout_buf,
        stdout_len,
        stderr_buf,
        stderr_len,
    )
    return ZenResult(
        stdout_buf.value.decode().strip(),
        stderr_buf.value.decode().strip(),
    )


def zenroom_exec(script, conf=None, keys=None, data=None):
    return _apply_call(_LIBZENROOM.zenroom_exec_tobuf, script, conf, keys, data)


def zencode_exec(script, conf=None, keys=None, data=None):
    return _apply_call(_LIBZENROOM.zencode_exec_tobuf, script, conf, keys, data)
