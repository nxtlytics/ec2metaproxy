FROM golang:latest

WORKDIR /go/src/github.com/impossibleventures/ec2metaproxy
ADD . /go/src/github.com/impossibleventures/ec2metaproxy
RUN go get github.com/impossibleventures/ec2metaproxy/cmd/ec2metaproxy

CMD []
ENTRYPOINT ["/go/bin/ec2metaproxy"]
