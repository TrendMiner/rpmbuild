# Using CentOS 7 as base image to support rpmbuild (packages will be Dist el7)
FROM docker.io/library/node:14.16.1-alpine3.13 AS builder

WORKDIR /build
COPY ./src/ ./src
COPY package.json package-lock.json tsconfig.json ./

RUN set -xe \
    && npm install \
    && npm run build

FROM docker.io/library/centos:7

# Copying all contents of rpmbuild repo inside container
WORKDIR /app

# Installing tools needed for rpmbuild , 
# depends on BuildRequires field in specfile, (TODO: take as input & install)
RUN set -xe \
    && yum install -y rpm-build rpmdevtools gcc make coreutils python

# Setting up node to run our JS file
# Download Node Linux binary
ARG NODEJS_VERSION=v14.16.1
RUN set -xe \
    && curl -o node.tar.gz https://nodejs.org/dist/${NODEJS_VERSION}/node-${NODEJS_VERSION}-linux-x64.tar.xz \
    && test $(sha256sum node.tar.gz | awk '{print $1}') = '85a89d2f68855282c87851c882d4c4bbea4cd7f888f603722f0240a6e53d89df' \
    && tar --strip-components 1 -xvf node.tar.gz -C /usr/local \
    && rm node.tar.gz

# Install all dependecies to execute main.js
COPY package.json package-lock.json ./
RUN set -xe \
    && npm install --production

COPY --from=builder /build/lib/ ./lib

# All remaining logic goes inside main.js , 
# where we have access to both tools of this container and 
# contents of git repo at /github/workspace
ENTRYPOINT ["node", "/app/lib/main.js"]
