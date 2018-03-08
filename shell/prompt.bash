PROMPT_COMMAND+=';set_prompt'

set_prompt()
{
    PS1="\h:\w"

    if in_git_repo
    then
        PS1+=" ("
        PS1+="\[${Green}\]$(git_current_head)\[${ResetColor}\]"
        PS1+="@\[${Yellow}\]$(git_current_rev)\[${ResetColor}\]"
        PS1+="\[${Red}\]$(git_dirty)\[${ResetColor}\]"

        BRANCH_INFO=`git_branch_info`
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
  git rev-parse --git-dir > /dev/null 2>&1
}

git_current_branch()
{
  git branch 2>/dev/null | awk '/^\* /{print $2}'
}

git_current_head()
{
  BRANCH=`git_current_branch`
  if [[ $BRANCH = "(detached" ]]
  then
    BRANCH=`git name-rev --name-only HEAD 2>/dev/null`
  fi
  echo $BRANCH
}

git_current_rev()
{
  git rev-parse --short=4 HEAD
}

git_dirty()
{
  (git status --porcelain | grep -qe .) > /dev/null 2>&1 && echo -n '*'
}

git_branch_info()
{
  git status --porcelain --branch | head -1
}

git_ahead_behind()
{
  AHEAD_BEHIND=''
  if [[ $BRANCH_INFO =~ behind\ ([0-9]+) ]]
  then
    AHEAD_BEHIND+=" ↓${BASH_REMATCH[1]}"
  fi
  if [[ $BRANCH_INFO =~ ahead\ ([0-9]+) ]]
  then
    AHEAD_BEHIND+=" ↑${BASH_REMATCH[1]}"
  fi

  echo $AHEAD_BEHIND
}

git_display()
{
  if in_git_repo
  then
    GIT_AHEAD_BEHIND=`git_ahead_behind`
    if [[ $GIT_AHEAD_BEHIND != '' ]]
    then
        GIT_AHEAD_BEHIND=" ${GIT_AHEAD_BEHIND}"
    fi
    echo " ($(git_current_head)@$(git_current_rev)$(git_dirty)${GIT_AHEAD_BEHIND})"
  fi
}

rvm_current()
{
  rvm info | sed -n '2,1s/:$//p'
}
