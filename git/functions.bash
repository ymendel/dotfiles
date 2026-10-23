in_git_repo()
{
    git rev-parse HEAD &>/dev/null
}

git_current_branch()
{
    git branch 2>/dev/null | awk '/^\* /{$1 = ""; print $0}' | sed 's/^ //'
}

set_git_main_branch()
{
    if in_git_repo
    then
        export MAIN_BRANCH=$(git_main_branch)
        export REVIEW_BASE=$MAIN_BRANCH
    else
        unset MAIN_BRANCH
        unset REVIEW_BASE
    fi
}

git_main_branch()
{
    local branch=$(git config config.main-branch)
    if [ -n "$branch" ]
    then
        echo -n $branch
        return 0
    fi

    local branches=('main' 'master')

    for branch in ${branches[@]}
    do
        if ( git branch-exists $branch )
        then
            echo -n $branch
            return 0
        fi
    done

    echo 'could not automatically determine main branch' >&2
    echo 'consider setting the config.main-branch value' >&2
    false
}

gtt()
{
    # if I'm not in a git repo, this will silently send me home
    if in_git_repo
    then
        cd "$(git top)"
    else
        echo "gtt: not in a git repo" >&2
        return 1
    fi
}
