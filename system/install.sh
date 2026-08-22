#!/usr/bin/env bash

set -e

cd "$(dirname "$0")/.."
# need to get the canonical path, not just ~/.dotfiles
DOTFILES_ROOT=$(pwd -P)

source "$DOTFILES_HOME/script/helpers/printing.sh"
source "$DOTFILES_HOME/script/helpers/linking.sh"
source "$DOTFILES_HOME/script/helpers/filestuff.sh"

link_dotfiles () {
    info 'linking dotfiles'

    local overwrite_all=false backup_all=false skip_all=false

    for src in $(find $DOTFILES_ROOT -name '*.symlink' -type f)
    do
        dst="$HOME/.$(basename ${src%.symlink})"
        link_file $src $dst
    done

    # link the config file trees as well as the simple symlink files
    # keep this here to follow along with overwrite/backup/skip all
    link_tree config "$CONFIG_HOME"
}

link_dotfiles
