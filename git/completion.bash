# completion for the `!sh -c` aliases
#
# Completion generally works on aliases, provided it's a "plain" one that resolves
# to a regular git command. But if the alias is more interesting than that (i.e.
# starts with `!`), that gets skipped and completion is… not good.
#
# For instance, `git pob <TAB>` completes as `git name`, thanks to `${1:?branch name required}`
#
# Luckily, `__git_main` looks for a function called `_git_<name>`, and so completion
# can be handled.
# Note that every alias needs its own — `git push-other-branch` and `git pob` are two
# separate things, using `_git_push_other_branch` and `_git_pob`. Fun.

# --mode=heads lists every local branch regardless of what's checked out,
__git_complete_local_branch_arg()
{
    # this really does work
    # cword counts from `git`
    # `__git_cmd_idx` is the index of the subcommand after global options are accounted for
    # it's simple math
    if [ $((cword - __git_cmd_idx)) -eq 1 ]
    then
        __git_complete_refs --mode="heads"
    fi
}

_git_pob()                  { __git_complete_local_branch_arg; }
_git_push_other_branch()    { __git_complete_local_branch_arg; }
_git_fb()                   { __git_complete_local_branch_arg; }
_git_fetch_branch()         { __git_complete_local_branch_arg; }
_git_fbf()                  { __git_complete_local_branch_arg; }
_git_fetch_branch_force()   { __git_complete_local_branch_arg; }
