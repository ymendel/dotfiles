PROMPT_COMMAND+=';set_git_main_branch'

function set_git_main_branch
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

function git_main_branch()
{
    branches=('main' 'master')

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

function gtt()
{
    cd `git top`
}
