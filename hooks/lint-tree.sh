#!/bin/sh
# The lint plugin's SessionStart and Stop hook (docs/lint.md). As a session starts, it notes a
# fingerprint of the project's work tree. As Claude ends its turn, it runs make lint-tree in each
# tree that lint-file.sh recorded for the session, and in the project's where its fingerprint
# differs from that note and from the last stop's, as Bash may change it too. Then it clears the
# record, so a turn that changed nothing runs nothing. Failures go to Claude, on stderr with
# status 2. On the stop that follows, stop_hook_active is true, and the hook lets Claude stop:
# what the fix wrote is linted at the next turn's end. A tree equal to origin/main, or one whose
# makefiles have no lint-tree, is passed over, and one not vouched for gets a notice once.
#
# shellcheck source-path=SCRIPTDIR

set -u

hooks=$(dirname -- "$0")
# shellcheck source=lib.sh
. "$hooks/lib.sh"

# fingerprint prints a sum of the work tree in the current directory as git sees it: HEAD, the
# diff from it, and the names and contents of the files git neither tracks nor ignores.
fingerprint() {
    {
        git rev-parse HEAD
        git diff --binary --no-ext-diff --no-textconv HEAD --
        git ls-files -z --others --exclude-standard
        git ls-files -z --others --exclude-standard | xargs -0 git hash-object --
    } 2>/dev/null | git hash-object --stdin
}

# start notes the fingerprint of the project's work tree, $top, where its makefiles name a lint
# target. It drops the state of sessions untouched for 30 days, as no hook runs as one ends.
start() {
    if ! cd -- "$top" || ! mentions || ! mkdir -p -- "$state"; then
        return 0
    fi
    fingerprint >"$state/start"
    find "${state%/*}/." ! -name . -prune -type d -mtime +30 -exec rm -rf -- {} +
}

# lint runs make lint-tree in the work tree $1, where it is one of the project's repository, not
# HEAD at origin/main with nothing changed, and vouched for. A failure goes to $tmp/report, and a
# notice to $tmp/notes. stdin is /dev/null and the output a file, as some tools refuse handles
# that do not block.
lint() {
    if ! plain "$1" || [ ! -d "$1" ] || [ "$(common "$1")" != "$repo" ] || ! cd -- "$1"; then
        return 0
    fi
    if [ "$(git rev-parse -q --verify HEAD)" = "$(git rev-parse -q --verify "$base")" ] &&
        [ -z "$(git status --porcelain --untracked-files=normal 2>/dev/null)" ]; then
        return 0
    fi
    mentions || return 0
    if ! why=$(vouch); then
        message="lint: no gate ran in $1, as $why."
        ! fresh "$message" || printf '%s\n' "$message" >>"$tmp/notes"
        return 0
    fi
    has lint-tree || return 0
    if ! make -k -C "$1" --no-print-directory lint-tree BASE="$base" \
        </dev/null >"$tmp/out" 2>&1; then
        printf 'lint: make lint-tree BASE=%s fails in %s:\n' "$base" "$1" >>"$tmp/report"
        excerpt "$tmp/out" >>"$tmp/report"
    fi
}

main() {
    # stdin is read whole first, as the hook reads three of its fields.
    input=$(cat)
    project=${CLAUDE_PROJECT_DIR:-.}
    repo=$(common "$project")
    [ -n "$repo" ] || return 0
    top=$(git -C "$project" rev-parse --show-toplevel 2>/dev/null) && plain "$top" || top=
    state=$(statedir "$(field session_id)") || return 0
    case $(field hook_event_name) in
    SessionStart)
        [ -z "$top" ] || start
        return 0
        ;;
    Stop) ;;
    *) return 0 ;;
    esac
    # Claude stops again after this hook's failure. The record stays for the next turn's stop.
    ! flag stop_hook_active || return 0
    [ -f "$state/trees" ] || [ -f "$state/start" ] || return 0

    tmp=$(mktemp -d) || return 0
    trap 'rm -rf "$tmp"' EXIT
    : >"$tmp/trees"
    : >"$tmp/report"
    : >"$tmp/notes"
    if [ -f "$state/trees" ]; then
        mv -f -- "$state/trees" "$tmp/trees" || return 0
    fi
    if [ -n "$top" ] && [ -f "$state/start" ] && cd -- "$top"; then
        now=$(fingerprint)
        if [ "$now" != "$(cat -- "$state/start")" ] &&
            [ "$now" != "$(cat -- "$state/checked" 2>/dev/null)" ]; then
            printf '%s\n' "$top" >>"$tmp/trees"
        fi
        printf '%s\n' "$now" >"$state/checked"
    fi
    sort -u "$tmp/trees" | while IFS= read -r tree; do
        lint "$tree" </dev/null
    done

    if [ -s "$tmp/report" ]; then
        cat "$tmp/notes" "$tmp/report" >&2
        {
            echo 'lint: fix what this session broke. Report a failure from before it, such as'
            echo "an older commit's message or the maintainer's own edits, rather than fix it."
        } >&2
        return 2
    fi
    [ ! -s "$tmp/notes" ] || notice "$(paste -s -d ' ' "$tmp/notes")"
}

main "$@"
