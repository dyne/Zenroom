import pytest
import multiprocessing as mp


@pytest.fixture
def mp_context():
    return  mp.get_context('spawn')


@pytest.fixture
def apply_with_process(mp_context):
    queue = mp_context.Queue()

    def _in_process(function, *args, **kwarags):
        def _in_process_closure(*args, **kwargs):
            queue.put(function(*args, **kwargs))
        return _in_process_closure

    def _closure(target, *args, **kwargs):
        proc = mp.Process(target=_in_process(target), args=args, kwargs=kwargs)
        proc.start()
        proc.join()
        if proc.exitcode != 0 or queue.empty():
            raise Exception(proc, queue)
        else:
            return queue.get()

    yield _closure
