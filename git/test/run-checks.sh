#!/usr/bin/env bash
#
# Checks the pre-commit credential guard. Run it after touching
# template/hooks/pre-commit:
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

printf '\n  %d passed, %d failed\n' "$pass" "$fail"
[[ $fail -eq 0 ]]
