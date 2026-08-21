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
- `pre-commit` — refuse a commit that stages a settings file carrying a credential (below)

## `pre-commit` — no credentials in a settings file

`pre-commit` refuses a commit that stages a file whose name ends in `settings.json`
(or `settings.json.symlink`, thanks to the convention in my dotfiles) holding a
key named like a credential and with a non-empty value. It never reports the value,
just path/line/key. This is the first (and so far, only) hook that can stop something.

It was created for Zed, which handles its config itself, and has `context_servers`
entries that take credentials inline, like y'know maybe a GitHub Personal Access
Token. And since I'd like to track my Zed config like so much else, I have to deal
with that. At least until ([zed#26043](https://github.com/zed-industries/zed/discussions/26043)
or something like it changes the landscape.

GitHub push protection would be nice to use here, but all I can use in a personal
repo is the recognized-provider-pattern. "Generic patterns" would do it for me,
if I could use it. So hook it is!

Since Zed's settings file is JSONC (allows fancy things like comments, trailing
commas, readability), the check is a text scan rather than parsing — `jq` doesn't
handle JSONC. So this may raise some false positives, which at least is safer than
false negatives.

If you really want to get around this, there's `git commit --no-verify`. But possibly
just make it not flag something legit instead.

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
