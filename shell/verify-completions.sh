#!/usr/bin/env bash
#
# Does every route into the lazy loader actually work, in a shell that loaded
# the real dotfiles? Three routes to cover:
#
#   compat  — Homebrew's own file, found through the install.sh symlink
#   shim    — a tracked one-liner in shell/bash-completion/completions
#   lazy    — a formula that installs into share/bash-completion/completions
#
# Reports the *source* of each, so a pass through the wrong route still shows.
# The commands it checks are whatever this machine happens to have installed, so
# SKIP is a normal result elsewhere and the list is meant to be edited.
# Read-only.
#
# Everything below goes in as a single-quoted -c argument, so it can't contain an
# apostrophe. A quoted heredoc on stdin would lift that, and it's been tried: an
# interactive shell reading stdin prints the prompt before every line it consumes,
# which took the run from 1.4s to 10.6s and buried the result lines in prompt
# escapes, continuation markers and a trailing `logout`. If the constraint ever
# starts to grate, the way out is to move the body into its own file — not named
# *.bash, or bashrc.symlink will source it at startup — and source that from -c.
set -uo pipefail

bash -lic '
    startup_specs="$(complete -p 2>/dev/null)"

    check () {  # check <command> <route>
        local cmd="$1" route="$2"

        if ! command -v "$cmd" > /dev/null 2>&1
        then
            printf "  %-8s %-8s SKIP (no such command here)\n" "$cmd" "$route"
            return
        fi

        # Registered before this check asked for it, which happens two ways worth
        # telling apart: something loaded it at startup, defeating the whole point
        # of lazy, or an earlier check pulled in a file that registers several
        # commands at once. The snapshot taken above is what separates them.
        if complete -p "$cmd" > /dev/null 2>&1
        then
            if printf "%s\n" "$startup_specs" | grep -q -- " $cmd$"
            then
                printf "  %-8s %-8s EAGER (registered at startup)\n" "$cmd" "$route"
            else
                printf "  %-8s %-8s SHARED (an earlier check registered it)\n" "$cmd" "$route"
            fi
            return
        fi

        if _comp_load -- "$cmd" > /dev/null 2>&1 && complete -p "$cmd" > /dev/null 2>&1
        then
            printf "  %-8s %-8s ok\n" "$cmd" "$route"
        else
            printf "  %-8s %-8s LOST\n" "$cmd" "$route"
        fi
    }

    printf "bash-completion %s, compat dir %s\n\n" \
        "${BASH_COMPLETION_VERSINFO[*]:-<not loaded>}" \
        "${BASH_COMPLETION_COMPAT_DIR:-<default>}"

    check gdal   compat
    check brew   compat
    check bat    compat

    # heroku used to report LOST on this route, and did so on the eager path too:
    # its compat file only sources a cache under ~/Library that names a heroku
    # that is no longer installed. It has a shim of its own now, sourcing the
    # completion function directly, so it should pass as one.
    check heroku shim
    check stripe shim
    check adr    shim
    # One Homebrew file registers all three of these, so whichever is checked
    # first reports ok and the other two report SHARED. That is the design working
    # rather than a regression — see the note in bash-completion/completions/gcloud.
    check gcloud shim
    check bq     shim
    check gsutil shim
    check git    lazy

    # Two the repo registers itself, because bashrc.symlink sources every *.bash
    # and both of these are one: ruby/rake_completion.bash, and
    # security/completion.bash, which runs `op completion bash` to get its source.
    # So EAGER is the right answer for them, and having them here keeps that branch
    # exercised instead of taking it on trust.
    check rake   repo
    check op     repo
' 2>&1 | grep -v 'job control\|terminal process group'
