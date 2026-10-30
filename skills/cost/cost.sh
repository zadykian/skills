#!/bin/sh
# Reports what Claude Code sessions cost, from their transcripts: cost.sh [SESSION...]
#
# A SESSION is a transcript, ~/.claude/projects/DIR/ID.jsonl, or its ID in the current directory's
# project: the project's latest by default. Its agents' transcripts sit in ID/subagents/. A response spans records of one message id, so each
# counts once. Its cost is in units of an Opus 5.5 input token: an output token weighs 5, a cache
# write 1.25, or 2 on the 1-hour cache, and a cache read 0.05. Sonnet costs half, and Haiku 1/40,
# or 1/8 in a request whose prompt passes 100k tokens. Any other model costs as Opus. It needs jq.

set -eu

# die prints a message of the script's and exits with status 1.
die() {
    printf 'cost.sh: %s\n' "$*" >&2
    exit 1
}

# rows prints the rows of the transcript $1, of the tier $2, whose thread $3 names.
rows() {
    jq -c -R --arg tier "$2" --arg thread "$3" -f "$dir/rows.jq" "$1"
}

# session prints the rows of the transcript $1 and of its agents'.
session() {
    rows "$1" main main
    for file in "${1%.jsonl}"/subagents/*.jsonl; do
        [ ! -f "$file" ] || rows "$file" subagent "$(basename "$file" .jsonl)"
    done
    for file in "${1%.jsonl}"/subagents/workflows/*/*.jsonl; do
        [ -f "$file" ] || continue
        rows "$file" workflow "$(basename "$(dirname "$file")")/$(basename "$file" .jsonl)"
    done
}

main() {
    command -v jq >/dev/null || die "no jq"
    dir=$(dirname -- "$0")
    # Claude Code names a project's directory after its path, each character but [A-Za-z0-9-] a -.
    project=${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects/$(printf '%s' \
        "${CLAUDE_PROJECT_DIR:-$PWD}" | sed 's/[^A-Za-z0-9-]/-/g')
    if [ $# -eq 0 ]; then
        latest=
        for file in "$project"/*.jsonl; do
            if [ -f "$file" ] && { [ -z "$latest" ] || [ "$file" -nt "$latest" ]; }; then
                latest=$file
            fi
        done
        [ -n "$latest" ] || die "no session in $project"
        set -- "$latest"
    fi
    for arg; do
        case $arg in
        *.jsonl) file=$arg ;;
        *) file=$project/$arg.jsonl ;;
        esac
        [ -f "$file" ] || die "no transcript $file"
        session "$file"
    done >"$tmp/rows"
    jq -s -r --argjson sessions $# -f "$dir/report.jq" "$tmp/rows"
}

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
trap 'exit 1' HUP INT TERM
main "$@"
