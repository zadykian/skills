# shellcheck shell=sh
# The functions of the lint plugin's hooks, sourced by lint-file.sh and lint-tree.sh
# (docs/lint.md). Sourcing it sets variables and defines functions, and runs nothing.

# input is the hook's JSON, as each hook sets it.
input=

# field prints the string field $1 of the hook's JSON in $input, escapes as they are. sed reads
# it, as jq may be missing. A quote in a JSON string is escaped, so only a key matches.
field() {
    printf '%s\n' "$input" | tr '\n' ' ' |
        sed -E -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"(([^\"\\\\]|\\\\.)*)\".*/\1/p"
}

# flag succeeds where the hook's JSON in $input sets the key $1 to true.
flag() {
    printf '%s\n' "$input" | tr '\n' ' ' | grep -q "\"$1\"[[:space:]]*:[[:space:]]*true"
}

# plain succeeds where the path $1 holds only characters of [A-Za-z0-9._/@+-] and no part of it
# starts with -. make pastes a path into its recipes unquoted, and expands a $ in it, and a tool
# takes a part starting with - as an option. A path that passes is safe in a line of the record
# and in the hooks' JSON too.
plain() {
    case $1 in
    '' | *[!A-Za-z0-9._/@+-]* | -* | */-*) return 1 ;;
    esac
}

# notice shows the user the text $1 in the hook's JSON output, and lets Claude go on. It drops
# control characters and escapes quotes and backslashes.
notice() {
    printf '{"systemMessage": "%s"}\n' \
        "$(printf '%s' "$1" | tr -d '\000-\037' | sed 's/[\\"]/\\&/g')"
}
