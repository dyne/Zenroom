FROM elixir:1.10.4-alpine

ENV HOME=/module TERM=xterm

WORKDIR $HOME

RUN apk add --no-cache make gcc musl-dev libc-dev erlang-dev bash

COPY . /module

# RUN make

CMD bash

# ENTRYPOINT ["iex", "-S", "mix", "phx.server"]

