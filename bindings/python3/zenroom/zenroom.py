from multiprocessing import Manager, Process
from .zenroom_swig import zenroom_exec_tobuf, zencode_exec_tobuf, zencode_exec_rng_tobuf, zenroom_exec_rng_tobuf


__MAX_STRING__ = 1048576


class ZenroomException(Exception):
    pass


class ZenroomResult:
    def __init__(self, stdout, stderr, result):
        self.out = stdout.decode().replace('\x00', '').strip()
        self.err = stderr.decode().replace('\x00', '')
        self.result = result

    @property
    def stdout(self):
        return self.out

    @property
    def stderr(self):
        return self.err

    def has_error(self):
        return not self.result

    def get_wanings(self):
        warns = (line for line in self.err.split('\n') if line[1:2]=="W")
        return list(warns)

    def get_info(self):
        info = (line for line in self.err.split('\n') if line[1:2]=="I")
        return list(info)

    def get_debug(self):
        debug = (line for line in self.err.split('\n') if line[1:2]=="D")
        return list(debug)

    def get_errors(self):
        errors = (line for line in self.err.split('\n') if line[1:2]=="!")
        return list(errors)

    def __str__(self):
        return "STDOUT: %s\nSTDERR: %s" % (self.stdout, self.stderr)


def _execute(func, result, args):
    args['stdout_buf'] = bytearray(__MAX_STRING__)
    args['stderr_buf'] = bytearray(__MAX_STRING__)
    return_code = func(*args.values())
    result.put(ZenroomResult(args['stdout_buf'], args['stderr_buf'], return_code))
    result.task_done()


def _zen_call(func, arguments):
    m = Manager()
    result = m.Queue()
    p = Process(target=_execute, args=(func, result, arguments))
    p.start()
    p.join()
    if result.empty():
        raise ZenroomException()

    return result.get()


def zencode_exec(script, keys=None, data=None, conf=None, verbosity=1):
    args = dict(script=script, conf=conf, keys=keys, data=data, verbosity=verbosity, stdout_buf=None, stderr_buf=None)
    return _zen_call(zencode_exec_tobuf, args)


def zenroom_exec(script, keys=None, data=None, conf=None, verbosity=1):
    args = dict(script=script, conf=conf, keys=keys, data=data, verbosity=verbosity, stdout_buf=None, stderr_buf=None)
    return _zen_call(zenroom_exec_tobuf, args)


def zenroom_exec_rng(script, random_seed, keys=None, data=None, conf=None, verbosity=1):
    args = dict(script=script, conf=conf, keys=keys, data=data, verbosity=verbosity, stdout_buf=None, stderr_buf=None, random_seed=random_seed)
    return _zen_call(zenroom_exec_rng_tobuf, args)


def zencode_exec_rng(script, random_seed, keys=None, data=None, conf=None, verbosity=1):
    args = dict(script=script,
                conf=conf,
                keys=keys,
                data=data,
                verbosity=verbosity,
                stdout_buf=None,
                stderr_buf=None,
                random_seed=random_seed)
    return _zen_call(zencode_exec_rng_tobuf, args)
