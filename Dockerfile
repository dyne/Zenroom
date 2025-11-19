# Copyright 2017-2025 Dyne.org foundation
# SPDX-FileCopyrightText: 2017-2025 Dyne.org foundation
#
# SPDX-License-Identifier: AGPL-3.0-or-later

FROM alpine:latest

COPY lib /lib
COPY src /src
COPY build /build
COPY .git /.git
COPY Makefile Makefile

RUN apk add --no-cache linux-headers gcc g++ make xxd cmake readline-dev bash wget git
# install musl-dyne
RUN mkdir -p /opt/musl-dyne
RUN wget -O musl-dyne.tar.xz "https://files.dyne.org/musl/dyne-gcc-musl-x86_64.tar.xz"
RUN tar -xJf musl-dyne.tar.xz -C /opt/musl-dyne/ --strip-components=1
RUN rm musl-dyne.tar.xz
# build with musl-dyne
ENV COMPILER=/opt/musl-dyne/gcc-musl/bin/x86_64-linux-musl-gcc
ENV COMPILER_CXX=/opt/musl-dyne/gcc-musl/bin/x86_64-linux-musl-g++
ENV RELEASE=1
RUN make musl
# install zenroom binaries
RUN mkdir -p /usr/local/bin/
RUN cp zenroom /usr/local/bin/
RUN cp zencode-exec /usr/local/bin/

ENTRYPOINT ["/usr/local/bin/zenroom"]
