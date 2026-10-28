# shellcheck shell=bash
# The cases of tools/pin, which pins app to a release of toolkit. app uses toolkit's actions as the
# repositories that use them lay them out. old keeps app's files from before the case's first run.

# start makes toolkit, of the actions x and y, its commit SHA tagged v1.2.3, and app's workflow, of
# x, y and checkout.
start() {
    git init -q -b main "$FAKE/toolkit"
    mkdir -p "$FAKE/toolkit/tools" "$FAKE/toolkit/actions/x" "$FAKE/toolkit/actions/y"
    cp "$ROOT/tools/pin" "$FAKE/toolkit/tools"
    touch "$FAKE/toolkit/actions/x/action.yml" "$FAKE/toolkit/actions/y/action.yml"
    git -C "$FAKE/toolkit" add .
    git -C "$FAKE/toolkit" commit -q -m 'feat: add tools/pin'
    git -C "$FAKE/toolkit" tag -a v1.2.3 -m v1.2.3
    SHA=$(git -C "$FAKE/toolkit" rev-parse HEAD)
    mkdir -p "$FAKE/app/.github/workflows"
    cat >"$FAKE/app/.github/workflows/rules.yml" <<'EOF'
jobs:
  rules:
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
      - uses: zadykian/actions/x@9c02fe599a7f620e98cd3d89ba9a0858e2f8b147 # v2.0.0
      - name: y
        uses: zadykian/toolkit/actions/y@v1.0.0
EOF
}

# settings makes app's settings.json, whose marketplace zadykian has the source $1.
settings() {
    mkdir -p "$FAKE/app/.claude"
    cat >"$FAKE/app/.claude/settings.json" <<EOF
{
  "extraKnownMarketplaces": {
    "other": {
      "source": { "source": "github", "repo": "o/plugins", "ref": "v9.0.0" }
    },
    "zadykian": {
$1
      "autoUpdate": true
    }
  }
}
EOF
}

# templates gives toolkit the templates, each of a text of its own, in a commit tagged $1.
templates() {
    mkdir -p "$FAKE/toolkit/skills/atomic-commits" "$FAKE/toolkit/skills/issue"
    echo '## Problem' >"$FAKE/toolkit/skills/atomic-commits/pull_request_template.md"
    echo 'name: Change' >"$FAKE/toolkit/skills/issue/change.yml"
    echo 'blank_issues_enabled: false' >"$FAKE/toolkit/skills/issue/config.yml"
    git -C "$FAKE/toolkit" add skills
    git -C "$FAKE/toolkit" commit -q -m 'feat: add the templates'
    git -C "$FAKE/toolkit" tag "$1"
}

# copied checks that app holds each template at its path, as toolkit's tree holds it.
copied() {
    local source path
    while read -r source path; do
        cmp -s "$FAKE/toolkit/$source" "$FAKE/app/$path" || fail "$path is not toolkit's $source"
    done <<'EOF'
skills/atomic-commits/pull_request_template.md .github/pull_request_template.md
skills/issue/change.yml .github/ISSUE_TEMPLATE/change.yml
skills/issue/config.yml .github/ISSUE_TEMPLATE/config.yml
EOF
}

# pin runs toolkit's tools/pin at the version $1 on app, and keeps app in old on the first run.
pin() {
    [ -d "$FAKE/old" ] || cp -R "$FAKE/app" "$FAKE/old"
    step "$FAKE/toolkit/tools/pin" "$1" "$FAKE/app"
}

# piped runs tools/pin as sh runs it from a pipe, at the version $1 on app: it clones toolkit.
piped() {
    [ -d "$FAKE/old" ] || cp -R "$FAKE/app" "$FAKE/old"
    # The inner sh expands $0, $1 and $2: the script, the version and app.
    # shellcheck disable=SC2016
    step TOOLKIT_URL="file://$FAKE/toolkit" sh -c 'sh -s -- "$1" "$2" <"$0"' "$ROOT/tools/pin" \
        "$1" "$FAKE/app"
}

# changes checks that app's file $1 differs from old's as the diff on stdin says.
changes() {
    local got
    got=$(cd "$FAKE" && diff "old/$1" "app/$1") || true
    [ "$got" = "$(cat)" ] || fail "$1 changed as: $got"
}

# pinned checks that app's workflow uses x and y at the commit $1, the tag $2.
pinned() {
    changes .github/workflows/rules.yml <<EOF
5c5
<       - uses: zadykian/actions/x@9c02fe599a7f620e98cd3d89ba9a0858e2f8b147 # v2.0.0
---
>       - uses: zadykian/toolkit/actions/x@$1 # $2
7c7
<         uses: zadykian/toolkit/actions/y@v1.0.0
---
>         uses: zadykian/toolkit/actions/y@$1 # $2
EOF
}

# sourced checks that app's settings.json gives its source of lines the ref $1.
sourced() {
    changes .claude/settings.json <<EOF
9c9,10
<         "repo": "zadykian/skills"
---
>         "repo": "zadykian/toolkit",
>         "ref": "$1"
EOF
}

setup pins-the-workflows-once
start
pin v1.2.3
exits 0
prints ".github/workflows/rules.yml:5: - uses: zadykian/toolkit/actions/x@$SHA # v1.2.3"
prints 'no .claude/settings.json, so the workflows alone are pinned'
pin v1.2.3
exits 0
prints "$FAKE/app pins v1.2.3 already"
pinned "$SHA" v1.2.3

setup refuses-a-version-it-cannot-resolve
start
pin 1.2.3
exits 1
prints '1.2.3 is not of the form vX.Y.Z'
pin v1.2.4
exits 1
prints 'no tag v1.2.4 in'
prints 'git fetch --tags'

setup pins-a-source-of-one-line-once
start
settings '      "source": { "source": "github", "repo": "zadykian/skills" },'
pin v1.2.3
pin v1.2.3
exits 0
prints 'pins v1.2.3 already'
changes .claude/settings.json <<'EOF'
7c7
<       "source": { "source": "github", "repo": "zadykian/skills" },
---
>       "source": { "source": "github", "repo": "zadykian/toolkit", "ref": "v1.2.3" },
EOF

setup refuses-settings-without-the-toolkit-and-writes-nothing
start
settings '      "source": { "source": "github", "repo": "o/skills" },'
pin v1.2.3
exits 1
prints 'names 0 marketplaces of zadykian/toolkit or zadykian/skills, not one'
changes .github/workflows/rules.yml </dev/null

setup refuses-an-action-the-release-lacks-and-writes-nothing
start
git -C "$FAKE/toolkit" rm -rq actions/y
git -C "$FAKE/toolkit" commit -q -m 'feat(y)!: remove the y action'
git -C "$FAKE/toolkit" tag v2.0.0
pin v2.0.0
exits 1
prints '.github/workflows/rules.yml:7: v2.0.0 has no action y: remove the step, as the release'
changes .github/workflows/rules.yml </dev/null

setup gives-the-ref-a-line-of-its-own-in-a-source-of-lines
start
settings '      "source": {
        "source": "github",
        "repo": "zadykian/skills"
      },'
pin v1.2.3
exits 0
prints '.claude/settings.json:10: "ref": "v1.2.3"'
sourced v1.2.3
git -C "$FAKE/toolkit" commit -q --allow-empty -m 'fix: mend it'
git -C "$FAKE/toolkit" tag v1.3.0
SHA=$(git -C "$FAKE/toolkit" rev-parse HEAD)
pin v1.3.0
exits 0
pinned "$SHA" v1.3.0
sourced v1.3.0

setup writes-the-templates-of-a-tag
start
templates v1.3.0
pin v1.3.0
exits 0
prints '.github/pull_request_template.md:1: v1.3.0:skills/atomic-commits/pull_request_template.md'
prints '.github/ISSUE_TEMPLATE/change.yml:1: v1.3.0:skills/issue/change.yml'
prints '.github/ISSUE_TEMPLATE/config.yml:1: v1.3.0:skills/issue/config.yml'
copied

setup writes-the-templates-once
start
templates v1.3.0
pin v1.3.0
pin v1.3.0
exits 0
prints "$FAKE/app pins v1.3.0 already"
copied

setup writes-no-template-that-the-tag-lacks
start
echo '## Mine' >"$FAKE/app/.github/pull_request_template.md"
pin v1.2.3
exits 0
changes .github/pull_request_template.md </dev/null
[ ! -e "$FAKE/app/.github/ISSUE_TEMPLATE" ] || fail 'it wrote .github/ISSUE_TEMPLATE'

setup overwrites-a-template-of-other-text
start
templates v1.3.0
echo '## Mine' >"$FAKE/app/.github/pull_request_template.md"
pin v1.3.0
exits 0
prints '.github/pull_request_template.md:1: v1.3.0:skills/atomic-commits/pull_request_template.md'
changes .github/pull_request_template.md <<'EOF'
1c1
< ## Mine
---
> ## Problem
EOF

setup writes-no-template-where-a-check-fails
start
git -C "$FAKE/toolkit" rm -rq actions/y
templates v2.0.0
pin v2.0.0
exits 1
prints 'v2.0.0 has no action y'
diff -r "$FAKE/old" "$FAKE/app" || fail 'it wrote a file'

setup creates-the-directories-of-the-templates
start
rm -r "$FAKE/app/.github"
settings '      "source": { "source": "github", "repo": "zadykian/toolkit" },'
templates v1.3.0
pin v1.3.0
exits 0
copied

setup pins-from-a-pipe-by-a-clone-of-the-tag
start
settings '      "source": { "source": "github", "repo": "zadykian/toolkit" },'
templates v1.3.0
piped v1.3.0
exits 0
prints '.claude/settings.json:7: "source": { "source": "github", "repo": "zadykian/toolkit", "ref": "v1.3.0" },'
prints '.github/ISSUE_TEMPLATE/change.yml:1: v1.3.0:skills/issue/change.yml'
copied

setup refuses-from-a-pipe-a-tag-it-cannot-clone
start
piped v9.9.9
exits 1
prints "no tag v9.9.9 in file://$FAKE/toolkit"
diff -r "$FAKE/old" "$FAKE/app" || fail 'it wrote a file'
