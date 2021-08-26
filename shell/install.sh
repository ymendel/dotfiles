#!/usr/bin/env bash

set -e

source "$DOTFILES_HOME/script/helpers/printing.sh"
source "$DOTFILES_HOME/script/helpers/linking.sh"

info 'checking shell'

ensure_specific_bash () {
    local the_bash="$1"

    if [[ $SHELL == "$the_bash" ]]
    then
        success "shell is desired bash — $the_bash"
        return
    fi

    if (! grep -qe "^$the_bash$" /etc/shells)
    then
        info "need to add $the_bash to /etc/shells"

        if (awk -v "bash=$the_bash" '/\/bash$/ && !x {print bash; x++} {print}' /etc/shells > /tmp/shells && sudo mv /tmp/shells /etc/shells && sudo chown root /etc/shells && sudo chmod 644 /etc/shells)
        then
            success "added $the_bash"
        else
            fail "couldn't add $the_bash"
        fi
    fi

    info "shell is '$SHELL'; switching to '$the_bash'"
    if (chsh -s $the_bash)
    then
        success "changed shell to '$the_bash'"
        info "open a new terminal for best results"
        return
    else
        fail "problem trying to change shell to '$the_bash'"
    fi
}

ensure_any_bash () {
    info 'checking shell'

    if [[ "$SHELL" =~ /bash$ ]]
    then
        success "shell is already a bash"
        return
    fi

    info "shell is '$SHELL'; switching to bash"

    # I don't want to figure out preference order here
    # so put multiple bashes in preference order in /etc/shells
    local bashes=$(grep -e /bash$ /etc/shells)

    for bash in ${bashes[@]}
    do
        if [ -x $bash ]
        then
            info "trying '$bash'"
            if (chsh -s $bash)
            then
                success "changed shell to '$bash'"
                info "open a new terminal for best results"
                return
            else
                warn "problem trying to change shell to '$bash'"
            fi
        fi
    done

    fail "could not change shell"
}

ensure_brew_bash () {
    ensure_specific_bash "$(brew --prefix)/bin/bash"
}

if test $(which brew)
then
    ensure_brew_bash
else
    ensure_any_bash
fi
