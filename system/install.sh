#!/usr/bin/env bash

set -e

cd "$(dirname "$0")/.."
# need to get the canonical path, not just ~/.dotfiles
DOTFILES_ROOT=$(pwd -P)

source "$DOTFILES_HOME/script/helpers/printing.sh"
source "$DOTFILES_HOME/script/helpers/linking.sh"
source "$DOTFILES_HOME/script/helpers/filestuff.sh"

info 'linking dotfiles'

# link_dotfiles needs these to exist
# one answer for every question to the end of the linking
overwrite_all=false backup_all=false skip_all=false

link_dotfiles
