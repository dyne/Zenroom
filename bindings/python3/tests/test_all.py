import pytest
import base64
import json
from schema import Schema, Regex
from zenroom import zencode_exec #, zenroom_exec


def test_zencode_call_random_array():
    contract =  """Given nothing
When I create the array of '64' random numbers modulo '100'
and I create the aggregation of array 'array'
Then print the 'array'
and print the 'aggregation'
"""
    res = zencode_exec(
        contract
    )
    out_regex = r'{\"aggregation\":\"\d{4}\",\"array\":\[(?:\"\d{1,3}\"\,)+\"\d{1,3}\"\]}'
    assert Regex(out_regex).validate(res.output)
    assert Schema({
        'aggregation': str,
        'array': [str]
    }).validate(res.result)

def test_extra():
    script="""Scenario 'ecdh': Create the keypair
Given I have a 'string' named 'keys'
Given I have a 'string' named 'data'
Given I have a 'string' named 'extra'
Then print data
"""
    res = zencode_exec(script, "", '{"keys": "keys"}', '{"data": "data"}', '{"extra": "extra"}', "")
    out = '{"data":"data","extra":"extra","keys":"keys"}\n'
    assert res.output == out

def test_zencode_failure():
    contract = """
Given I have a 'string' named 'string'
Then print the data
"""
    res = zencode_exec(contract)
    logs = json.loads(res.logs)
    found = None
    for s in logs:
        if s.startswith("J64 TRACE"):
            found = base64.b64decode(s.split(": ")[1]).decode()
    assert("Cannot find 'string' anywhere " in found)

# def test_lua_call_hello_world():
#     lua_res = zenroom_exec(
#         "print('hello world')"
#     )
#     assert lua_res.output == 'hello world'
