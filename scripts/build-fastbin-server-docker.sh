#!/usr/bin/env ash
# a script to build fastbin-index on the debian dotnet image

# exit on error
set -e

# display last non-zero exit code in a failed pipeline
set -o pipefail

# set core count for make
core_count="$(grep -c ^processor /proc/cpuinfo)"

# choose where to put the build files
BUILDROOT="$(mktemp -d)"

# remove the build directory on exit
function cleanup {
        rm -rf "$BUILDROOT"
}
trap cleanup EXIT

git clone https://github.com/galenguyer/fastbin-server $BUILDROOT
cd "$BUILDROOT"/FastBin-Server
dotnet restore
dotnet publish -r linux-x64

rm -rf /artifacts/server
mv ./bin/Debug/netcoreapp3.1/linux-x64/publish /artifacts/server
