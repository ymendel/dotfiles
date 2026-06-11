# TODO: understand nameref better so these don't have to be globals
declare -A DirtyBreakdown
declare -A BranchInfo

set_prompt()
{
    local ExitCode=$?

    PS1=""

    add_prompt_exit_code $ExitCode

    PS1+="\u@\h:\w"

    add_prompt_repo_info

    PS1+="\n"
    PS1+="\[${Cyan}\][\t]\[${ResetColor}\]"
    add_prompt_duration
    PS1+=" \$ "

    export PS1
}

add_prompt_exit_code()
{
    local ExitCode=$1

    if [[ $ExitCode == 0 ]]
    then
        PS1+="\[${Green}\]✔\[${ResetColor}\] "
    else
        PS1+="\[${Red}\]✖$ExitCode\[${ResetColor}\] "
    fi
}

add_prompt_repo_info()
{
  if [[ $PREFER_JJ_REPO_INFO ]]
  then
    add_prompt_jj_info
  else
    add_prompt_git_info
  fi
}

add_prompt_git_info()
{
    if (! in_git_repo)
    then
        return
    fi

    PS1+=" ("
    PS1+="\[${Green}\]$(prompt_git_current_head)\[${ResetColor}\]"
    PS1+="\[${Magenta}\]$(prompt_git_rebasing_marker)\[${ResetColor}\]"
    PS1+="@\[${Yellow}\]$(prompt_git_current_rev)\[${ResetColor}\]"

    local StatusInfo=$(prompt_git_status_info)

    prompt_git_branch_info "$StatusInfo"
    PS1+="\[${Red}\]${BranchInfo[behind]}\[${ResetColor}\]"
    PS1+="\[${Green}\]${BranchInfo[ahead]}\[${ResetColor}\]"
    PS1+="\[${Cyan}\]${BranchInfo[local]}\[${ResetColor}\]"

    PS1+="\[${Cyan}\]$(prompt_git_paused_marker)\[${ResetColor}\]"

    PS1+="|"

    local Dirty
    if [[ $GIT_PROMPT_DIRTY_BREAKDOWN ]]
    then
        prompt_git_dirty_breakdown "$StatusInfo"
        PS1+="\[${Red}\]${DirtyBreakdown[conflicted]}\[${ResetColor}\]"
        PS1+="\[${Yellow}\]${DirtyBreakdown[staged]}\[${ResetColor}\]"
        PS1+="\[${Red}\]${DirtyBreakdown[deleted]}\[${ResetColor}\]"
        PS1+="\[${Green}\]${DirtyBreakdown[modified]}\[${ResetColor}\]"
        PS1+="\[${Magenta}\]${DirtyBreakdown[renamed]}\[${ResetColor}\]"
        PS1+="\[${Cyan}\]${DirtyBreakdown[untracked]}\[${ResetColor}\]"
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

    BranchInfo=([behind]='' [ahead]='' [local]='')

    if [[ $BranchInfoStr =~ \.\.\. ]]
    then
        if [[ $BranchInfoStr =~ behind\ ([0-9]+) ]]
        then
            BranchInfo[behind]=" ↓${BASH_REMATCH[1]}"
        fi

        if [[ $BranchInfoStr =~ ahead\ ([0-9]+) ]]
        then
            BranchInfo[ahead]=" ↑${BASH_REMATCH[1]}"
        fi
    elif [[ ! $BranchInfoStr =~ \(no\ branch\) ]]
    then
        BranchInfo[local]=" ▼"

        local CurrentBranch=$(git rev-parse --abbrev-ref HEAD)
        local BaseBranch=$(git show-branch 2>/dev/null | grep '\(\*\|^-.*\[\)' | grep -v '\['$CurrentBranch'\([\^]\|~[0-9]\+\)\?\]' | head -n1 | sed 's/.*\[\([^\^~]*\).*\].*/\1/;')
        if [ -n "$BaseBranch" ]
        then
            local MergeBase=$(git merge-base HEAD $BaseBranch)
        fi
        if [ -n "$MergeBase" ]
        then
            local NumCommits=$(git rev-list --count HEAD ^$MergeBase)
        fi
        if [[ $NumCommits ]]
        then
            if [[ $NumCommits -gt 0 ]]
            then
                BranchInfo[ahead]=" ↑${NumCommits}"
            fi
        fi
    fi
}

prompt_git_dirty_marker()
{
    echo "$1" | (tail -n +2 | grep -qe .) &>/dev/null && echo -n '§'
}

prompt_git_dirty_breakdown()
{
    local StatusInfo=$(echo "$1" | tail -n +2 | cut -c 1-2)
    DirtyBreakdown=([modified]='' [staged]='' [deleted]='' [renamed]='' [untracked]='' [conflicted]='')

    local ModifiedCount=$(echo "$StatusInfo" | grep -e '.M' -c)
    if [[ "$ModifiedCount" != "0" ]]
    then
        DirtyBreakdown[modified]="✚${ModifiedCount}"
    fi

    local StagedCount=$(echo "$StatusInfo" | grep -e '[MA].' -c)
    if [[ "$StagedCount" != "0" ]]
    then
        DirtyBreakdown[staged]="●${StagedCount}"
    fi

    local DeletedCount=$(echo "$StatusInfo" | grep 'D \| D' -c)
    if [[ "$DeletedCount" != "0" ]]
    then
        DirtyBreakdown[deleted]="-${DeletedCount}"
    fi

    local RenamedCount=$(echo "$StatusInfo" | grep -e 'R.' -c)
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
see_git_dirty_breakdown

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

see_jj_prompt()
{
    export PREFER_JJ_REPO_INFO=1
}

see_git_prompt()
{
    unset PREFER_JJ_REPO_INFO
}

add_prompt_jj_info()
{
    if (! in_jj_repo)
    then
        return
    fi

    PS1+=" ("
    # PS1+="\[${Green}\]$(prompt_git_current_head)\[${ResetColor}\]"
    # PS1+="\[${Magenta}\]$(prompt_git_rebasing_marker)\[${ResetColor}\]"
    PS1+="@\[${Yellow}\]$(prompt_jj_current_change)\[${ResetColor}\]"

    # local StatusInfo=$(prompt_git_status_info)

    # prompt_git_branch_info "$StatusInfo"
    # PS1+="\[${Red}\]${BranchInfo[behind]}\[${ResetColor}\]"
    # PS1+="\[${Green}\]${BranchInfo[ahead]}\[${ResetColor}\]"
    # PS1+="\[${Cyan}\]${BranchInfo[local]}\[${ResetColor}\]"

    # PS1+="\[${Cyan}\]$(prompt_git_paused_marker)\[${ResetColor}\]"

    # PS1+="|"

    # local Dirty
    # if [[ $GIT_PROMPT_DIRTY_BREAKDOWN ]]
    # then
    #     prompt_git_dirty_breakdown "$StatusInfo"
    #     PS1+="\[${Red}\]${DirtyBreakdown[conflicted]}\[${ResetColor}\]"
    #     PS1+="\[${Yellow}\]${DirtyBreakdown[staged]}\[${ResetColor}\]"
    #     PS1+="\[${Red}\]${DirtyBreakdown[deleted]}\[${ResetColor}\]"
    #     PS1+="\[${Green}\]${DirtyBreakdown[modified]}\[${ResetColor}\]"
    #     PS1+="\[${Magenta}\]${DirtyBreakdown[renamed]}\[${ResetColor}\]"
    #     PS1+="\[${Cyan}\]${DirtyBreakdown[untracked]}\[${ResetColor}\]"
    #     Dirty=$(echo "${DirtyBreakdown[@]}" | tr -d ' ')
    # else
    #     Dirty=$(prompt_git_dirty_marker "$StatusInfo")
    #     PS1+="\[${Red}\]${Dirty}\[${ResetColor}\]"
    # fi

    # local Stash=$(prompt_git_stash_count)
    # PS1+="\[${Yellow}\]${Stash}\[${ResetColor}\]"

    # local Clean=''
    # if [[ "${Dirty}${Stash}" == '' ]]
    # then
    #     Clean='✔'
    # fi
    # PS1+="\[${Green}\]${Clean}\[${ResetColor}\]"

    PS1+=")"

}

prompt_jj_current_change()
{
    jj show @ -T 'change_id.short()'
}


# command timing
# requires bash 5+ for $EPOCHREALTIME

__cmd_start_record()
{
    [[ -z $__cmd_armed ]] && return
    __cmd_start=$EPOCHREALTIME
    unset __cmd_armed
}

# chain our DEBUG trap with anything else's instead of clobbering
# called from PROMPT_COMMAND so we re-chain if anything later (e.g. chruby) clobbered us
# the existing trap is passed in because DEBUG isn't inherited into functions
__install_debug_trap()
{
    local Existing=$1
    case $Existing in
        *__cmd_start_record*) return ;;
    esac

    if [[ -n $Existing ]]
    then
        Existing=${Existing#trap -- \'}
        Existing=${Existing%\' DEBUG}
        trap "__cmd_start_record; ${Existing}" DEBUG
    else
        trap '__cmd_start_record' DEBUG
    fi
}

__cmd_arm()
{
    __cmd_armed=1
}

__format_duration()
{
    awk -v t="$1" 'BEGIN {
        if (t < 1)    { exit }
        if (t < 60)   { printf "%ds",     int(t + 0.5); exit }
        if (t < 3600) { printf "%dm%ds",  int(t/60), int(t) % 60; exit }
                        printf "%dh%dm",  int(t/3600), int((t % 3600) / 60)
    }'
}

add_prompt_duration()
{
    [[ -z $__cmd_start ]] && return

    local Elapsed=$(awk -v s="$__cmd_start" -v e="$EPOCHREALTIME" 'BEGIN { printf "%.3f", e - s }')
    unset __cmd_start

    local Formatted=$(__format_duration "$Elapsed")
    [[ -n $Formatted ]] && PS1+=" \[${Cyan}\](+${Formatted})\[${ResetColor}\]"
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
# capture the existing DEBUG trap at top level; functions don't inherit DEBUG without functrace
add_prompt_command '__install_debug_trap "$(trap -p DEBUG)"'
add_prompt_command '__cmd_arm'  # arm last, so DEBUG only fires for the user's next command
