FROM alpine:3.6

WORKDIR /code/zenroom

RUN apk update
RUN apk upgrade
RUN apk add --no-cache git openssh git
RUN git clone --recursive https://github.com/DECODEproject/zenroom.git .
RUN apk add --no-cache vim cmake build-base zsh linux-headers
RUN make musl-system

ENTRYPOINT ["/code/zenroom/src/zenroom-static"]
