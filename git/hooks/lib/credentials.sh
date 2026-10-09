# What a credential-shaped key looks like in a settings file, and how to find one
# without ever printing its value.
#
# This lib is shared by pre-commit (which checks the index), and pre-push (which
# checks the commits going out). It's a bit of belt-and-suspenders, but also
# definitely important because of `git pause` and its `--no-verify` use.

credential_keywords='token|secret|password|passwd|api[_-]?key|access[_-]?key|private[_-]?key|credential|authorization'
credential_key_re="\"[A-Za-z0-9_-]*(${credential_keywords})[A-Za-z0-9_-]*\""
credential_assignment_re="${credential_key_re}[[:space:]]*:[[:space:]]*\"[^\"]"

# Settings names that just _look_ to be credential-shaped. Matched whole, so
# something that only contains one of these (e.g. `my_semantic_tokens) is still
# flagged. Add to this. *DO NOT* narrow the keywords to skip things. And don't use
# `--no-verify` to skip things (unless you really want to accept what you're
# giving up.)
credential_benign_keys='semantic_tokens'
credential_benign_re="^\"(${credential_benign_keys})\"$"

# Filter a list of paths on stdin down to the settings files worth checking.
credential_settings_paths () {
    grep -E 'settings\.json(\.symlink)?$'
}

# Read a settings file on stdin, and print "<line>  <key>" per credential-shaped
# assignment. Only line and key, *never* the value.
#
# a simple text scan rather than parsing — at least Zed config is JSONC, an
# `jq` doesn't do that
credential_scan () {
    grep -inE "$credential_assignment_re" | while IFS= read -r hit
    do
        # every credential-shaped key on the line, not just the first, so a benign
        # one sitting ahead of a real one doesn't speak for the whole line
        flagged=$(printf '%s\n' "$hit" \
            | grep -oiE "$credential_key_re" \
            | grep -viE "$credential_benign_re" \
            | head -1)
        [ -n "$flagged" ] || continue
        printf '%s  %s\n' "${hit%%:*}" "$flagged"
    done
}
