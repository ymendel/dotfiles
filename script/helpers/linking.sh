# Link (symlink, not hard link) one path to another, with some optionality
# (overwrite, backup, skip), and some cleverness (if the link is already
# correct, skip and move on).
#
# NOTE: this _requires_ a few variables in scope: `overwrite_all`, `backup_all`, `skip_all`
link_file () {
    local src=$1 dst=$2

    local overwrite= backup= skip=
    local action=

    if [ -e "$dst" ]
    then
        if [ "$skip_all" == "false" ]
        then
            if ( does_link_match "$src" "$dst" )
            then
                skip=true;
            fi
        fi

        if [ "$overwrite_all" == "false" ] && [ "$backup_all" == "false" ] && [ "$skip_all" == "false" ] && [ "$skip" != "true" ]
        then
            prompt "File already exists: $dst ($(basename "$src")), what do you want to do?\n\
            [s]kip, [S]kip all, [o]verwrite, [O]verwrite all, [b]ackup, [B]ackup all?"
            read -n 1 action

            case "$action" in
                o )
                    overwrite=true;;
                O )
                    overwrite_all=true;;
                b )
                    backup=true;;
                B )
                    backup_all=true;;
                s )
                    skip=true;;
                S )
                    skip_all=true;;
                * )
                    ;;
            esac
        fi

        overwrite=${overwrite:-$overwrite_all}
        backup=${backup:-$backup_all}
        skip=${skip:-$skip_all}

        if [ "$overwrite" == "true" ]
        then
            rm -rf "$dst"
            success "removed $dst"
        fi

        if [ "$backup" == "true" ] && [ "$skip" != "true" ]
        then
            mv "$dst" "${dst}.backup"
            success "moved $dst to ${dst}.backup"
        fi

        if [ "$skip" == "true" ]
        then
            success "skipped $src"
        fi
    fi

    if [ "$skip" != "true" ]  # "false" or empty
    then
        if ( ln -s "$src" "$dst" )
        then
            success "linked $dst to $src"
        else
            fail "couldn't link $dst to $src"
        fi
    fi
}

does_link_match () {
    local src=$1 dst=$2
    local currentSrc="$(readlink "$dst")"

    if [ "$currentSrc" == "$src" ]
    then
        true
    else
        false
    fi
}

# Look for <subdir> under every topic, and then link all the files in there
# to <root>/ with the same path. e.g. editing/config/zed/settings.json goes to
# $root/zed/settings.json
#
# The _files_ are linked, rather than the _directory_, because something else
# might be using the directory for its own reasons.
#
# Uses `link_file` internally, so all of its behavior applies — notably, it
# needs `overwrite_all`, `backup_all`, and `skip_all` in scope.
link_tree () {
    local subdir=$1 root=$2
    local dir src rel dst

    for dir in "$DOTFILES_ROOT"/*/"$subdir"
    do
        # check if the dir is actually a directory, because an unmatched glob
        # stays literal
        [[ -d $dir ]] || continue

        # process substitution lets this run in the current shell
        while IFS= read -r src
        do
            rel="${src#"$dir"/}"
            dst="$root/$rel"

            ensure_dir "$(dirname "$dst")"
            link_file "$src" "$dst"
        done < <(find "$dir" -type f)
    done
}

# Do all the linking!
#   - all *.symlink files into $HOME with a dot prepended
#     (eg. git/gitconfig.symlink → ~/.gitconfig)
#   - every topic's config/ tree into CONFIG_HOME
#
# This gets done on first clone/bootstrap, but also on every `updot` (via
# script/install, via system/install.sh), so newly-added config files get
# linked on the next run.
#
# NOTE: needs the same variables `link_file` does (`overwrite_all`, `backup_all`, `skip_all`),
# plus `DOTFILES_ROOT` and `CONFIG_HOME`.
# Those *_all flags stay the caller's to declare, by design. One answer there
# should cover all the linking in the run, even whatever that caller adds to
# the mix.
link_dotfiles () {
    local src dst

    for src in $(find $DOTFILES_ROOT -name '*.symlink' -type f)
    do
        dst="$HOME/.$(basename ${src%.symlink})"
        link_file $src $dst
    done

    link_tree config "$CONFIG_HOME"
}
