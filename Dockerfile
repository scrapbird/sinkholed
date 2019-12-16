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

RUN mkdir -p /var/lib/sinkholed/samples
VOLUME /var/lib/sinkholed/samples

COPY --from=build /opt/sinkholed/bin/* /opt/sinkholed/

COPY ./config/sinkholed.yml /etc/sinkholed/sinkholed.yml
COPY ./entrypoint.sh /opt/sinkholed/entrypoint.sh

WORKDIR /opt/sinkholed

ENTRYPOINT /opt/sinkholed/entrypoint.sh /opt/sinkholed/sinkholed /var/log/sinkholed.log

