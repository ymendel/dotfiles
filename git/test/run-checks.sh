#!/usr/bin/env bash
#
# Checks the two hooks that can stop something — pre-commit's credential guard and
# pre-push's paused-commit guard. Run it after touching either:
#
#     git/test/run-checks.sh
#
# Each check builds a throwaway repo, stages one file, and tries to commit with
# core.hooksPath pointed at this repo's hooks — so the result holds whether or
# not the machine has been bootstrapped.
#
# Deliberately not set -e: a failing check should report, not abort the run.

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
hooks="$(cd "$here/../template/hooks" && pwd -P)"

# Hyphens are not in GitHub's PAT alphabet, so this cannot match GitHub's own
# secret-scanning pattern and trip push protection on this very file.
token='ghp_not-a-real-token'

pass=0
fail=0

check () {  # check <label> <expected> <actual>
    if [[ "$2" == "$3" ]]; then
        printf '  PASS  %-52s %s\n' "$1" "$3"
        pass=$((pass + 1))
    else
        printf '  FAIL  %-52s expected [%s] got [%s]\n' "$1" "$2" "$3"
        fail=$((fail + 1))
    fi
}

attempt () {  # attempt <repo path> <content> — line 1 is blocked|allowed, rest is hook output
    local dir out
    dir="$(mktemp -d)"
    git -C "$dir" init --quiet
    mkdir -p "$dir/$(dirname "$1")"
    printf '%s\n' "$2" > "$dir/$1"
    git -C "$dir" add -- "$1"
    if out="$(git -C "$dir" -c core.hooksPath="$hooks" commit -m 'check' 2>&1)"; then
        printf 'allowed\n'
    else
        printf 'blocked\n'
    fi
    printf '%s\n' "$out"
    rm -rf "$dir"
}

verdict () { printf '%s\n' "$1" | head -1; }
body ()    { printf '%s\n' "$1" | tail -n +2; }

# git hands pre-push a ref's before-and-after as all-zeros when it is being
# created or deleted. Spelled out rather than generated, since the hook's whole
# job turns on recognising it.
zeros=0000000000000000000000000000000000000000

paused_subject='PAUSED: Use `git resume` to continue working.'

fixture () {  # fixture <dir> — an empty repo, central hooks kept out of it
    git -C "$1" init --quiet
    # so only the push being tested runs anything
    mkdir -p "$1/.nohooks"
    git -C "$1" config core.hooksPath "$1/.nohooks"
}

commit_at () {  # commit_at <dir> <path> <content> <subject>
    mkdir -p "$1/$(dirname "$2")"
    printf '%s\n' "$3" > "$1/$2"
    git -C "$1" add -- "$2"
    git -C "$1" commit --quiet -m "$4"
}

history () {  # history <dir> <subject>... — one commit per subject
    local dir=$1 subject
    shift

    fixture "$dir"

    for subject in "$@"
    do
        printf '%s\n' "$subject" >> "$dir/log.txt"
        git -C "$dir" add -- log.txt
        git -C "$dir" commit --quiet -m "$subject"
    done
}

at () { git -C "$1" rev-parse --short "$2"; }  # at <dir> <rev>

# pre-push's contract is argv plus stdin: git passes the remote's name and URL,
# then "<local ref> <local sha> <remote ref> <remote sha>" per ref. Feeding that
# directly covers every branch without needing a remote to push to. GIT_DIR and
# GIT_WORK_TREE put the hook inside the fixture without a `cd`.
attempt_push () {  # attempt_push <dir> <local sha> <remote sha>
    local out
    if out="$(printf '%s %s %s %s\n' refs/heads/main "$2" refs/heads/main "$3" \
        | GIT_DIR="$1/.git" GIT_WORK_TREE="$1" sh "$hooks/pre-push" origin "$1" 2>&1)"
    then
        printf 'allowed\n'
    else
        printf 'blocked\n'
    fi
    printf '%s\n' "$out"
}

# The real shape: JSONC, which is why the hook scans text instead of parsing.
# jq exits 5 on this — the // comment and the trailing commas are both invalid JSON.
read -r -d '' jsonc <<EOF
// Zed settings
{
  "context_servers": {
    "mcp-server-github": {
      "enabled": false,
      "settings": {
        "github_personal_access_token": "$token",
      },
    },
  },
}
EOF

read -r -d '' clean <<'EOF'
// Zed settings
{
  "buffer_font_family": "Fira Code",
  "vim_mode": true,
}
EOF

echo "== the case this exists for"
result="$(attempt zed/settings.json "$jsonc")"
check "JSONC with a PAT is blocked" "blocked" "$(verdict "$result")"
check "the report names the key" "yes" \
    "$([[ "$(body "$result")" == *github_personal_access_token* ]] && echo yes || echo no)"
check "the report does not echo the value" "yes" \
    "$([[ "$(body "$result")" != *"$token"* ]] && echo yes || echo no)"

echo "== jq cannot do this job (why the hook scans as text)"
check "jq rejects the fixture" "no" \
    "$(printf '%s\n' "$jsonc" | jq . >/dev/null 2>&1 && echo yes || echo no)"

echo "== what must still get through"
check "same file without the credential" "allowed" \
    "$(verdict "$(attempt zed/settings.json "$clean")")"
check "an empty value is not a credential" "allowed" \
    "$(verdict "$(attempt zed/settings.json '{ "github_personal_access_token": "" }')")"
check "a non-settings file is out of scope" "allowed" \
    "$(verdict "$(attempt notes/scratch.json "{ \"api_key\": \"$token\" }")")"
check "a benign credential-shaped name is allowed" "allowed" \
    "$(verdict "$(attempt zed/settings.json '{ "semantic_tokens": "combined" }')")"
check "a benign name is matched whole, not as a substring" "blocked" \
    "$(verdict "$(attempt zed/settings.json "{ \"my_semantic_tokens\": \"$token\" }")")"
check "a benign name does not cover the rest of its line" "blocked" \
    "$(verdict "$(attempt zed/settings.json \
        "{ \"semantic_tokens\": \"combined\", \"api_key\": \"$token\" }")")"

echo "== the other two places Zed takes a credential"
check "an Authorization header is blocked" "blocked" \
    "$(verdict "$(attempt zed/settings.json '{ "headers": { "Authorization": "Bearer abc" } }')")"
check "a token in an env block is blocked" "blocked" \
    "$(verdict "$(attempt zed/settings.json '{ "env": { "GITHUB_TOKEN": "abc" } }')")"

echo "== name variants"
check "nested deeper in the tree" "blocked" \
    "$(verdict "$(attempt editing/zed/settings.json "$jsonc")")"
check "a .symlink suffix" "blocked" \
    "$(verdict "$(attempt editing/settings.json.symlink "$jsonc")")"

echo "== pre-push — the accident this exists for"
# The branch is already on the remote and a pause commit lands on top. Range is
# remote..local, which is the shape of every push after the first.
dir="$(mktemp -d)"
history "$dir" 'first' "$paused_subject"
result="$(attempt_push "$dir" "$(at "$dir" HEAD)" "$(at "$dir" HEAD~1)")"
check "a pause commit on top of a pushed branch is blocked" "blocked" \
    "$(verdict "$result")"
check "the report names the ref" "yes" \
    "$([[ "$(body "$result")" == *refs/heads/main* ]] && echo yes || echo no)"
check "the report names the subject" "yes" \
    "$([[ "$(body "$result")" == *PAUSED:* ]] && echo yes || echo no)"
rm -rf "$dir"

echo "== pre-push — every commit being pushed, not just the tip"
dir="$(mktemp -d)"
history "$dir" 'first' "$paused_subject" 'work on top of the pause'
check "a pause commit buried under a later one is blocked" "blocked" \
    "$(verdict "$(attempt_push "$dir" "$(at "$dir" HEAD)" "$(at "$dir" HEAD~2)")")"
rm -rf "$dir"

echo "== pre-push — what must still go through"
dir="$(mktemp -d)"
history "$dir" 'first' 'second'
check "ordinary commits are allowed" "allowed" \
    "$(verdict "$(attempt_push "$dir" "$(at "$dir" HEAD)" "$(at "$dir" HEAD~1)")")"
check "a brand-new branch of ordinary commits is allowed" "allowed" \
    "$(verdict "$(attempt_push "$dir" "$(at "$dir" HEAD)" "$zeros")")"
check "deleting a ref sends nothing to inspect" "allowed" \
    "$(verdict "$(attempt_push "$dir" "$zeros" "$(at "$dir" HEAD)")")"
rm -rf "$dir"

# The range is what makes this true: a pause commit the remote already has is
# not being pushed, so it is none of the hook's business.
dir="$(mktemp -d)"
history "$dir" "$paused_subject" 'later work'
check "a pause commit already on the remote is left alone" "allowed" \
    "$(verdict "$(attempt_push "$dir" "$(at "$dir" HEAD)" "$(at "$dir" HEAD~1)")")"
rm -rf "$dir"

echo "== pre-push — a first push has no remote counterpart to diff against"
dir="$(mktemp -d)"
history "$dir" 'first' "$paused_subject"
check "a new branch carrying a pause commit is blocked" "blocked" \
    "$(verdict "$(attempt_push "$dir" "$(at "$dir" HEAD)" "$zeros")")"
rm -rf "$dir"

echo "== pre-push — the credential pre-commit never saw"
# An ordinary subject on purpose: this is the `--no-verify` commit that isn't a
# pause, which pre-commit skipped and the paused check above would never catch.
dir="$(mktemp -d)"
fixture "$dir"
commit_at "$dir" README.md 'hello' 'first'
commit_at "$dir" zed/settings.json "{ \"github_personal_access_token\": \"$token\" }" \
    'add my zed config'
result="$(attempt_push "$dir" "$(at "$dir" HEAD)" "$(at "$dir" HEAD~1)")"
check "a pushed credential is blocked" "blocked" "$(verdict "$result")"
check "the report names the key" "yes" \
    "$([[ "$(body "$result")" == *github_personal_access_token* ]] && echo yes || echo no)"
check "the report names the file" "yes" \
    "$([[ "$(body "$result")" == *zed/settings.json* ]] && echo yes || echo no)"
check "the report does not echo the value" "yes" \
    "$([[ "$(body "$result")" != *"$token"* ]] && echo yes || echo no)"
rm -rf "$dir"

echo "== pre-push — the pause commit that swept up a credential"
# `git add --all` and `--no-verify` together, which is the case both checks exist
# for. Both should have something to say about it.
dir="$(mktemp -d)"
fixture "$dir"
commit_at "$dir" README.md 'hello' 'first'
commit_at "$dir" zed/settings.json "{ \"github_personal_access_token\": \"$token\" }" \
    "$paused_subject"
result="$(attempt_push "$dir" "$(at "$dir" HEAD)" "$(at "$dir" HEAD~1)")"
check "it is blocked" "blocked" "$(verdict "$result")"
check "the paused commit gets its own section" "yes" \
    "$([[ "$(body "$result")" == *"Paused commits"* ]] && echo yes || echo no)"
check "so does the credential" "yes" \
    "$([[ "$(body "$result")" == *"Credential-shaped keys"* ]] && echo yes || echo no)"
rm -rf "$dir"

echo "== pre-push — a credential the range still carries"
# Gone by the tip, but the push publishes the commit that had it.
dir="$(mktemp -d)"
fixture "$dir"
commit_at "$dir" README.md 'hello' 'first'
commit_at "$dir" zed/settings.json "{ \"api_key\": \"$token\" }" 'oops'
commit_at "$dir" zed/settings.json '{ "api_key": "" }' 'took it back out'
check "added and then removed is still blocked" "blocked" \
    "$(verdict "$(attempt_push "$dir" "$(at "$dir" HEAD)" "$(at "$dir" HEAD~2)")")"
rm -rf "$dir"

echo "== pre-push — credentials that are not this push's problem"
# Already on the remote, so already published. Reporting it forever would block
# every later push without unpublishing anything.
dir="$(mktemp -d)"
fixture "$dir"
commit_at "$dir" zed/settings.json "{ \"api_key\": \"$token\" }" 'already up there'
commit_at "$dir" README.md 'hello' 'later work'
check "one already on the remote is left alone" "allowed" \
    "$(verdict "$(attempt_push "$dir" "$(at "$dir" HEAD)" "$(at "$dir" HEAD~1)")")"
rm -rf "$dir"

echo "== pre-push — what must still go through"
dir="$(mktemp -d)"
fixture "$dir"
commit_at "$dir" README.md 'hello' 'first'
commit_at "$dir" zed/settings.json '{ "vim_mode": true }' 'settings, no creds'
check "a settings file without a credential" "allowed" \
    "$(verdict "$(attempt_push "$dir" "$(at "$dir" HEAD)" "$(at "$dir" HEAD~1)")")"
rm -rf "$dir"

dir="$(mktemp -d)"
fixture "$dir"
commit_at "$dir" README.md 'hello' 'first'
commit_at "$dir" zed/settings.json '{ "semantic_tokens": "combined" }' 'rendering'
check "a benign credential-shaped name" "allowed" \
    "$(verdict "$(attempt_push "$dir" "$(at "$dir" HEAD)" "$(at "$dir" HEAD~1)")")"
rm -rf "$dir"

dir="$(mktemp -d)"
fixture "$dir"
commit_at "$dir" README.md 'hello' 'first'
commit_at "$dir" notes/scratch.json "{ \"api_key\": \"$token\" }" 'not a settings file'
check "a credential outside a settings file is out of scope" "allowed" \
    "$(verdict "$(attempt_push "$dir" "$(at "$dir" HEAD)" "$(at "$dir" HEAD~1)")")"
rm -rf "$dir"

echo "== neither guard runs without its matching"
# The dangerous failure here is the quiet one. No lib means no patterns, and no
# patterns matches nothing — which is indistinguishable from finding nothing. This
# is the shape `git hooks-override` used to produce, since it skipped directories
# and left the hooks in .git/hooks/ with no lib/ beside them.
bare="$(mktemp -d)"
cp "$hooks/pre-commit" "$hooks/pre-push" "$bare/"

dir="$(mktemp -d)"
fixture "$dir"
commit_at "$dir" README.md 'hello' 'first'

check "pre-push refuses" "1" \
    "$(printf '%s %s %s %s\n' refs/heads/main "$(at "$dir" HEAD)" refs/heads/main "$zeros" \
        | GIT_DIR="$dir/.git" GIT_WORK_TREE="$dir" sh "$bare/pre-push" origin "$dir" \
        >/dev/null 2>&1; echo $?)"
check "pre-commit refuses" "1" \
    "$(git -C "$dir" -c core.hooksPath="$bare" commit --quiet --allow-empty -m 'check' \
        >/dev/null 2>&1; echo $?)"

rm -rf "$bare" "$dir"

# And the fix, run for real rather than grepped for. GIT_CONFIG_GLOBAL stands in
# for the global config that hooks-override reads its central path out of, so this
# never touches the real one.
echo "== hooks-override brings lib/ along, so an overridden repo still has it"
fake_global="$(mktemp -d)"
printf '[core]\n\thooksPath = %s\n' "$hooks" > "$fake_global/gitconfig"

dir="$(mktemp -d)"
fixture "$dir"
GIT_CONFIG_GLOBAL="$fake_global/gitconfig" GIT_DIR="$dir/.git" GIT_WORK_TREE="$dir" \
    sh "$here/../bin/git-hooks-override" >/dev/null 2>&1

check "the hooks got linked" "yes" \
    "$([[ -e "$dir/.git/hooks/pre-push" ]] && echo yes || echo no)"
check "and so did the library they source" "yes" \
    "$([[ -e "$dir/.git/hooks/lib/credentials.sh" ]] && echo yes || echo no)"
rm -rf "$fake_global" "$dir"

printf '\n  %d passed, %d failed\n' "$pass" "$fail"
[[ $fail -eq 0 ]]
