#!/bin/zsh

set -e
cd "$(dirname "$0")"

rm -rf Build
mkdir Build

cd Build

if test -n "$MORAEA_LOCAL_DEPENDENCIES"
then
	cp -R ../../moraea-common ../../moraea-sources .
else
	git clone https://github.com/moraea/moraea-common
	git clone https://github.com/moraea/moraea-sources
fi

chflags hidden moraea-common moraea-sources

moraea-common/Build.tool
