from typing import Any, Mapping


def case_apply(case: Any, mapping: Mapping, *args: Any, **kwargs: Any) -> Any:
    ...


def case_call(case: Any, mapping: Mapping) -> Any:
    ...
