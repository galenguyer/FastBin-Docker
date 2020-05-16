#!/usr/bin/env bash
# build, tag, and push docker images

# exit if a command fails
set -o errexit

# exit if required variables aren't set
set -o nounset

# first and only argument should be nginx version to build
version="1.18.0"

# set current directory as base directory
basedir="$(pwd)"

# build fastbin-server and copy build artifacts to volume mount
docker run -it --rm -v "$basedir"/artifacts:/artifacts mcr.microsoft.com/dotnet/core/sdk:3.1-buster /bin/bash -c "`cat ./scripts/build-fastbin-server-docker.sh`"

# build nginx and copy build artifacts to volume mount
docker run -it --rm -e "NGINX=$version" -v "$basedir"/artifacts:/build alpine:latest /bin/ash -c "`cat ./scripts/build-nginx-docker.sh`"
