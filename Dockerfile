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

RUN apk add --no-cache linux-headers gcc g++ make xxd cmake readline-dev bash
RUN mkdir -p /opt/musl-dyne && wget -O musl-dyne.tar.xz "https://files.dyne.org/?file=musl/musl-dyne.tar.xz" && tar -xJf musl-dyne.tar.xz -C /opt/musl-dyne/ --strip-components=1 && rm musl-dyne.tar.xz
RUN make -f build/musl.mk RELEASE=1 COMPILER=gcc COMPILER_CXX=g++
RUN mkdir -p /usr/local/bin/
RUN cp zenroom /usr/local/bin/
RUN cp zencode-exec /usr/local/bin/

ENTRYPOINT ["/usr/local/bin/zenroom"]
