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

# shell/completion.bash switches off bash-completion's eager loading of
# Homebrew's etc/bash_completion.d and points the lazy loader here instead. The
# lazy loader wants a directory literally named `completions`, so one symlink
# stands in for a link per command — and new formulae then show up in it for
# free, with nothing to re-run.
#
# It can't be tracked in the repo, because its target is the Homebrew prefix, and
# that's machine-dependent (or at least arch-dependent).
link_homebrew_completions () {
    local overwrite_all=false backup_all=false skip_all=false
    local user_dir="$HOME/.local/share/homebrew-completions"

    info 'linking homebrew completions for lazy loading'

    mkdir -p "$user_dir"
    link_file "$(brew --prefix)/etc/bash_completion.d" "$user_dir/completions"
}

if test $(which brew)
then
    ensure_brew_bash
    link_homebrew_completions
else
    ensure_any_bash
fi
