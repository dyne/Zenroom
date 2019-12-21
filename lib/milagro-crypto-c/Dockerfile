FROM ubuntu:bionic

RUN dpkg --add-architecture i386

# add repositories cache
RUN apt-get update -y

# install packages
RUN apt-get install -y \
    build-essential \
    cmake \
    doxygen \
    parallel \
    mingw-w64 \
    wine64 \
    wine32 \
    lcov \
    python3-dev \
    python3-pip \
    gcc-multilib

RUN pip3 install cffi autopep8

CMD ["/bin/bash"]
