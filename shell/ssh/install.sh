#!/usr/bin/env bash

set -e

source "$DOTFILES_HOME/script/helpers/printing.sh"
source "$DOTFILES_HOME/script/helpers/linking.sh"

dirs=("$HOME/.ssh" "$HOME/.ssh/ctrl")
for dir in ${dirs[@]}
do
    info "checking $dir directory"
    if [[ -d $dir ]]
    then
        success "$dir is a directory"
    else
        if (mkdir $dir)
        then
            success "$dir created"
        else
            fail "could not create $dir"
        fi
    fi
done

overwrite_all=false backup_all=false skip_all=false

# TODO: get the full path of the present dir, without specifying all of this
link_file "$DOTFILES_HOME/shell/ssh/config" "$HOME/.ssh/config"
