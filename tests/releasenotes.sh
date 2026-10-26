# shellcheck shell=bash
# The cases of tools/releasenotes, in work, a repository whose first commit is chore: start. A
# release is a lightweight tag, as gh release create makes it.

# start starts work, with the commit chore: start.
start() {
    git init -q -b main "$FAKE/work"
    cd "$FAKE/work" || return
    commit 'chore: start'
}

# commit commits the header $1, with the body $2 where given, and no change.
commit() {
    local message=(-m "$1")
    [ -z "${2-}" ] || message+=(-m "$2")
    git commit -q --allow-empty "${message[@]}"
}

# notes checks that tools/releasenotes prints the notes $1, each commit's SHA left out, and HEAD's
# line with its SHA.
notes() {
    step "$ROOT/tools/releasenotes"
    exits 0
    prints "- $(git log -1 --format=%s) ($(git rev-parse --short HEAD))"
    [ "$(sed -E 's/ \([0-9a-f]{7,}\)$//' "$FAKE/out")" = "$1" ] ||
        fail "the notes: $(cat "$FAKE/out")"
}

setup lists-every-commit-before-the-first-release
start
commit 'feat: add it'
notes '- chore: start
- feat: add it'

setup ignores-a-tag-of-no-release
start
commit 'feat: add t'
git tag v1.9.0
commit 'feat: add it'
git tag v1.10.0
commit 'fix: mend it'
git tag v2.0.0-rc.1
git tag 2.0.0
git switch -qc side
commit 'feat!: drop it'
git tag v3.0.0
git switch -q main
commit 'docs: describe it'
notes '- fix: mend it
- docs: describe it'
