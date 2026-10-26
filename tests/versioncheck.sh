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

# commit commits the header $1, and no change.
commit() {
    git commit -q --allow-empty -m "$1"
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
