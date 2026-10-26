# shellcheck shell=bash
# The cases of tools/pin, which pins app to a release of toolkit. app uses toolkit's actions as the
# repositories that use them lay them out. old keeps app's files from before the case's first run.

# start makes toolkit, its commit SHA tagged v1.2.3, and app's workflow, of x, y and checkout.
start() {
    git init -q -b main "$FAKE/toolkit"
    mkdir "$FAKE/toolkit/tools"
    cp "$ROOT/tools/pin" "$FAKE/toolkit/tools"
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

# pin runs toolkit's tools/pin at the version $1 on app, and keeps app in old on the first run.
pin() {
    [ -d "$FAKE/old" ] || cp -R "$FAKE/app" "$FAKE/old"
    step "$FAKE/toolkit/tools/pin" "$1" "$FAKE/app"
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

setup pins-the-workflows-once
start
pin v1.2.3
exits 0
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
