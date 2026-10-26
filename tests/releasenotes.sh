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

setup writes-each-section-oldest-first
start
git tag v1.2.3
commit 'feat(x)!: drop the old input'
commit 'refactor: move y' 'BREAKING CHANGE: y moved to z.'
commit 'feat(x): add z'
commit 'fix(x): mend w'
commit 'docs: describe v' 'It quotes feat!: and a BREAKING CHANGE: footer.'
notes '## Breaking changes

- feat(x)!: drop the old input
- refactor: move y

  y moved to z.

## Features

- feat(x): add z

## Fixes

- fix(x): mend w

## Other changes

- docs: describe v'

setup gives-the-text-of-a-breaking-footer
start
git tag v1.2.3
commit 'refactor!: move it' "$(printf '%s\n' 'It moves.' '' \
    'BREAKING CHANGE: it moved to y, and its' 'input to z.' 'Refs: #1')"
commit 'docs: note it' "$(printf '%s\n' 'BREAKING-CHANGE: x is gone.' 'Note: it stays.' '' \
    'BREAKING CHANGE: Note: w is gone.' '' 'Co-Authored-By: a <a@example.com>')"
notes '## Breaking changes

- refactor!: move it

  it moved to y, and its
  input to z.
- docs: note it

  x is gone.

  Note: w is gone.'

setup lists-every-commit-before-the-first-release
start
commit 'feat: add it'
notes '## Features

- feat: add it

## Other changes

- chore: start'

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
notes '## Fixes

- fix: mend it

## Other changes

- docs: describe it'
