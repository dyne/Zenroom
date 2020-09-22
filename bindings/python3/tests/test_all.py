# TODO write tests for failuers
import pytest
from schema import Schema, Regex
from zenroom import (
    lua_call,
    zencode_call,
    ZenResult
)


def test_zencode_call_random_array(apply_with_process):
    contract =  """Given nothing
When I create the array of '64' random numbers modulo '100'
and I create the aggregation of array 'array'
Then print the 'array' as 'number'
and print the 'aggregation' as 'number'
"""
    res = apply_with_process(
        zencode_call,
        contract
    )
    out_regex = r'{\"aggregation\":\d{4},\"array\":\[(?:\d{1,3}\,)+\d{1,3}\]}'
    assert Regex(out_regex).validate(res.output)
    assert Schema({
        'aggregation': int,
        'array': [int]
    }).validate(res.result)


def test_lua_call_hello_world(apply_with_process):
    lua_res = apply_with_process(
        lua_call,
        "print('hello world')"
    )
    assert lua_res.output == 'hello world'
