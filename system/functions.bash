grok()
{
    grep -ri "$*" . | grep -v '\.svn' | grep -v '\.git'
}

files_with()
{
    grok $* | cut -d : -f 1 | sort | uniq
}

ip()
{
    ifconfig ${1:-en0} | awk '$1 == "inet" { print $2 }'
}

mac()
{
    ifconfig ${1:-en0} | awk '$1 == "ether" { print $2 }'
}

wiki()
{
    dig +short txt $1.wp.dg.cx
}

flatten()
{
    local FlattenTarget=${1:-.}

    find $FlattenTarget -type f -mindepth 2 -exec mv {} $FlattenTarget \;
    find $FlattenTarget -type d -d -depth 1 -exec rm -fr {} \;
}

go_to()
{
    # `type -P` finds _only executables_ in PATH, so it comes back empty
    # for aliases, functions, builtins… anything that doesn't have a home
    # to `go_to`
    # without this guard, typos (like `gt sts`) were complaining and sending me home
    local location=$(type -P "$1")

    if [[ -z $location ]]
    then
        echo "go_to: not an executable in PATH: $1" >&2
        return 1
    fi

    cd "$(dirname "$location")"
}
alias gt=go_to

command_line_tr()
{
    if [[ -z "$3" ]]
    then
        tr $@
    else
        echo "${@:3}" | tr $1 $2
    fi
}
alias cltr=command_line_tr
