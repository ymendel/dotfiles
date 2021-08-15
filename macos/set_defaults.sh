#!/usr/bin/env bash

if [ ! "$(uname -s)" == "Darwin" ]
then
    exit 0
fi

# cf. https://mths.be/macos

# Close any open System Preferences panes, to prevent them from overriding
# settings we’re about to change
# osascript -e 'tell application "System Preferences" to quit'
# Mathias does it with that osascript, but why not killall instead?
killall "System Preferences" &>/dev/null

find $(dirname $0) -name *.defaults | while read defaults; do source ${defaults} ; done
