import pytest
from schema import Schema, Regex
from zenroom import zenroom_exec, zencode_exec


def test_zencode_call_random_array():
    contract =  """Given nothing
When I create the array of '64' random numbers modulo '100'
and I create the aggregation of array 'array'
Then print the 'array' as 'number'
and print the 'aggregation' as 'number'
"""
    res = zencode_exec(
        contract
    )
    out_regex = r'{\"aggregation\":\d{4},\"array\":\[(?:\d{1,3}\,)+\d{1,3}\]}'
    assert Regex(out_regex).validate(res.output)
    assert Schema({
        'aggregation': int,
        'array': [int]
    }).validate(res.result)

def test_zencode_failure():
    contract = """
Given I have a 'string' named 'string'
Then print the data
"""
    res = zencode_exec(contract)
    assert("ERROR" in res.logs)

def test_lua_call_hello_world():
    lua_res = zenroom_exec(
        "print('hello world')"
    )
    assert lua_res.output == 'hello world'
