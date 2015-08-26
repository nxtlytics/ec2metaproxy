# Credits
First off. This is a repackaging of this repo: [dump247/docker-ec2-metadata](https://github.com/dump247/docker-ec2-metadata)
I didn't write this code. It works great though. Hopefully this will enable you to adopt
it even quicker.

# What is this?
A service that runs on an EC2 instance that proxies the EC2 instance metadata service
for docker containers. The proxy overrides metadata endpoints for individual docker
containers.

At this point, the only endpoint overridden is the security credentials. This allows
for different containers to have different IAM permissions and not just use the permissions
provided by the instance profile. However, this same technique could be used to override
any other endpoints where appropriate.

# Build

Requires:

* golang 1.2+

The dependencies are managed with Godep.

## Go

Clone this repo into your Golang workspace, move into the repo, and then maybe run things like this:

```bash
go test ./...
go install ./...
```

## Docker

Clone this repo and do something like this:

```bash
docker build -t ec2metaproxy .
```

# Setup

What is needed is an EC2 instance with assume role permissions and one or more roles defined
that it can assume. The roles will be used by the containers to acquire their own permissions.

## Permissions

The EC2 instance must have permission to assume the roles required by the docker containers.

Note that assuming a role is two way: the permission to assume roles has to be granted to the
instance profile and the role has to allow the instance profile to assume it.

There must be at least one role to use as the default role if the container has not specified
one. The default role can have empty permissions (zero access) or some set of standard
permissions.

Example CloudFormation:

* _DockerContainerRole1_ is the set of permissions for a docker container
* _InstanceRole_ is the role used by the EC2 instance profile and needs permission to assume _DockerContainerRole1_

```json
{
  "AWSTemplateFormatVersion": "2010-09-09",
  "Resources": {
    "DockerContainerRole1": {
      "Type": "AWS::IAM::Role",
      "Properties": {
        "AssumeRolePolicyDocument": {
          "Statement": [
            {
              "Effect": "Allow",
              "Principal": {
                "AWS": [ {"Fn::GetAtt" : ["InstanceRole", "Arn"]} ]
              },
              "Action": [ "sts:AssumeRole" ]
            }
          ]
        },
        "Path": "/docker/",
        "Policies": []
      }
    },

    "InstanceRole": {
      "Type": "AWS::IAM::Role",
      "Properties": {
        "AssumeRolePolicyDocument": {
          "Statement": [
           {
             "Effect": "Allow",
             "Principal": {
                "Service": [ "ec2.amazonaws.com" ]
              },
              "Action": [ "sts:AssumeRole" ]
            }
          ]
        },
        "Path": "/",
        "Policies": [
          {
            "PolicyName": "AssumeRoles",
            "PolicyDocument": {
              "Statement": [
                {
                  "Effect": "Allow",
                  "Resource": {"Fn::Join": ["", ["arn:aws:iam::", {"Ref": "AWS::AccountId"}, ":role/docker/*"]]},
                  "Action": [ "sts:AssumeRole" ]
                }
              ]
            }
          }
        ]
      }
    },

    "InstanceProfile": {
      "Type": "AWS::IAM::InstanceProfile",
      "Properties": {
        "Path": "/",
        "Roles": [{"Ref": "InstanceRole"}]
      }
    }
  }
}
```

## Instance Setup

Install docker and run with the standard unix domain socket (_/var/run/docker.sock_).

Run this command to setup iptables to reroute metadata service calls from docker0 to
our little docker instance:

`Note: NIC_NAME should be the name of the nic that is in use on the machine.`

```bash
curl -sSL https://raw.githubusercontent.com/flyinprogrammer/ec2metaproxy/master/firewall_setup.sh | NIC_NAME=eth0 bash
```

## Run the Service

Run this to pull and start the container:

```bash
curl -sSL https://raw.githubusercontent.com/flyinprogrammer/ec2metaproxy/master/start_ec2metaproxy.sh | bash
```

# Container Role

If the container does not specify a role, the default role is used. A container can specify
a specific role to use by setting the `IAM_ROLE` environment variable.

Example: `IAM_ROLE=arn:aws:iam::123456789012:role/CONTAINER_ROLE_NAME`

Note that the host machine’s instance profile must have permission to assume the given role.
If not, the container will receive an error when requesting the credentials.

# Docker Test

```bash
docker-machine create \
    --driver amazonec2 \
    --amazonec2-region "us-west-2" \
    --amazonec2-access-key <key> \
    --amazonec2-secret-key <secret> \
    --amazonec2-vpc-id <vpc id> \
    --amazonec2-instance-type "t2.medium" \
    --amazonec2-iam-instance-profile <InstanceProfile> \
    docker-ec2
eval $(docker-machine env docker-ec2)

docker-machine ssh docker-ec2
sudo su -
curl -sSL https://raw.githubusercontent.com/flyinprogrammer/ec2metaproxy/master/firewall_setup.sh | NIC_NAME=eth0 bash
curl -sSL https://raw.githubusercontent.com/flyinprogrammer/ec2metaproxy/master/start_ec2metaproxy.sh | bash -s -- --verbose
exit
exit

docker run -it -e IAM_ROLE=arn:aws:iam::<account number>:role/docker/<DockerContainerRole1> ubuntu:14.04 /bin/bash
--> apt-get install curl
--> curl http://169.254.169.254/latest/meta-data/iam/security-credentials/ && echo
```

# License

The MIT License (MIT)
Copyright (c) 2014 Cory Thomas

See [LICENSE](LICENSE)
