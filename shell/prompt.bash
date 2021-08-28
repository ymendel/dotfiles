set_prompt()
{
    local ExitCode=$?

    PS1=""

    add_prompt_exit_code $ExitCode

    PS1+="\h:\w"

    add_prompt_git_info

    PS1+=" \u\$ "

    export PS1
}

add_prompt_exit_code() {
    local ExitCode=$1

    if [[ $ExitCode == 0 ]]
    then
        PS1+="\[${Green}\]✔\[${ResetColor}\] "
    else
        PS1+="\[${Red}\]✖$ExitCode\[${ResetColor}\] "
    fi
}

add_prompt_git_info() {
    if (! in_git_repo)
    then
        return
    fi

    PS1+=" ("
    PS1+="\[${Green}\]$(prompt_git_current_head)\[${ResetColor}\]"
    PS1+="\[${Magenta}\]$(prompt_git_rebasing_marker)\[${ResetColor}\]"
    PS1+="@\[${Yellow}\]$(prompt_git_current_rev)\[${ResetColor}\]"

    local StatusInfo=$(prompt_git_status_info)

    local BranchInfo=$(prompt_git_branch_info "$StatusInfo")
    if [[ $BranchInfo =~ behind\ ([0-9]+) ]]
    then
        PS1+=" \[${Red}\]↓${BASH_REMATCH[1]}"
    fi
    if [[ $BranchInfo =~ ahead\ ([0-9]+) ]]
    then
        PS1+=" \[${Green}\]↑${BASH_REMATCH[1]}"
    fi
    PS1+="\[${ResetColor}\]"

    PS1+="\[${Cyan}\]$(prompt_git_paused_marker)\[${ResetColor}\]"

    PS1+="|"

    local Dirty=$(prompt_git_dirty_marker "$StatusInfo")
    PS1+="\[${Red}\]${Dirty}\[${ResetColor}\]"

    local Stash=$(prompt_git_stash_count)
    PS1+="\[${Yellow}\]${Stash}\[${ResetColor}\]"

    local Clean=''
    if [[ "${Dirty}${Stash}" == '' ]]
    then
        Clean='✔'
    fi
    PS1+="\[${Green}\]${Clean}\[${ResetColor}\]"

    PS1+=")"
}

prompt_git_current_head()
{
    local Branch=$(git_current_branch)
    if [[ $Branch =~ " detached at " ]]
    then
        Branch=$(git name-rev --name-only HEAD 2>/dev/null)
    elif [[ $Branch =~ no\ branch,\ rebasing\ ([^\)]+) ]]
    then
        Branch="${BASH_REMATCH[1]}"
    fi
    echo $Branch
}

prompt_git_current_rev()
{
    git rev-parse --short=4 HEAD
}

prompt_git_status_info()
{
    git status --porcelain --branch | head -2
}

prompt_git_branch_info()
{
    echo "$1" | head -1
}

prompt_git_dirty_marker()
{
    echo "$1" | (tail -n +2 | grep -qe .) &>/dev/null && echo -n '§'
}

prompt_git_paused_marker()
{
    git paused && echo -n ' ¶'
}

prompt_git_rebasing_marker()
{
    local Branch=$(git_current_branch)
    local Rebase=''
    if [[ $Branch =~ "no branch, rebasing " ]]
    then
        Rebase='®'
    fi
    echo $Rebase
}

prompt_git_stash_count()
{
    local StashCount=$(git stash list | grep . -c)
    if [[ "$StashCount" != "0" ]]
    then
        echo -n "⚑$StashCount"
    fi
}

# add prompt commands
# anything that may change over time

# only add a prompt command once
# useful for anything that will re-source the profile
add_prompt_command()
{
    local AddCommand="$1"
    if [[ "$PROMPT_COMMAND" == "" ]]
    then
        PROMPT_COMMAND=$AddCommand
    elif [[ ! $PROMPT_COMMAND =~ ";$AddCommand" ]]
    then
        PROMPT_COMMAND+=";$AddCommand"
    fi
}

# make sure a particlar command is at the _start_
# this is important to make sure the exit code is correct
prepend_prompt_command()
{
    local AddCommand="$1"
    if [[ "$PROMPT_COMMAND" == "" ]]
    then
        PROMPT_COMMAND=$AddCommand
    elif [[ ! $PROMPT_COMMAND =~ "^$AddCommand;" ]]
    then
        PROMPT_COMMAND="$AddCommand;$PROMPT_COMMAND"
    fi
}

prepend_prompt_command 'set_prompt'
add_prompt_command 'set_git_main_branch'
add_prompt_command 'window_title_user_host'
