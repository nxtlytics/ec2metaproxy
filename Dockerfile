FROM golang:alpine

RUN apk add --update git

WORKDIR /go/src/github.com/nxtlytics/ec2metaproxy
ADD . /go/src/github.com/nxtlytics/ec2metaproxy
RUN go get github.com/nxtlytics/ec2metaproxy/cmd/ec2metaproxy

CMD []
ENTRYPOINT ["/go/bin/ec2metaproxy"]
