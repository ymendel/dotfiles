PROMPT_COMMAND+=';set_prompt'

set_prompt()
{
    PS1="\h:\w"

    if in_git_repo
    then
        PS1+=" ("
        PS1+="\[${Green}\]$(git_current_head)\[${ResetColor}\]"
        PS1+="\[${Red}\]$(git_rebasing)\[${ResetColor}\]"
        PS1+="@\[${Yellow}\]$(git_current_rev)\[${ResetColor}\]"

        STATUS_INFO=`git status --porcelain --branch | head -2`

        DIRTY=$(echo "${STATUS_INFO}" | git_dirty)
        PS1+="\[${Red}\]${DIRTY}\[${ResetColor}\]"

        PS1+="\[${Cyan}\]$(git_paused)\[${ResetColor}\]"

        BRANCH_INFO=`echo "${STATUS_INFO}" | git_branch_info`
        if [[ $BRANCH_INFO =~ behind\ ([0-9]+) ]]
        then
            PS1+=" \[${Red}\]↓${BASH_REMATCH[1]}"
        fi
        if [[ $BRANCH_INFO =~ ahead\ ([0-9]+) ]]
        then
            PS1+=" \[${Green}\]↑${BASH_REMATCH[1]}"
        fi

        PS1+="\[${ResetColor}\])"
    fi

    PS1+=" \u\$ "
    export PS1
}

in_git_repo()
{
    git rev-parse HEAD > /dev/null 2>&1
}

git_current_branch()
{
    git branch 2>/dev/null | awk '/^\* /{$1 = ""; print $0}'
}

git_current_head()
{
    BRANCH=`git_current_branch`
    if [[ $BRANCH =~ " detached at " ]]
    then
        BRANCH=`git name-rev --name-only HEAD 2>/dev/null`
    elif [[ $BRANCH =~ no\ branch,\ rebasing\ ([^\)]+) ]]
    then
        BRANCH="${BASH_REMATCH[1]}"
    fi
    echo $BRANCH
}

git_current_rev()
{
    git rev-parse --short=4 HEAD
}

git_dirty()
{
    (tail -n +2 | grep -qe .) > /dev/null 2>&1 && echo -n '*'
}

git_branch_info()
{
    head -1
}

git_paused()
{
    git paused && echo -n '║'
}

git_rebasing()
{
    BRANCH=`git_current_branch`
    REBASE=''
    if [[ $BRANCH =~ "no branch, rebasing " ]]
    then
        REBASE='↩'
    fi
    echo $REBASE
}
