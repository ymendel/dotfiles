# inspired by http://beckism.com/2009/02/better_bash_prompt/#comment-19411
divider()
{
    echo -n "${Bold}${YellowBg}"
    for ((x=1; x <= $COLUMNS; x++))
    do
        echo -n "="
    done
    echo $ResetColor
}

# `man read` takes me to the builtins manpage, which feels like an insult
# `help read` just plops the text out and makes me scroll back, rather than
# the nice documentation behavior I've come to expect from `man`.
#
# To make this more like `man`, use the pager and the `-m` (man-like) layout.
# The only thing missing is making `man read` work.
#
# -s and -d are asking for the one-line forms on purpose, so leave those alone.
# (-d would win over -m anyway, but -m beats -s, which would be annoying.)
help()
{
    case "$1" in
        -*) builtin help "$@" ;;
        *)  builtin help -m "$@" ;;
    esac 2>&1 | "${PAGER:-less}"

    return "${PIPESTATUS[0]}"
}
