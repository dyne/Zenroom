#!/usr/bin/env python3

# simple redis client written in python to demonstrate usage of the
# redis api with mutli-line variables used as scripts (also zencode)
# works with a dlmopen patched redis running the zenroom module

import redis

r = redis.Redis(host='localhost', port=6379, db=0)
r.execute_command("zenroom.debug", "1")

r.set("script", """
print('Hello World!')
""")
res = r.execute_command("zenroom.exec", "script")
print(res)

r.set("script", """Scenario 'coconut': issuer key generation
  Given that I am known as 'MadHatter'
  When I create my new issuer keypair
  Then print all data""")
res = r.execute_command("zencode.exec", "script")
print(res)

