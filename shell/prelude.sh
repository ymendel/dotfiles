# Sourced from bashrc ahead of the loop that picks up every topic *.bash,
# so whatever lives here is available to all of those

# two ways to handle path additions: prepend and append
# both take a directory argument and only add to PATH if it's not already
# present there (and require the directory to actually exist)
#
# that existence requirement doubles as an opt-in: a path can be listed for
# every machine and only joins PATH on the ones where the directory has been
# created
path_prepend()
{
    [[ -d $1 ]] || return 0

    case ":$PATH:" in
        *":$1:"*) ;;
        *) PATH="$1:$PATH" ;;
    esac

    export PATH
}

path_append()
{
    [[ -d $1 ]] || return 0

    case ":$PATH:" in
        *":$1:"*) ;;
        *) PATH="$PATH:$1" ;;
    esac

    export PATH
}
