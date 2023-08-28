"""Zenroom bindings for python 3.6+"""

import json
from dataclasses import dataclass, field
import subprocess
import base64


@dataclass
class ZenResult():
    output: str = field()
    logs: str = field()

    def __post_init__(self):
        try:
            self.result = json.loads(self.output)
        except json.JSONDecodeError:
            self.result = None


def zencode_exec(script, conf=None, keys=None, data=None, extra=None, context=None):
    zen_input = []
    if conf:
        zen_input.append(conf)
    zen_input.append(b'\n')
    zen_input.append(base64.b64encode(script.encode()))
    zen_input.append(b'\n')
    if keys:
        zen_input.append(base64.b64encode(keys.encode()))
    zen_input.append(b'\n')
    if data:
        zen_input.append(base64.b64encode(data.encode()))
    zen_input.append(b'\n')
    if extra:
        zen_input.append(base64.b64encode(extra.encode()))
    zen_input.append(b'\n')
    if context:
        zen_input.append(base64.b64encode(context.encode()))
    zen_input.append(b'\n')
    res = subprocess.run(["zencode-exec"],
                         capture_output=True,
                         input=b''.join(zen_input))

    return ZenResult(res.stdout.decode(), res.stderr.decode())
