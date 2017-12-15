export PS1="\h:\w\$(git_display) \u\$ "

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

git_dirty()
{
  (git status --porcelain | grep -qe .) > /dev/null 2>&1 && echo '*'
}

git_ahead_behind()
{
  BRANCH_INFO=`git status --porcelain --branch | head -1`
  AHEAD_BEHIND=''
  if [[ $BRANCH_INFO =~ behind\ ([0-9]+) ]]
  then
    AHEAD_BEHIND+="↓${BASH_REMATCH[1]}"
  fi
  if [[ $BRANCH_INFO =~ ahead\ ([0-9]+) ]]
  then
    AHEAD_BEHIND+="↑${BASH_REMATCH[1]}"
  fi
  echo $AHEAD_BEHIND
}

git_display()
{
  if in_git_repo
  then
    export GIT_DIRTY=`git_dirty`
    export GIT_AHEAD_BEHIND=`git_ahead_behind`
    git_current_head | awk '{if ($1) print " (" $1 ENVIRON["GIT_DIRTY"] ENVIRON["GIT_AHEAD_BEHIND"] ")"}'
  fi
}

rvm_current()
{
  rvm info | sed -n '2,1s/:$//p'
}
