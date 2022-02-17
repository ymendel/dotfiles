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
    local branches=('main' 'master')

    for branch in ${branches[@]}
    do
        if ( git branch-exists $branch )
        then
            echo -n $branch
            return 0
        fi
    done

    echo 'could not determine main branch' >&2
    false
}

git_fetch_branch()
{
    local force=''
    if [ ! -z "$2" ]
    then
        force='--force'
    fi

    if [[ $(git_current_branch) == $1 ]]
    then
        git pull $force
    else
        git fetch origin $1:$1 $force
    fi
}

gtt()
{
    cd `git top`
}
