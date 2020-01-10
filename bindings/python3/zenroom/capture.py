import io
import os
import sys
from codecs import EncodedFile
from tempfile import TemporaryFile


class SysCapture:

    EMPTY_BUFFER = str()
    _state = None

    def __init__(self, tmpfile):
        name = "stderr"
        self._old = getattr(sys, name)
        self.name = name
        self.tmpfile = tmpfile

    def start(self):
        setattr(sys, self.name, self.tmpfile)
        self._state = "started"

    def done(self):
        setattr(sys, self.name, self._old)
        del self._old
        self.tmpfile.close()
        self._state = "done"


def safe_text_dupfile(f, mode, default_encoding="UTF8"):
    """ return an open text file object that's a duplicate of f on the
        FD-level if possible.
    """
    encoding = getattr(f, "encoding", None)
    try:
        fd = f.fileno()
    except Exception:
        if "b" not in getattr(f, "mode", "") and hasattr(f, "encoding"):
            # we seem to have a text stream, let's just use it
            return f
    else:
        newfd = os.dup(fd)
        if "b" not in mode:
            mode += "b"
        f = os.fdopen(newfd, mode, 0)  # no buffering
    return EncodedFile(f, encoding or default_encoding)


class FDCaptureBinary:
    """Capture IO to/from a given os-level filedescriptor.
    snap() produces `bytes`
    """

    EMPTY_BUFFER = b""
    _state = None

    def __init__(self):
        self.targetfd = 2
        try:
            self.targetfd_save = os.dup(self.targetfd)
        except OSError:
            self.start = lambda: None
            self.done = lambda: None
        else:
            self.start = self._start
            self.done = self._done
            f = TemporaryFile()
            with f:
                tmpfile = safe_text_dupfile(f, mode="wb+")

            self.syscapture = SysCapture(tmpfile)
            self.tmpfile = tmpfile
            self.tmpfile_fd = tmpfile.fileno()
        self.start()

    def _start(self):
        """ Start capturing on targetfd using memorized tmpfile. """
        try:
            os.fstat(self.targetfd_save)
        except (AttributeError, OSError):
            raise ValueError("saved filedescriptor not valid anymore")
        os.dup2(self.tmpfile_fd, self.targetfd)
        self.syscapture.start()
        self._state = "started"

    def snap(self):
        res = b''
        try:
            self.tmpfile.seek(0)
            res = self.tmpfile.read()
            self.tmpfile.seek(0)
            self.tmpfile.truncate()
        except Exception:
            pass
        return res

    def _done(self):
        """ stop capturing, restore streams, return original capture file,
        seeked to position zero. """
        targetfd_save = self.__dict__.pop("targetfd_save")
        os.dup2(targetfd_save, self.targetfd)
        os.close(targetfd_save)
        self.syscapture.done()
        self.tmpfile.close()
        self._state = "done"


class Capture(FDCaptureBinary):
    """Capture IO to/from a given os-level filedescriptor.
    snap() produces text
    """

    # Ignore type because it doesn't match the type in the superclass (bytes).
    EMPTY_BUFFER = str()  # type: ignore

    def snap(self):
        res = super().snap()
        enc = getattr(self.tmpfile, "encoding", None)
        if isinstance(res, bytes):
            res = str(res, enc if enc else 'utf-8', "replace")

        self.done()
        return res
