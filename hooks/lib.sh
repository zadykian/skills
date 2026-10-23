# shellcheck shell=sh
# The functions of the lint plugin's hooks, sourced by lint-file.sh and lint-tree.sh
# (docs/lint.md). Sourcing it sets variables and defines functions, and runs nothing.

# The hooks' git commands take no optional lock, such as the index's on a refresh, so that none
# fails a git command that Claude runs at the same time.
GIT_OPTIONAL_LOCKS=0
export GIT_OPTIONAL_LOCKS

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

# common prints the git common directory of the directory $1, which every work tree of a
# repository shares.
common() {
    git -C "$1" rev-parse --path-format=absolute --git-common-dir 2>/dev/null
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

# mentions succeeds where a makefile of the work tree in the current directory names lint-file
# or lint-tree. It reads the makefiles without running them, so it serves before the vouch:
# a tree that names neither gets no notice, and costs no more than this.
mentions() {
    git grep -q --untracked -w -e lint-file -e lint-tree -- \
        GNUmakefile makefile Makefile '*.mk' 2>/dev/null
}

# notice shows the user the text $1 in the hook's JSON output, and lets Claude go on. It drops
# control characters and escapes quotes and backslashes.
notice() {
    printf '{"systemMessage": "%s"}\n' \
        "$(printf '%s' "$1" | tr -d '\000-\037' | sed 's/[\\"]/\\&/g')"
}
