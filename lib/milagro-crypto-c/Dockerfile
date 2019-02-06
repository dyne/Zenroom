FROM ubuntu:latest

RUN dpkg --add-architecture i386 \
    && apt-get update && apt-get install -y --no-install-recommends \
    astyle \
    ca-certificates \
    cmake \
    doxygen \
    doxygen-latex \
    g++ \
    g++-multilib \
    gcc \
    git \
    lcov \
    make \
    mingw-w64 \
    parallel \
    python-pip \
    python-setuptools\
    wine-stable \
    wine64 \
    wine32 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && pip install \
    autopep8 \
    cffi \
    wheel

CMD ["/bin/bash"]
