window_title()
{
    echo -ne "\033]0;$1\007"
}

window_title_user_host()
{
    window_title ${USER}@${HOSTNAME%%.*}
}
