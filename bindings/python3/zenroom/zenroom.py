"""Zenroom bindings for python 3.6+"""

import io
import json
import ctypes as ct
from dataclasses import dataclass, field
from enum import auto, Enum

from zenroom._config import LIBZENROOM_LOC
from zenroom._redirect import redirect_sys_stream
from zenroom._utils import case_apply



_LIBZENROOM = ct.CDLL(str(LIBZENROOM_LOC))


class _ZenLanguage(Enum):
    """Enum for languages supported to execute in Zenroom."""
    lua = auto()
    zencode = auto()


@dataclass
class ZenResult():
    output: str = field()
    error: str = field()

    def __post_init__(self):
        try:
            self.result = json.loads(self.output)
        except json.JSONDecodeError:
            self.result = None


def _libzenroom_exec(language, script, conf, keys, data):
    """Call either zenroom_exec of zencode_exec function depending on language
    argument."""
    def _char_p(x):
        return ct.c_char_p(None if x is None else x.encode())

    case_apply(
        language,
        {_ZenLanguage.lua: _LIBZENROOM.zenroom_exec,
         _ZenLanguage.zencode: _LIBZENROOM.zencode_exec},
        _char_p(script),
        _char_p(conf),
        _char_p(keys),
        _char_p(data)
    )


def lua_exec(script, conf=None, keys=None, data=None):
    """Execute Lua in Zenroom environment"""
    _libzenroom_exec(_ZenLanguage.lua, script, conf, keys, data)


def zencode_exec(script, conf=None, keys=None, data=None):
    """Execute Zencode in Zenroom environment"""
    _libzenroom_exec(_ZenLanguage.zencode, script, conf, keys, data)


def _zenroom_call(language, script, conf, keys, data):
    outbuf = io.BytesIO()
    errbuf = io.BytesIO()
    with redirect_sys_stream(True, outbuf), redirect_sys_stream(False, errbuf):
        case_apply(
            language,
            {_ZenLanguage.lua: lua_exec,
             _ZenLanguage.zencode: zencode_exec},
            script,
            conf,
            keys,
            data
        )
    return ZenResult(
        outbuf.getvalue().decode().strip(),
        errbuf.getvalue().decode().strip(),
    )


def lua_call(script, conf=None, keys=None, data=None):
    return _zenroom_call(_ZenLanguage.lua, script, conf, keys, data)


def zencode_call(script, conf=None, keys=None, data=None):
    return _zenroom_call(_ZenLanguage.zencode, script, conf, keys, data)
