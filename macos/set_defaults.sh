#!/usr/bin/env bash

if [ ! "$(uname -s)" == "Darwin" ]
then
    exit 0
fi

# cf. https://mths.be/macos

# Close System Settings if it's open, to prevent it from overriding
# settings we’re about to change
# osascript -e 'tell application "System Settings" to quit'
# Mathias does it with that osascript, but why not killall instead?
killall "System Settings" &>/dev/null

find "$(dirname "$0")" -name '*.defaults' | while read -r defaults; do source "$defaults" ; done
