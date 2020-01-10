import sys
from pathlib import Path

path = Path("../bindings/python3/zenroom/")
sys.path.append(path.resolve())

from zenroom.zenroom import zenroom_exec, zencode_exec

broken_zencode = """Scenario coconut: 'coconut'
When I"""

broken_zenroom = f"""
ZEN:begin(0)

ZEN:parse([[
{broken_zencode}
]])

ZEN:run()
"""

# UNCOMMENT THIS TO SEE ZENroom 
# print("execute zenROOM")
# zenroom_exec(broken_zenroom)


print("execute zenCODE")
zencode_exec(broken_zencode)

