FROM alpine:3.6


WORKDIR /code/zenroom

RUN apk update
RUN apk upgrade
RUN apk add --no-cache git openssh git
RUN git clone --recursive https://github.com/DECODEproject/zenroom.git .
RUN apk add --no-cache vim cmake build-base zsh linux-headers
RUN make musl-system
RUN ln -s /code/zenroom/src/zenroom-static /usr/bin/zenroom

ENTRYPOINT ["zenroom"]

# Metadata params
ARG BUILD_DATE
ARG VERSION
ARG VCS_URL
ARG VCS_REF

# Metadata
LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.name="Zenroom VM" \
      org.label-schema.description="Base docker for Zenroom operations in native x86 64bit" \
      org.label-schema.url="https://zenroom.dyne.org" \
      org.label-schema.vcs-url=$VCS_URL \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vendor="Dyne.org" \
      org.label-schema.version=$VERSION \
      org.label-schema.schema-version="1.0" \
      org.dyne.zenroom.docker.dockerfile="/Dockerfile" \
      org.dyne.zenroom.license="GPL-3.0-only" \
      maintainer="Puria Nafisi Azizi <puria@dyne.org>" \
      homepage=$VCS_URL
