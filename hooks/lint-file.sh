#!/bin/sh
# The lint plugin's PostToolUse hook for Edit, MultiEdit, Write and NotebookEdit (docs/lint.md):
# runs make lint-file on the file just written, in its own work tree. A failure goes to Claude,
# on stderr with status 2. The hook passes over a file outside the project's repository, one gone
# or ignored, a path make cannot take, and a tree whose makefiles name no lint target. It records
# the tree for lint-tree.sh, even one not vouched for, as a commit later in the turn may vouch for
# it. Such a tree runs no gate, and the user gets a notice once.
#
# shellcheck source-path=SCRIPTDIR

set -u

hooks=$(dirname -- "$0")
# shellcheck source=lib.sh
. "$hooks/lib.sh"

# remember adds the work tree $1 to the session's record, which lint-tree.sh lints at Stop and
# then clears.
remember() {
    [ -n "$state" ] || return 0
    grep -qxF -- "$1" "$state/trees" 2>/dev/null || printf '%s\n' "$1" >>"$state/trees"
}

main() {
    # stdin is read whole first, as the hook reads three of its fields.
    input=$(cat)
    file=$(field file_path)
    [ -n "$file" ] || file=$(field notebook_path)
    # A path with an escape in its JSON, a backslash or a quote, is not plain.
    case $file in
    '' | *\\*) return 0 ;;
    esac
    [ -f "$file" ] || return 0
    repo=$(common "${CLAUDE_PROJECT_DIR:-.}")
    dir=$(dirname -- "$file")
    if [ -z "$repo" ] || [ "$(common "$dir")" != "$repo" ]; then
        return 0
    fi
    # The file's own work tree, which may be a linked one, and the file's path in it.
    cd -- "$dir" || return 0
    path=$(git rev-parse --show-prefix 2>/dev/null)$(basename -- "$file")
    top=$(git rev-parse --show-toplevel 2>/dev/null) && cd -- "$top" || return 0
    if ! plain "$top/$path" || git check-ignore -q -- "$path" || ! mentions; then
        return 0
    fi
    if ! state=$(statedir "$(field session_id)") || ! mkdir -p -- "$state"; then
        state=
    fi
    remember "$top"
    if ! why=$(vouch); then
        message="lint: no gate ran in $top, as $why."
        ! fresh "$message" || notice "$message"
        return 0
    fi
    has lint-file || return 0

    out=$(mktemp) || return 0
    trap 'rm -f "$out"' EXIT
    # stdin is /dev/null and the output a file, as some tools refuse handles that do not block.
    if ! make -k -C "$top" --no-print-directory lint-file FILES="$path" \
        </dev/null >"$out" 2>&1; then
        printf 'lint: make lint-file FILES=%s fails in %s:\n' "$path" "$top" >&2
        excerpt "$out" >&2
        return 2
    fi
}

main "$@"
