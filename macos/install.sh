#!/usr/bin/env bash

if [ ! "$(uname -s)" == "Darwin" ]
then
    exit 0
fi

# The Brewfile handles Homebrew-based app and library installs, but there may
# still be updates and installables in the Mac App Store. Now, installing
# everything seemed like a good idea, but as it so happens, that includes
# major OS upgrades. Trying to be choosier now.
#
# run rather than sourced, for the same early-exit reason as touchid, below
updatesFile="$(dirname $0)/install_software_updates.sh"
echo "› software updates"
[[ -x $updatesFile ]] && "$updatesFile"

# run rather than sourced, since this exits early on "already enabled"
# and that would just end this script, too
touchidFile="$(dirname $0)/ensure_touchid_sudo.sh"
[[ -x $touchidFile ]] && "$touchidFile"

defaultsFile="$(dirname $0)/set_defaults.sh"
echo "› setting defaults"
[[ -f $defaultsFile ]] && source $defaultsFile

echo ''
echo "MacOS defaults written. Note that some of these changes require a logout/restart to take effect."
echo ''
