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
- `pre-push` — refuse a push carrying a paused commit, or a credential (below)
- `lib/credentials.sh` — the credential matching, shared by the two above

## `pre-commit` — no credentials in a settings file

`pre-commit` refuses a commit that stages a file whose name ends in `settings.json`
(or `settings.json.symlink`, thanks to the convention in my dotfiles) holding a
key named like a credential and with a non-empty value. It never reports the value,
just path/line/key. This and `pre-push` are the hooks here that can stop something.

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

Speaking of false positives, Zed got me with `semantic_tokens` (which is just a rendering
setting, nothing serious). So the hook has a `credential_benign_keys` list for names that
are truly just fine. Those keys are matched whole, where the keyword list matches in part.
That is, the keyword list has `token` and that caught `semantic_tokens`. But
`other_semantic_tokens` would still be caught. Only add things to
`credential_benign_keys`, *do not* put restrictions on `credential_keywords`.

Both of those lists, and the scan that uses them, live in `lib/credentials.sh` rather than
in this hook — `pre-push` needs exactly the same matching, and one copy of a pattern list
is enough. The `credential_` prefix is because it's sourced into a hook with names of its
own.

If you really want to get around this, there's `git commit --no-verify`. But possibly
just make it not flag something legit instead.

## `pre-push` — no pushing a paused commit, or a credential

`git pause` commits everything so work can be parked, and it passes `--no-verify` on
purpose — parking work shouldn't have to satisfy any guards.

But this is just a checkpoint, and it's not meant to leave the local machine. So now
a `pre-push` that refuses a push carrying the `PAUSED: ` commit-subject marker. And
it checks every commit, of course, not just the tip.

`pre-push` also does the credential check, same as `pre-commit`. Since `--no-verify`
is possible in other instances _and_ the `git add --all` may pick up something that
nothing has ever looked at yet, check again on push just to be sure.

Again, this checks every commit — in thise case, each commit's changes. That means
if a credential was added in one commit and removed in another, the push still gets
refused.

Important note: `git diff-tree` reports nothing for a merge commit, so a credential
introduced while resolving a conflict gets past this. Don't do that.

Since git rejects the whole push on a non-zero exit, there is no way to allow some
refs and refuse others. So on refusal, this names the ref and the commit so it's
clear what the offense is — and the two kinds of problem get their own sections, since
they want different fixes.

Just like the commit hook, you can get around this with `git push --no-verify`.
Don't do that.

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

`lib/` gets linked along with the hooks, because the two guards source it relative
to their own location and would otherwise come up empty when run from `.git/hooks/`.

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
