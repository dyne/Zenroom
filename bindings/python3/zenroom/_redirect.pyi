from enum import Enum
from typing import Any, IO
from ctypes import CDLL


_LIBC: CDLL
_LIBC_STDOUT: Any
_LIBC_STDERR: Any


class _Std(Enum):
    in_: str = ...
    out: str = ...
    err: str = ...


def _redirect_sys_stream(stdio: _Std, stream: IO) -> None:
    ...


def output_to(stream: IO) -> None:
    ...


def error_to(stream: IO) -> None:
    ...
