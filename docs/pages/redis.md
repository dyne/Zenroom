# Zenroom Redis module

A build of Zenroom as Redis module is supported by the target `linux-redis`, which will build a shared library object in `src/redis_zenroom.so-x86_64-0.9.so` (or subsequent versions). Such a module will be loaded if the configuration directive `loadmodule src/redis_zenroom.so-x86_64-0.9.so` is present in the `redis.conf` in use.

The module will only work with `dlmopen` patched Redis, see https://github.com/antirez/redis/pull/6125 - reason being that Zenroom carries its own Lua interpreter and a namespace clash with the host application (redis) needs to be avoided.

Once loaded the current commands will be available:

- zenroom.debug [1 | 2 | 3]
- zenroom.reset
- zenroom.exec script [ data ] [ keys ]
- zencode.exec script [ data ] [ keys ]

Where `script`, `data` and `keys` are names of variables whose contents will be used by Zenroom. 

All commands will return a string with results, future plans includes `.exec_tokey` commands that will print output as content into a key.

To facilitate multi-line contents of keys to be passed to Zenroom, here a redis client example in python:

```py
import redis

r = redis.Redis(host='localhost', port=6379, db=0)
r.execute_command("zenroom.debug", "1")

r.set("script", "print('Hello World!')")
res = r.execute_command("zenroom.exec", "script")
print(res)

r.set("script", """Scenario 'coconut': issuer key generation
  Given that I am known as 'MadHatter'
  When I create my new issuer keypair
  Then print all data""")
res = r.execute_command("zencode.exec", "script")
print(res)
```
 
