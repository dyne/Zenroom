import os
import sys
from time import process_time

path = "../bindings/python3/zenroom/"
sys.path.append(os.path.abspath(path))

from zenroom.zenroom import zenroom_exec

print("[PY] zenroom_exec %s" % sys.argv[2])
scriptfile = os.path.join(sys.argv[1], sys.argv[2])
with open(scriptfile, 'rb') as script: 
    script = script.read()
    try:
        script = script.decode('utf-8')
    except UnicodeDecodeError:
        script = script.decode('iso-8859-1')
    start = process_time()
    result = zenroom_exec(script=script)
    end = process_time() - start
    print( result.stdout)
    print("--- %s seconds ---" % end)
    print("@", "="*40, "@")
