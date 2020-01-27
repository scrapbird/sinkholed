FROM golang:1.11.6-alpine as build

ENV GOPATH=""

RUN apk add --update --no-cache git build-base bash

RUN mkdir /opt/sinkholed

WORKDIR /opt/sinkholed

COPY ./cmd cmd
COPY ./config config
COPY ./internal internal
COPY ./pkg pkg
COPY ./plugins plugins
COPY ./build.sh build.sh
COPY ./go.mod go.mod
COPY ./go.sum go.sum

RUN ./build.sh

FROM alpine

RUN apk add --update --no-cache libcap

# Add sinkholed user and group
RUN addgroup -S sinkholed \
    && adduser -S sinkholed -G sinkholed

RUN mkdir -p /var/lib/sinkholed/samples
VOLUME /var/lib/sinkholed/samples

VOLUME /etc/sinkholed/certs

RUN mkdir -p /usr/local/lib/sinkholed
COPY --from=build /opt/sinkholed/bin/*.so /usr/local/lib/sinkholed/

COPY --from=build /opt/sinkholed/bin/sinkholed /usr/local/bin/sinkholed

COPY ./config/sinkholed.yml /etc/sinkholed/sinkholed.yml
COPY ./entrypoint.sh /usr/local/bin/entrypoint.sh

RUN setcap CAP_NET_BIND_SERVICE=+eip /usr/local/bin/sinkholed

# Create log dir and set permissions
RUN mkdir /var/log/sinkholed \
    && chown sinkholed:sinkholed /var/log/sinkholed

USER sinkholed

ENTRYPOINT /usr/local/bin/entrypoint.sh /usr/local/bin/sinkholed /var/log/sinkholed/sinkholed.log

