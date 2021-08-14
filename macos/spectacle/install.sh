#!/usr/bin/env bash

killall "Spectacle" 2>/dev/null

source "${DOTFILES_HOME}/script/helpers/printing.sh"
source "${DOTFILES_HOME}/script/helpers/linking.sh"

# FIXME: read-within-read makes it so the prompt for choice doesn't actually take user input
# so once that works, this should go back to backup_all=false
overwrite_all=false backup_all=true skip_all=false

# TODO: get the full path of the present dir, without specifying all of this
link_file "$DOTFILES_HOME/macos/spectacle/Shortcuts.json" "$HOME/Library/Application Support/Spectacle/Shortcuts.json"

# TODO: re-run?
# open /Applications/Spectacle.app
