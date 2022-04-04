#!/bin/zsh

set -e
cd "$(dirname "$0")"

rm -rf Build
mkdir Build

cd Build

if test -n "$MORAEA_LOCAL_DEPENDENCIES"
then
	cp -R ../../non-metal-common .
	cp -R ../../non-metal-binaries .
else
	git clone https://github.com/moraea/non-metal-common
	git clone https://github.com/moraea/non-metal-binaries
fi

non-metal-common/Build.tool