export PS1="\h:\w\$(git_display) \u\$ "

git_current_branch()
{
  git branch 2>/dev/null | awk '/^\* /{print $2}'
}

git_current_head()
{
  export BRANCH=`git branch 2>/dev/null | awk '/^\* /{print $2}'`
  if [[ $BRANCH = "(no" ]]; then
    export BRANCH=`git name-rev --name-only HEAD 2>/dev/null`
  fi
  echo $BRANCH
}

git_dirty()
{
  git st 2>/dev/null | grep -c : | awk '{if ($1 > 0) print "*"}'
}

git_display()
{
  export GIT_DIRTY=$(git_dirty)
  git_current_head | awk '{if ($1) print "(" $1 ENVIRON["GIT_DIRTY"] ")"}'
}

rvm_current()
{
  rvm info | sed -n '2,1s/:$//p'
}