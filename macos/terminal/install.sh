#!/usr/bin/env bash

if [ ! "$(uname -s)" == "Darwin" ]
then
    exit 0
fi

cd "$(dirname $0)"

settings=()
for f in *.terminal; do settings+=("${f%.terminal}"); done

for ((i = 0; i < ${#settings[@]}; i++))
do
    setting=${settings[$i]}
    if [[ "$setting" =~ " " ]]
    then
        settingCheck="\"$setting\""
    else
        settingCheck=$setting
    fi

    if (! (defaults read com.apple.Terminal "Window Settings" | grep -q "name = $settingCheck"))
    then
        # TODO: figure out how to import these without opening a window
        # or at least auto-close the window afterwards
        open "$setting.terminal"
    fi
done
