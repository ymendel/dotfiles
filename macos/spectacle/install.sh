#!/usr/bin/env bash

killall "Spectacle" &>/dev/null

source "$DOTFILES_HOME/script/helpers/printing.sh"
source "$DOTFILES_HOME/script/helpers/linking.sh"

overwrite_all=false backup_all=false skip_all=false

# TODO: get the full path of the present dir, without specifying all of this
link_file "$DOTFILES_HOME/macos/spectacle/Shortcuts.json" "$HOME/Library/Application Support/Spectacle/Shortcuts.json"

# TODO: re-run?
# open /Applications/Spectacle.app
