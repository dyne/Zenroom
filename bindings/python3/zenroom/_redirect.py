from contextlib import contextmanager
from tempfile import NamedTemporaryFile
import os
import sys


@contextmanager
def redirect_sys_stream(is_stdout, stream):
    fd_to_redirect = sys.stdout.fileno() if is_stdout else sys.stderr.fileno()
    saved_fd = os.dup(fd_to_redirect)
    with NamedTemporaryFile() as write_buf:
        os.dup2(write_buf.fileno(), fd_to_redirect)
        try:
            yield
        finally:
            write_buf.flush()
            with open(write_buf.name, 'rb') as read_buf:
                stream.write(read_buf.read())
            os.close(fd_to_redirect)
            os.dup2(saved_fd, fd_to_redirect)
            os.close(saved_fd)
