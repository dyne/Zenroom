FROM alpine:latest

ADD . /

RUN apk add --no-cache zsh linux-headers build-base cmake
RUN make linux
RUN cp /src/zenroom /usr/local/bin/zenroom

ENTRYPOINT ["zenroom"]

