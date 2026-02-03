ensure_dir () {
    local dir=$1

    if [[ -e $dir ]]
    then
        if [[ -d $dir ]]
        then
            success "$dir is a directory"
        else
            fail "$dir exists and is not a directory"
        fi
    else
        if ( mkdir -p $dir )
        then
            success "$dir created"
        else
            fail "could not create $dir"
        fi
    fi
}
