#!/usr/bin/env bash

set -e

source "$DOTFILES_HOME/script/helpers/printing.sh"

# I have a ~/.ruby-version to set my "default" ruby. If that ruby isn't installed,
# chruby will complain and exit 1 at _every shell start_. That's not great.
# So install it.
version_file="$HOME/.ruby-version"

if [[ ! -f $version_file ]]
then
    warn "no $version_file, no default ruby to build"
    exit
fi

# ruby-add hardcodes the engine, so get the plain version number (no prefix)
version="$(head -1 "$version_file")"
version="${version#ruby-}"

info "checking the default ruby — $version"

# If this is truly the bootstrap, PATH will be pretty anemic, so be clear
# about exactly where ruby-add is.
#
# Also, this is nice and idempotent, so no need to check anything.
# - ruby-add passes `--no-reinstall`
# - ruby-install just exits cleanly if the ruby is already installed
"$DOTFILES_HOME/ruby/bin/ruby-add" "$version"
