# Copyright 2017-2018 Dyne.org foundation
# SPDX-FileCopyrightText: 2017-2022 Dyne.org foundation
#
# SPDX-License-Identifier: AGPL-3.0-or-later

FROM alpine:latest

ADD . /

RUN apk add --no-cache zsh linux-headers build-base cmake
RUN make linux
RUN cp /src/zenroom /usr/local/bin/zenroom

ENTRYPOINT ["zenroom"]

