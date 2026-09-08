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

git_clean_merged()
{
    local main
    main=$(git_main_branch) || return 1

    # sometimes a repo has branches other than "the main one" to keep around
    # one example is an integration branch behind the production branch
    # protect those branches with `git config --add config.keep-branch <name>`
    local -A keep=( ["$main"]=1 )
    local branch
    while read -r branch
    do
        keep["$branch"]=1
    done < <(git config --get-all config.keep-branch)

    local -a doomed=()
    while read -r branch
    do
        [[ -v keep["$branch"] ]] || doomed+=("$branch")
    done < <(git branch --merged "$main" --format='%(refname:short)')

    [[ ${#doomed[@]} -gt 0 ]] || return 0

    git branch -d "${doomed[@]}"
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
    # if I'm not in a git repo, this will silently send me home
    if in_git_repo
    then
        cd "$(git top)"
    else
        echo "gtt: not in a git repo" >&2
        return 1
    fi
}

git_blame_with_subject()
{
    git blame -s "$@" | while read -r hash filename rest;
    do
      printf "%-9s %-50.50s | %s\n" "$hash" "$(git log -1 --pretty=%s "$hash")" "$rest";
    done
}
