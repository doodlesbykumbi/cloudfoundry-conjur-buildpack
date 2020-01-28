FROM golang:1.13.6-stretch
MAINTAINER CyberArk Software, Inc.

ENV GOOS=linux \
    GOARCH=amd64 \
    CGO_ENABLED=0

WORKDIR /conjur-env

COPY go.mod go.sum /conjur-env/

RUN go mod download
