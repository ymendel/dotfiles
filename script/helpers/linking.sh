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
