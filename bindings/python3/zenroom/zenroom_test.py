import json

import pytest

from zenroom import zenroom
from zenroom.zenroom import ZenroomException

LOAD_FATIGUE = 20


def test_basic():
    script = "print('Hello world')"
    output = zenroom.zenroom_exec(script)

    assert "Hello world" == output.stdout


def test_keygen():
    script = """
    print( JSON.encode(map(ECDH.keygen(), hex)) )
    """
    output = zenroom.zenroom_exec(script)
    result = json.loads(output.stdout)
    assert "public" in result
    assert "private" in result


def test_zencode():
    contract = """Scenario coconut petition
rule check version 1.0
Given that I am known as 'identifier'
When I create the credential keypair
Then print all data
    """

    result = zenroom.zencode_exec(contract)
    print(result)
    assert result
    assert "public" in result.stdout
    assert "private" in result.stdout


def test_broken_script():
    with pytest.raises(ZenroomException) as e:
        script = "print('"
        output = zenroom.zenroom_exec(script)
        print(str(e))
        assert e
        assert "line 1" in e


def test_broken_zencode():
    with pytest.raises(ZenroomException) as e:
        contract = """Scenario coconut: 'coconut'
When I"""
        conf = "color:0\ndebug:1"
        result = zenroom.zencode_exec(contract)
        assert result.stderr
        assert "{}" == result.stdout


def test_load_test():
    contract = """Scenario 'coconut': "To run over the mobile wallet the first time and store the output as keypair.keys"
    Given that I am known as 'identifier'
    When I create the credential keypair
    Then print all data
        """

    for _ in range(LOAD_FATIGUE):
        print(f"#{_} CONTRACT")
        result = zenroom.zencode_exec(contract)
        assert "private" in result.stdout


def test_load_script():
    contract = """-- 0 for silent logging
ZEN:begin(0)

ZEN:parse([[
Scenario 'coconut': "To run over the mobile wallet the first time and store the output as keypair.keys"
Given that I am known as 'identifier'
When I create the credential keypair
Then print all data
]])

ZEN:run()
    """

    for _ in range(LOAD_FATIGUE):
        print(f"#{_} CONTRACT")
        result = zenroom.zenroom_exec(contract)
        assert "private" in result.stdout


def test_data():
    script = "print(DATA)"
    data = "3"

    result = zenroom.zenroom_exec(script=script, data=data)
    assert "3" == result.stdout


def st_tally_count():
    contract = """Scenario 'coconut': "count"
    Given that I have a valid 'petition'
    and I have a valid 'petition_tally'
    When I count the petition results
    Then print the 'results'
    """
    data = """{"verifiers":{"alpha":"u64:CTkI_DudfVF9QbyRQjfue_ajdLGmeP5Ednd_j5efcy-WFUmEgqHpxYaAgvGTqcppCly7HNt_qBIzJk9IdlR_RBBEqebNV6jPqudNqGKTwcTo2B806nYRuCEnL97hj7xgDtXNSHu3bf57eEAE2vEcPPmamBHajNtLzRMmM74YwmYwtqZ-F-N2-RliXexESTMQBN8YdWoawA548_S6Ait6sphvrIw4E-Tu2Ti5uDFEYUJ7Muwus8fB0QHB3djmPaiA","beta":"u64:DhlbAie3DM8ZLfPeg9lU02koN5J0mHqDkY10nO0bMvIevMRsRnoztEOId5MllVSeVEgLkhykaDO7ZO50O9TE-5Php7f5XtyWntl0KwGOLzoH3zvdQ2yBl6WHZpBWk7rmAw6KBAQ3IeDWbZ_-pd7I-IyaXh4KI8X2h7v6aqZ1OKWHgMkqmFZfLUmsfmxppqw3Idr5CTqsnttuwFpyLrUv86pbsQ2jCuicCcVFlRMs0Nsf_wKidyVdnkC73cpsnKWQ"},"petition":{"uid":"u64:tion","scores":{"pos":{"right":"u64:BC1FuPqSti6Bj4Ue4ZwQsb-WgoDCvK2h-yoY-Ozi0Vx5VT7Bu03nR6QFls8WJ7u06SNQksgFoaxGWtikoYbfBXY0xmV9ICLGFWpplkGygNIfweN7eG1awNpDxiYFnM8ZdQ","left":"u64:BBgfKpMXsOiDxsOxeNUMoUY32NX2HEMchbtA8SsyreYxfFKiYH8mwzJc2L13BBTNKC54mu-5Pwq1WTNPS9cHRqKzrNa1htWH_iuojpp9PGHOBI7-5idn4fVKEx9Bl9zxmA"},"neg":{"right":"u64:BEKvHEiAMa7CtMfs9e3f1qW_CE7TrAPbzKxJTp39L5akEBhcBbyQck15pdUyiaNhdQD8-8m7zcjIpXxihR0LbZX8mJ-xE9pkjeZTSErTc_bc8ddRFdqqMe8XW4KXkL-rcw","left":"u64:BBgfKpMXsOiDxsOxeNUMoUY32NX2HEMchbtA8SsyreYxfFKiYH8mwzJc2L13BBTNKCbsu6WrbGQARzpeeEjjS-HtAG93bJAdE4CJKWbsJMMmdf1AQ2L8ozaQI_4i7c2_Ew"}},"list":{"u64:BAE2o3kvlEzBcKr3JutK0KGiL1JD8CucEETvQSnYV4B2k7GfxXuzRn9TFyZmG8YTQiBaYOaWxYOqvKPAVsK7yn76NaNLyNGGzsBrrx5sHM0Uyqo9qGrX3vvXwX4UCkiS9w":true},"owner":"u64:BAnXgbjfC-25YaXPjT68wpxxcHWMYMzVdvq8W12fhJR0_l55MtQHLXjjYliES8DDiz9dTXc_5n-8bIFptRiwTPnheJlmE6JBawm4t6GYI7JMjcwwB0Uh4KfD6OunqRm2_w"}}"""
    keys = """{"petition_tally":{"rx":"u64:rDpC3EAjd8xm64oz2Cw31DGOc2JS53pCAe1CeS0H04Q","dec":{"pos":"u64:BEKvHEiAMa7CtMfs9e3f1qW_CE7TrAPbzKxJTp39L5akEBhcBbyQck15pdUyiaNhdQD8-8m7zcjIpXxihR0LbZX8mJ-xE9pkjeZTSErTc_bc8ddRFdqqMe8XW4KXkL-rcw","neg":"u64:BEKvHEiAMa7CtMfs9e3f1qW_CE7TrAPbzKxJTp39L5akEBhcBbyQck15pdUyiaNhdVRoWsuo3aXs-vFLPwLfJO6kFKZ734tAg8Xeb7aV7S4XiLTuE6-6UzzC25rM9OsFOA"},"c":"u64:TzOrx5VC8grFuzVvoXxzADcdazJ3_5b1S6IJbe_tJTA","uid":"u64:tion"},"petition":{"uid":"u64:tion","scores":{"pos":{"right":"u64:BC1FuPqSti6Bj4Ue4ZwQsb-WgoDCvK2h-yoY-Ozi0Vx5VT7Bu03nR6QFls8WJ7u06SNQksgFoaxGWtikoYbfBXY0xmV9ICLGFWpplkGygNIfweN7eG1awNpDxiYFnM8ZdQ","left":"u64:BBgfKpMXsOiDxsOxeNUMoUY32NX2HEMchbtA8SsyreYxfFKiYH8mwzJc2L13BBTNKC54mu-5Pwq1WTNPS9cHRqKzrNa1htWH_iuojpp9PGHOBI7-5idn4fVKEx9Bl9zxmA"},"neg":{"right":"u64:BEKvHEiAMa7CtMfs9e3f1qW_CE7TrAPbzKxJTp39L5akEBhcBbyQck15pdUyiaNhdQD8-8m7zcjIpXxihR0LbZX8mJ-xE9pkjeZTSErTc_bc8ddRFdqqMe8XW4KXkL-rcw","left":"u64:BBgfKpMXsOiDxsOxeNUMoUY32NX2HEMchbtA8SsyreYxfFKiYH8mwzJc2L13BBTNKCbsu6WrbGQARzpeeEjjS-HtAG93bJAdE4CJKWbsJMMmdf1AQ2L8ozaQI_4i7c2_Ew"}},"list":{"u64:BAE2o3kvlEzBcKr3JutK0KGiL1JD8CucEETvQSnYV4B2k7GfxXuzRn9TFyZmG8YTQiBaYOaWxYOqvKPAVsK7yn76NaNLyNGGzsBrrx5sHM0Uyqo9qGrX3vvXwX4UCkiS9w":true},"owner":"u64:BAnXgbjfC-25YaXPjT68wpxxcHWMYMzVdvq8W12fhJR0_l55MtQHLXjjYliES8DDiz9dTXc_5n-8bIFptRiwTPnheJlmE6JBawm4t6GYI7JMjcwwB0Uh4KfD6OunqRm2_w"}}"""

    result = zenroom.zencode_exec(script=contract, data=data, keys=keys)
    json_result = json.loads(result.stdout)

    assert "results" in json_result
    assert 1 == json_result["results"]["pos"]
