#!/usr/bin/env bash
#
# Rosetta 2, for the Intel-only apps in the Brewfile — Mailplane and CirclePing.
#
# There's no file to check for. /usr/libexec/rosetta ships populated (oahd,
# runtime, translate_tool, &c.) whether or not Rosetta is installed, and the
# listing is identical either way. pkgutil doesn't know about it either. So the
# check is behavioral: can an x86_64 binary actually run? /usr/bin/true is
# universal, so `arch -x86_64` on it exits 1 with "Bad CPU type in executable"
# when the translation isn't there. Nothing pops up a dialog, which is what
# makes that safe to use as a check.
#
# Make sure to _run_ this instead of _sourcing_ it, so the early exit when
# Rosetta is already installed doesn't stop the caller too.

set -e

if [ ! "$(uname -s)" == "Darwin" ] || [ ! "$(uname -m)" == "arm64" ]
then
    exit 0
fi

echo "› checking rosetta"

if arch -x86_64 /usr/bin/true 2>/dev/null
then
    echo "  rosetta is already installed"
    exit 0
fi

if ! sudo softwareupdate --install-rosetta --agree-to-license
then
    echo "  couldn't install rosetta" >&2
    exit 1
fi

# actually check, instead of trusting the installer's exit status
if arch -x86_64 /usr/bin/true 2>/dev/null
then
    echo "  installed rosetta"
else
    echo "  softwareupdate finished but x86_64 binaries still won't run" >&2
    exit 1
fi
