import logging
from multiprocessing import Manager, Process
from capturer import CaptureOutput
from .zenroom_swig import zenroom_exec_tobuf, zencode_exec_tobuf

__MAX_STRING__ = 1048576


class ZenroomException(Exception):
    pass


class ZenroomResult:
    def __init__(self, stdout=None, stderr=None):
        self.out = stdout.decode().replace('\x00', '').strip()
        self.err = stderr.decode().replace('\x00', '')

    @property
    def stdout(self):
        return self.out

    @property
    def stderr(self):
        return self.err

    def has_error(self):
        return True if self.err else False

    def __str__(self):
        return "STDOUT: %s\nSTDERR: %s" % (self.stdout, self.stderr)


def _execute(func, result, args):
    args['stdout_buf'] = bytearray(__MAX_STRING__)
    args['stderr_buf'] = bytearray(__MAX_STRING__)
    func(*args.values())
    result.put(ZenroomResult(args['stdout_buf'], args['stderr_buf']))
    result.task_done()


def _zen_call(func, arguments):
    with CaptureOutput() as capturer:
        m = Manager()
        result = m.Queue()
        p = Process(target=_execute, args=(func, result, arguments))
        p.start()
        p.join()
    if result.empty():
        raise ZenroomException(capturer.get_text())

    return result.get()


def zencode_exec(script, keys=None, data=None, conf=None):

    """Invoke Zenroom, capturing and returning the output as a byte string
    This function is the primary method we expose from this wrapper library,
    which attempts to make Zenroom slightly simpler to call from Python. This
    wrapper has only been developed for a specific pilot project within DECODE,
    so beware - the code within this wrapper may be doing very bad things that
    the underlying Zenroom tool does not require.
    Args:
        script (str): Required byte string containing script which Zenroom will execute
        keys (str): Optional byte string containing keys which Zenroom will use
        data (str): Optional byte string containing data upon which Zenroom will operate
        conf (str): Optional byte string containing conf data for Zenroom
    Returns:
            tuple: The output from Zenroom expressed as a byte string, the eventual errors generated as a string
    """
    args = dict(script=script, conf=conf, keys=keys, data=data, stdout_buf=None, stderr_buf=None)
    return _zen_call(zencode_exec_tobuf, args)


def zenroom_exec(script, keys=None, data=None, conf=None):

    """Invoke Zenroom, capturing and returning the output as a byte string
    This function is the primary method we expose from this wrapper library,
    which attempts to make Zenroom slightly simpler to call from Python. This
    wrapper has only been developed for a specific pilot project within DECODE,
    so beware - the code within this wrapper may be doing very bad things that
    the underlying Zenroom tool does not require.
    Args:
        script (str): Required byte string containing script which Zenroom will execute
        keys (str): Optional byte string containing keys which Zenroom will use
        data (str): Optional byte string containing data upon which Zenroom will operate
        conf (str): Optional byte string containing conf data for Zenroom
    Returns:
            bytes: The output from Zenroom expressed as a byte string
    """
    args = dict(script=script, conf=conf, keys=keys, data=data, stdout_buf=None, stderr_buf=None)
    return _zen_call(zenroom_exec_tobuf, args)
