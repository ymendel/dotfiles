# Git hooks

This repo ships [a small set of hooks](template/hooks) (mostly ctags maintenance)
and uses git's `core.hooksPath` to apply them to every repo on the machine from
a single central location.

## How it works

[The top-level gitconfig](gitconfig.symlink) sets

```
[core]
    hooksPath = ~/.dotfiles/git/template/hooks
```

With that set, every repo on the machine runs hooks from `~/.dotfiles/git/template/hooks/`
exclusively, regardless of what's in its own `.git/hooks/`. Edit a hook in one place, and
every repo picks up the change immediately, for its next hook fire.

## What's there

- `ctags` — regenerate ctags for the repo (excludes javascript and sql, see `--languages`)
- `post-checkout`, `post-commit`, `post-merge` — run `ctags`
- `post-rewrite` — if the action is a rebase, run `post-merge`

## Per-repo customization: `git hooks-override`

Sometimes a repo needs its own hooks (a project-specific lint pre-commit,
a CI trigger, &c.). Run from inside the repo:

```
git hooks-override
```

This populates `.git/hooks/` with symlinks to every central hook and sets
local `core.hooksPath` to `.git/hooks/`. The repo now uses its own hooks
dir, but un-customized hooks still resolve to the central files (so they
keep auto-updating). Replace any symlink with a real script to override
that hook locally.

To undo: `git config --unset core.hooksPath` and (optionally) clear the
symlinks. The global `hooksPath` takes over again.

## Cleaning up old copies: `git hooks-clean`

Repos that were `git init`'d back when `init.templateDir` was in use have
real hook *copies* sitting in `.git/hooks/`. These are inert now (the
global `core.hooksPath` overrides), but they're confusing cruft and the
copies are likely stale relative to the central versions.

Dry-run for the current repo:

```
git hooks-clean
```

Actually delete:

```
git hooks-clean -f
```

Recursive — clean every repo under a directory:

```
git hooks-clean ~/dev          # dry-run
git hooks-clean -f ~/dev       # delete
```

Repos that have set local `core.hooksPath` (likely opted in via
`git hooks-override`) are skipped — those own their hooks dir.

## Why not `init.templateDir`?

`init.templateDir` copies the template into `.git/` on `git init`. That's
a *push* model: each repo gets a frozen snapshot. Updating the central
hook doesn't propagate. Old repos keep running stale copies. Yes, you can
re-run `git init`, but that's a manual step.

`core.hooksPath` is a *reference* model: every repo uses the central dir.
One edit, all repos updated.

The cost is that per-repo customization is less casual — you can't just
drop a script in `.git/hooks/` and have it work. `git hooks-override`
makes the opt-in cheap.

## Where did this come from?

Tim Pope's [Effortless Ctags with Git](https://tbaggery.com/2011/08/08/effortless-ctags-with-git.html) to start.
My own modifications since then.
