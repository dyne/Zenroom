import sys
from pathlib import Path
from time import process_time

path = Path("../bindings/python3/zenroom/")
sys.path.append(path.resolve())

from zenroom.zenroom import zenroom_exec

print("[PY] zenroom_exec %s" % sys.argv[1])
script_path = Path(sys.argv[1])

try:
    script = script_path.read_text()
except UnicodeDecodeError:
    script = script_path.read_text(encoding='iso-8859-1')

start = process_time()
result = zenroom_exec(script=script)
end = process_time() - start

print(result if result else '')
print("--- %s seconds ---" % end)
print("@", "="*40, "@")
