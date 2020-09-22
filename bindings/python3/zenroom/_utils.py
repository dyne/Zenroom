"""Utils"""


def case_apply(case, mapping, *args, **kwargs):
    return mapping[case](*args, **kwargs)


def case_call(case, mapping):
    return mapping[case]()
