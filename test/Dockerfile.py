FROM dyne/zenroom:latest

# run python3 tests

WORKDIR /code/zenroom

RUN apk add python3 python3-dev swig
RUN ln -s /usr/bin/python3 /usr/bin/python
RUN make clean && make linux-python3
RUN awk '/ZENROOM_VERSION :=/ { print $3 }' src/Makefile > bindings/VERSION
RUN python3 -m venv venv && source venv/bin/activate \
	&& pip3 install -e /code/zenroom/bindings/python3
CMD source venv/bin/activate && make check-py
