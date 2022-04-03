#!/bin/zsh

set -e
cd "$(dirname "$0")"

rm -rf Build
mkdir Build

cd Build

git clone https://github.com/moraea/non-metal-common
non-metal-common/Build.tool

git clone https://github.com/moraea/non-metal-binaries