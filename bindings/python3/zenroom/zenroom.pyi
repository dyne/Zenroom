from enum import Enum
from typing import Any, Callable, Optional, Mapping
from ctypes import CDLL


_LIBZENROOM: CDLL


class ZenResult:
    output: str = ...
    error: str = ...
    result: Optional[Mapping] = ...

    def __post_init__(self) -> None:
        ...

    def __init__(self, output: Any, error: Any) -> None:
        ...


def _apply_call(
        call: Callable,
        script: str,
        conf: Optional[str],
        keys: Optional[str],
        data: Optional[str]) -> ZenResult:
    ...


def zenroom_exec(
        script: str,
        conf: Optional[str],
        keys: Optional[str],
        data: Optional[str]) -> ZenResult:
    ...


def zencode_exec(
        script: str,
        conf: Optional[str],
        keys: Optional[str],
        data: Optional[str]) -> ZenResult:
    ...
