FROM golang:1.14.3-alpine3.11 as builder

# Prevent linking against libc
ENV CGO_ENABLED 0

RUN apk add --update git

WORKDIR /go/src/github.com/nxtlytics/ec2metaproxy
ADD . /go/src/github.com/nxtlytics/ec2metaproxy
RUN go get github.com/nxtlytics/ec2metaproxy/cmd/ec2metaproxy

FROM alpine:3.11.6

COPY --from=builder /go/bin/ec2metaproxy /go/bin/ec2metaproxy

CMD []
ENTRYPOINT ["/go/bin/ec2metaproxy"]
