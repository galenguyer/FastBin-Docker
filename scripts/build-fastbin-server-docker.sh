#!/usr/bin/env ash
# a script to build fastbin-index on the debian dotnet image

# choose where to put the build files
BUILDROOT="$(mktemp -d)"

# remove the build directory on exit
function cleanup {
        rm -rf "$BUILDROOT"
}
trap cleanup EXIT

apk add git

git clone https://github.com/galenguyer/fastbin-server $BUILDROOT
cd "$BUILDROOT"/FastBin-Server
dotnet restore
dotnet publish -r linux-musl-x64

rm -rf /artifacts/server
mv ./bin/Debug/netcoreapp3.1/linux-musl-x64/publish /artifacts/server
