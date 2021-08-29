# TODO: understand nameref better so this doesn't have to be a global
declare -A DirtyBreakdown

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

    local BranchInfo
    declare -a BranchInfo
    prompt_git_branch_info "$StatusInfo" BranchInfo
    PS1+="\[${Red}\]${BranchInfo[0]}\[${ResetColor}\]"
    PS1+="\[${Green}\]${BranchInfo[1]}\[${ResetColor}\]"

    PS1+="\[${Cyan}\]$(prompt_git_paused_marker)\[${ResetColor}\]"

    PS1+="|"

    local Dirty
    if [[ $GIT_PROMPT_DIRTY_BREAKDOWN ]]
    then
        prompt_git_dirty_breakdown "$StatusInfo"
        PS1+="\[${Green}\]${DirtyBreakdown[modified]}\[${ResetColor}\]"
        PS1+="\[${Yellow}\]${DirtyBreakdown[staged]}\[${ResetColor}\]"
        PS1+="\[${Red}\]${DirtyBreakdown[stagedDelete]}\[${ResetColor}\]"
        PS1+="\[${Yellow}\]${DirtyBreakdown[renamed]}\[${ResetColor}\]"
        PS1+="\[${Cyan}\]${DirtyBreakdown[untracked]}\[${ResetColor}\]"
        PS1+="\[${Red}\]${DirtyBreakdown[conflicted]}\[${ResetColor}\]"
        Dirty=$(echo "${DirtyBreakdown[@]}" | tr -d ' ')
    else
        Dirty=$(prompt_git_dirty_marker "$StatusInfo")
        PS1+="\[${Red}\]${Dirty}\[${ResetColor}\]"
    fi

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
    if [[ $GIT_PROMPT_DIRTY_BREAKDOWN ]]
    then
        git status --porcelain --branch --untracked-files=all
    else
        git status --porcelain --branch | head -2
    fi
}

prompt_git_branch_info()
{
    local BranchInfoStr=$(echo "$1" | head -1)

    local -n BehindAhead=$2
    BehindAhead=('' '')

    if [[ $BranchInfoStr =~ behind\ ([0-9]+) ]]
    then
        BehindAhead[0]=" ↓${BASH_REMATCH[1]}"
    fi
    if [[ $BranchInfoStr =~ ahead\ ([0-9]+) ]]
    then
        BehindAhead[1]=" ↑${BASH_REMATCH[1]}"
    fi
}

prompt_git_dirty_marker()
{
    echo "$1" | (tail -n +2 | grep -qe .) &>/dev/null && echo -n '§'
}

prompt_git_dirty_breakdown()
{
    local StatusInfo=$(echo "$1" | tail -n +2 | cut -c 1-2)
    DirtyBreakdown=([modified]='' [staged]='' [stagedDelete]='' [renamed]='' [untracked]='' [conflicted]='')

    local ModifiedCount=$(echo "$StatusInfo" | grep ' M' -c)
    if [[ "$ModifiedCount" != "0" ]]
    then
        DirtyBreakdown[modified]="✚${ModifiedCount}"
    fi

    local StagedCount=$(echo "$StatusInfo" | grep -e '[MA] ' -c)
    if [[ "$StagedCount" != "0" ]]
    then
        DirtyBreakdown[staged]="●${StagedCount}"
    fi

    local StagedDeleteCount=$(echo "$StatusInfo" | grep 'D ' -c)
    if [[ "$StagedDeleteCount" != "0" ]]
    then
        DirtyBreakdown[stagedDelete]="-${StagedDeleteCount}"
    fi

    local RenamedCount=$(echo "$StatusInfo" | grep 'R ' -c)
    if [[ "$RenamedCount" != "0" ]]
    then
        DirtyBreakdown[renamed]="→${RenamedCount}"
    fi

    local UntrackedCount=$(echo "$StatusInfo" | grep '??' -c)
    if [[ "$UntrackedCount" != "0" ]]
    then
        DirtyBreakdown[untracked]="…${UntrackedCount}"
    fi

    local ConflictedCount=$(echo "$StatusInfo" | grep -e 'U.\|.U\|AA' -c)
    if [[ "$ConflictedCount" != "0" ]]
    then
        DirtyBreakdown[conflicted]="✖${ConflictedCount}"
    fi
}

see_git_dirty_breakdown()
{
    export GIT_PROMPT_DIRTY_BREAKDOWN=1
}

see_git_dirty_simple()
{
    unset GIT_PROMPT_DIRTY_BREAKDOWN
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
