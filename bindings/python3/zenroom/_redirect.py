from contextlib import contextmanager
from enum import Enum
from tempfile import TemporaryFile
import ctypes
import io
import os
import sys


_LIBC = ctypes.CDLL(None)
_LIBC_STDOUT = ctypes.c_void_p.in_dll(_LIBC, 'stdout')
_LIBC_STDERR = ctypes.c_void_p.in_dll(_LIBC, 'stderr')


class _Std(Enum):
    """Enum representing standard io to choose. Values of IN_, OUT and ERR are
    strings representing sys module attributes of coresponding standard io
    wrappers.
    """
    in_ = 'stdin'
    out = 'stdout'
    err = 'stderr'

def _redirect_sys_stream(stdio, stream):

    # sysattr is used for global reference and mutation of sys.stdout and
    # sys.stderr with getattr and setattr.
    sysattr = stdio.value
    libfd = {
        _Std.out: _LIBC_STDOUT,
        _Std.err: _LIBC_STDERR
    }[stdio]

    def redirect_gen():
        original_fd = getattr(sys, sysattr).fileno()

        def _redirect(to_fd):
            _LIBC.fflush(libfd)
            getattr(sys, sysattr).close()
            os.dup2(to_fd, original_fd)
            setattr(
                sys,
                sysattr,
                io.TextIOWrapper(os.fdopen(original_fd, 'wb'))
            )

        saved_fd = os.dup(original_fd)
        try:
            tfile = TemporaryFile(mode='w+b')
            _redirect(tfile.fileno())

            yield

            _redirect(saved_fd)
            tfile.flush()
            tfile.seek(0, io.SEEK_SET)
            stream.write(tfile.read())
        finally:
            tfile.close()
            os.close(saved_fd)

    return redirect_gen()


@contextmanager
def output_to(stream):
    """Context manager to capture data written to stdout from dynamically loaded
    library or an extension"""
    return _redirect_sys_stream(_Std.out, stream)


@contextmanager
def error_to(stream):
    """Context manager to capture data written to stderr from dynamically loaded
    library or an extension"""
    return _redirect_sys_stream(_Std.err, stream)
