set_prompt()
{
    PS1="\h:\w"

    if in_git_repo
    then
        PS1+=" ("
        PS1+="\[${Green}\]$(prompt_git_current_head)\[${ResetColor}\]"
        PS1+="\[${Magenta}\]$(prompt_git_rebasing_marker)\[${ResetColor}\]"
        PS1+="@\[${Yellow}\]$(prompt_git_current_rev)\[${ResetColor}\]"

        local STATUS_INFO=$(git status --porcelain --branch | head -2)

        local BRANCH_INFO=$(echo "${STATUS_INFO}" | prompt_git_branch_info)
        if [[ $BRANCH_INFO =~ behind\ ([0-9]+) ]]
        then
            PS1+=" \[${Red}\]↓${BASH_REMATCH[1]}"
        fi
        if [[ $BRANCH_INFO =~ ahead\ ([0-9]+) ]]
        then
            PS1+=" \[${Green}\]↑${BASH_REMATCH[1]}"
        fi
        PS1+="\[${ResetColor}\]"

        PS1+="\[${Cyan}\]$(prompt_git_paused_marker)\[${ResetColor}\]"

        PS1+="|"

        local DIRTY=$(echo "${STATUS_INFO}" | prompt_git_dirty_marker)
        PS1+="\[${Red}\]${DIRTY}\[${ResetColor}\]"

        local STASH=$(prompt_git_stash_count)
        PS1+="\[${Yellow}\]${STASH}\[${ResetColor}\]"

        local CLEAN=''
        if [[ "${DIRTY}${STASH}" == '' ]]
        then
            CLEAN='✔'
        fi
        PS1+="\[${Green}\]${CLEAN}\[${ResetColor}\]"

        PS1+=")"
    fi

    PS1+=" \u\$ "

    export PS1
}

prompt_git_current_head()
{
    local BRANCH=$(git_current_branch)
    if [[ $BRANCH =~ " detached at " ]]
    then
        BRANCH=$(git name-rev --name-only HEAD 2>/dev/null)
    elif [[ $BRANCH =~ no\ branch,\ rebasing\ ([^\)]+) ]]
    then
        BRANCH="${BASH_REMATCH[1]}"
    fi
    echo $BRANCH
}

prompt_git_current_rev()
{
    git rev-parse --short=4 HEAD
}

prompt_git_dirty_marker()
{
    (tail -n +2 | grep -qe .) &>/dev/null && echo -n '§'
}

prompt_git_branch_info()
{
    head -1
}

prompt_git_paused_marker()
{
    git paused && echo -n ' ¶'
}

prompt_git_rebasing_marker()
{
    local BRANCH=$(git_current_branch)
    local REBASE=''
    if [[ $BRANCH =~ "no branch, rebasing " ]]
    then
        REBASE='®'
    fi
    echo $REBASE
}

prompt_git_stash_count()
{
    local STASH_COUNT=$(git stash list | grep . -c)
    if [[ "$STASH_COUNT" != "0" ]]
    then
        echo -n "⚑$STASH_COUNT"
    fi
}

# add prompt commands
# anything that may change over time

# only add a prompt command once
# useful for anything that will re-source the profile
add_prompt_command()
{
    local ADD_COMMAND="$1"
    if [[ "$PROMPT_COMMAND" == "" ]]
    then
        PROMPT_COMMAND=$ADD_COMMAND
    elif [[ ! $PROMPT_COMMAND =~ ";$ADD_COMMAND" ]]
    then
        PROMPT_COMMAND+=";$ADD_COMMAND"
    fi
}

add_prompt_command 'window_title_user_host'
add_prompt_command 'set_prompt'
add_prompt_command 'set_git_main_branch'
