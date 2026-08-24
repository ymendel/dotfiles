#!/usr/bin/env bash
#
# Touch ID for sudo, in the file that survives system updates.
#
# `pam_tid.so` used to go in /etc/pam.d/sudo, and macOS rewrites that on
# system updates. That meant it kept disappearing, and I lost the fight
# of trying to keep the line in there. Thankfully, Sonoma added a sudo_local
# file, included from the sudo file and left alone by updates. And they even
# shipped a template for it with Touch ID in there (but commented out).
#
# Hey, keep up stuff like this and maybe I'll even finally install Tahoe. Or
# whatever comes after that.
#
# Make sure to _run_ this instead of _sourcing_ it. Unless, of course, you want
# to stop the caller on any of the early exits, like the one where the file is
# already present and good.

set -e

if [ ! "$(uname -s)" == "Darwin" ]
then
    exit 0
fi

SUDO_LOCAL=/etc/pam.d/sudo_local
TEMPLATE=/etc/pam.d/sudo_local.template
TID_LINE='auth       sufficient     pam_tid.so'
TID_ENABLED='^auth[[:space:]]+sufficient[[:space:]]+pam_tid\.so'

echo "› checking touch-id for sudo"

if grep -qE "$TID_ENABLED" "$SUDO_LOCAL" 2>/dev/null
then
    echo "  touch-id for sudo is already enabled"
    exit 0
fi

if [ ! -f "$SUDO_LOCAL" ]
then
    if [ ! -f "$TEMPLATE" ]
    then
        echo "  no $SUDO_LOCAL and no template to make one from — this macOS predates it" >&2
        exit 0
    fi

    echo "  no $SUDO_LOCAL yet, starting from Apple's template"

    if ! sudo cp "$TEMPLATE" "$SUDO_LOCAL"
    then
        echo "  couldn't create $SUDO_LOCAL" >&2
        exit 1
    fi
fi

tid_file="$(mktemp)"

sed 's/^#[[:space:]]*\(auth[[:space:]]\{1,\}sufficient[[:space:]]\{1,\}pam_tid\.so\)/\1/' \
    "$SUDO_LOCAL" > "$tid_file"

# Did someone edit the file so there's no pam_tid line at all? That's odd.
# Well, add it back.
if ! grep -qE "$TID_ENABLED" "$tid_file"
then
    printf '%s\n' "$TID_LINE" >> "$tid_file"
fi

# `cp` here, instead of `mv`, so this file keeps the ownership/mode it
# had before, instead of taking what the tmpfile has. See shell/install.sh
# for the chown/chmod shenanigans that would have to happen otherwise.
#
# Thankfully, root will write this despite the 444.
if ! sudo cp "$tid_file" "$SUDO_LOCAL"
then
    echo "  couldn't write $SUDO_LOCAL" >&2
    rm -f "$tid_file"
    exit 1
fi

rm -f "$tid_file"

# actually check the file contents, instead of just trusting the write
if grep -qE "$TID_ENABLED" "$SUDO_LOCAL"
then
    echo "  enabled touch-id for sudo"
else
    echo "  wrote $SUDO_LOCAL but the pam_tid line isn't in it" >&2
    exit 1
fi
