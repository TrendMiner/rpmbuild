# Using CentOS 7 as base image to support rpmbuild (packages will be Dist el7)
FROM centos:7

# Copying all contents of rpmbuild repo inside container
WORKDIR /build
COPY . /build

# Installing tools needed for rpmbuild , 
# depends on BuildRequires field in specfile, (TODO: take as input & install)
RUN set -xe \
    && yum install -y rpm-build rpmdevtools gcc make coreutils python

# Setting up node to run our JS file
# Download Node Linux binary
ARG NODEJS_VERSION=v12.22.1
RUN set -xe \
    && curl -o node.tar.gz https://nodejs.org/dist/${NODEJS_VERSION}/node-${NODEJS_VERSION}-linux-x64.tar.xz \
    && test $(sha256sum node.tar.gz | awk '{print $1}') = '8b537282c222ae4a40e019a52f769ca27b6640699bdde1510375e8d72da7d041' \
    && tar --strip-components 1 -xvf node.tar.gz -C /usr/local \
    && rm node.tar.gz

# Install all dependecies to execute main.js
RUN set -xe \
    && npm install --production

# All remaining logic goes inside main.js , 
# where we have access to both tools of this container and 
# contents of git repo at /github/workspace
ENTRYPOINT ["node", "/lib/main.js"]
