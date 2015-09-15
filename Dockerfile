FROM google/golang

WORKDIR /gopath/src/github.com/impossibleventures/ec2metaproxy
ADD . /gopath/src/github.com/impossibleventures/ec2metaproxy
RUN go get github.com/impossibleventures/ec2metaproxy/cmd/ec2metaproxy

CMD []
ENTRYPOINT ["/gopath/bin/ec2metaproxy"]