#!/usr/bin/env bash

if [ ! "$(uname -s)" == "Darwin" ]
then
    exit 0
fi

# The Brewfile handles Homebrew-based app and library installs, but there may
# still be updates and installables in the Mac App Store. There's a nifty
# command line interface to it that we can use to just install everything, so
# yeah, let's do that.

echo "› sudo softwareupdate -i -a"
sudo softwareupdate -i -a

defaultsFile="$(dirname $0)/set_defaults.sh"
echo "› setting defaults"
test -f $defaultsFile && source $defaultsFile
