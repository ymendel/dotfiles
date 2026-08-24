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

history () {  # history <dir> <subject>... — one commit per subject
    local dir=$1 subject
    shift

    git -C "$dir" init --quiet
    # keep the central hooks out of the fixture's own commits, so only the push
    # being tested runs anything
    mkdir -p "$dir/.nohooks"
    git -C "$dir" config core.hooksPath "$dir/.nohooks"

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

printf '\n  %d passed, %d failed\n' "$pass" "$fail"
[[ $fail -eq 0 ]]
