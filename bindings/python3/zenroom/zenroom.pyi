from enum import Enum
from typing import Any, Optional, Mapping
from ctypes import CDLL

from zenroom._config import LIBZENROOM_LOC as LIBZENROOM_LOC
from zenroom._redirect import error_to as error_to, output_to as output_to
from zenroom._utils import case_apply as case_apply


_LIBZENROOM: CDLL


class _ZenLanguage(Enum):
    lua: int = ...
    zencode: int = ...


class ZenResult:
    output: str = ...
    error: str = ...
    result: Optional[Mapping] = ...

    def __post_init__(self) -> None:
        ...

    def __init__(self, output: Any, error: Any) -> None:
        ...


def _libzenroom_exec(
        language: _ZenLanguage,
        script: str,
        conf: Optional[str],
        keys: Optional[str],
        data: Optional[str]) -> None:
    ...


def lua_exec(
        script: str,
        conf: Optional[str],
        keys: Optional[str],
        data: Optional[str]) -> None:
    ...


def zencode_exec(
        script: Any,
        conf: Optional[str],
        keys: Optional[str],
        data: Optional[str]) -> None:
    ...


def _zenroom_call(
        language: _ZenLanguage,
        script: str,
        conf: Optional[str],
        keys: Optional[str],
        data: Optional[str]) -> ZenResult:
    ...


def lua_call(
        script: str,
        conf: Optional[str],
        keys: Optional[str],
        data: Optional[str]) -> ZenResult:
    ...


def zencode_call(
        script: str,
        conf: Optional[str],
        keys: Optional[str],
        data: Optional[str]) -> ZenResult:
    ...
