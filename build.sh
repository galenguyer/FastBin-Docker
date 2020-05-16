#!/usr/bin/env bash
# build, tag, and push docker images

# exit if a command fails
set -o errexit

# exit if required variables aren't set
set -o nounset

#set environment variables
nginx_version="1.18.0"
build_version="1.1"
core_count="$(grep -c ^processor /proc/cpuinfo)"

# create docker run image
docker build \
	--build-arg NGINX_VER="$nginx_version" \
	--build-arg CORE_COUNT="$core_count" \
	-f Dockerfile .
