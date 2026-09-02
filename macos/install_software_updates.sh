#!/usr/bin/env bash
#
# Install the software updates a sync can actually finish.
#
# `softwareupdate -i -a` is everything, and "everything" includes major OS
# upgrades. Those are a pain, partly because they need a restart and I don't
# want to do that more than necessary. So they didn't complete, and every run
# re-attempted those downloads, and then asked for auth again (this auths
# through Authorization Services instead of sudo). Really just annoying overall.
#
# There's no flag for "everything but" — there are things like `--os-only` and
# `--product-types`, but those are inclusion filters. Get the whole list and
# parse the labels out of that.
#
# What gets installed? Any update that declares no Action whatsoever.
# `Action: restart` means the machine needs to come down. No thanks.
# Something like Command Line Tools declare no action, so they can be installed.

set -e

dryRun=''

if [[ $1 == '--dry-run' ]]
then
    dryRun='yes'
fi

# softwareupdate reports on stderr and puts only its banner on stderr
# Sure, that's a way to do this. I guess.
available="$(softwareupdate --list 2>&1)"

# --list pairs a `* Label: <label>` line with an indented detail line carrying
# Title, Size, Recommended and Action (if there is one). Hold on to the label
# and decide the action (heh) when the detail line comes.
labels=()
candidate=''

while IFS= read -r line
do
    case "$line" in
        '* Label: '*)
            candidate="${line#'* Label: '}"
            ;;
        # keep this above Title, since every line has a Title
        *'Action: '*)
            candidate=''
            ;;
        *'Title: '*)
            if [[ -n $candidate ]]
            then
                labels+=("$candidate")
            fi

            candidate=''
            ;;
    esac
done <<< "$available"

if [[ ${#labels[@]} -eq 0 ]]
then
    echo "  nothing to install that doesn't want a restart"
    exit 0
fi

for label in "${labels[@]}"
do
    echo "  › $label"
done

if [[ -n $dryRun ]]
then
    exit 0
fi

# --no-scan reuses the scan just done
sudo softwareupdate --install --no-scan "${labels[@]}"
