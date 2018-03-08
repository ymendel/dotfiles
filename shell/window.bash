window_title()
{
    echo -ne "\033]0;$1\007"
}

window_title_user_host()
{
    window_title ${USER}@${HOSTNAME%%.*}
}

# set the window title
# done as a prompt command to reset if it changes because of e.g. sshing to another place
PROMPT_COMMAND+=';window_title_user_host'
export PROMPT_COMMAND
