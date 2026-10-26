# shellcheck shell=bash
# The cases of tools/versioncheck, in work, a repository whose marketplace has one bundle, a, of
# the skill x. Each case changes the work tree, and checks the findings on it. A release is a
# lightweight tag, as gh release create makes it.

# start starts work, with the marketplace of the version $1 in its first commit.
start() {
    git init -q -b main "$FAKE/work"
    cd "$FAKE/work" || return
    mkdir -p skills/x
    : >skills/x/SKILL.md
    catalog "$1"
    git add .
    git commit -q -m 'chore: start'
}

# commit commits the header $1, with the body $2 where given, and no change.
commit() {
    local message=(-m "$1")
    [ -z "${2-}" ] || message+=(-m "$2")
    git commit -q --allow-empty "${message[@]}"
}

# catalog writes the marketplace of the version $1, whose bundle gives the version $2, $1 where
# omitted, and CHANGELOG.md's first heading for $1.
catalog() {
    mkdir -p .claude-plugin
    jq -n --arg version "$1" --arg bundle "${2:-$1}" '{metadata: {version: $version},
        plugins: [{name: "a", source: "./", strict: false, version: $bundle,
        skills: ["./skills/x"]}]}' >.claude-plugin/marketplace.json
    printf '## %s\n' "$1" >CHANGELOG.md
}

# passes checks that tools/versioncheck passes the work tree.
passes() {
    step "$ROOT/tools/versioncheck"
    exits 0
}

# finds checks that tools/versioncheck fails the work tree, with the finding $1.
finds() {
    step "$ROOT/tools/versioncheck"
    exits 1
    prints "$1"
}

# calls checks that the commits since the last release call for the version $1: the version $2
# fails with the finding $3, and $1 passes, which the work tree then gives.
calls() {
    catalog "$2"
    finds "$3"
    catalog "$1"
    passes
}

setup checks-the-bundles-and-their-skills
start 1.2.3
passes
catalog 1.2
finds "the marketplace's version, '1.2', is not of the form X.Y.Z"
catalog 1.2.3 1.2.4
finds "a: its version is not the marketplace's, 1.2.3"
catalog 1.2.3
printf '## 1.2.2\n' >CHANGELOG.md
finds "CHANGELOG.md's first heading is not ## 1.2.3"
catalog 1.2.3
mkdir skills/y
: >skills/y/SKILL.md
finds 'y: no bundle lists it'
rm -r skills
finds 'x: listed, but skills/x/SKILL.md is missing'

setup keeps-the-version-of-unreleased-commits
start 1.2.3
git tag v1.2.3
commit 'feat!: drop it'
passes

setup refuses-a-version-below-the-last-release
start 1.9.0
git tag v1.9.0
commit 'feat: add it'
git tag v1.10.0
git tag v2.0.0-rc.1
git switch -qc side
commit 'feat!: drop it'
git tag v3.0.0
git switch -q main
catalog 1.9.1
finds 'the version 1.9.1 is below the last release, v1.10.0'
catalog 1.10.0
passes

setup takes-any-version-before-the-first-release
start 1.2.3
commit 'feat!: drop it'
catalog 0.1.0
passes

setup bumps-the-patch-for-the-rest
start 1.2.3
git tag v1.2.3
commit 'fix(x): mend it'
commit 'docs: describe it' 'It quotes feat!: and a BREAKING CHANGE: footer.'
calls 1.2.4 1.3.0 \
    'the version 1.3.0 is not the one the commits since v1.2.3 call for, 1.2.4: no commit is'

setup bumps-the-minor-for-a-feature
start 1.2.3
git tag v1.2.3
commit 'fix: mend it'
commit 'feat(x): add it'
calls 1.3.0 1.2.4 "1.3.0: $(git rev-parse --short HEAD) is a feature, and no commit is breaking"

setup bumps-the-major-for-a-header-s-bang
start 1.2.3
git tag v1.2.3
commit 'feat(x)!: drop it'
commit 'feat: add it'
calls 2.0.0 1.3.0 "call for, 2.0.0: $(git rev-parse --short HEAD~) is a breaking change"

setup bumps-the-major-for-a-footer
start 1.2.3
git tag v1.2.3
commit 'refactor: move it' 'BREAKING CHANGE: it moved.'
calls 2.0.0 1.3.0 "call for, 2.0.0: $(git rev-parse --short HEAD) is a breaking change"
git commit -qam 'chore: release 2.0.0'
git tag v2.0.0
commit 'fix: mend it'
calls 2.0.1 3.0.0 'since v2.0.0 call for, 2.0.1'
commit 'docs: note it' $'It changed.\n\nBREAKING-CHANGE: it changed.'
calls 3.0.0 2.0.2 'call for, 3.0.0'

setup bumps-the-minor-for-a-breaking-change-before-1.0
start 0.3.1
git tag v0.3.1
commit 'feat!: drop it'
calls 0.4.0 1.0.0 "0.4.0: $(git rev-parse --short HEAD) is a breaking change, before 1.0"
