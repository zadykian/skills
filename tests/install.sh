# shellcheck shell=bash
# The cases of tools/install, in work, a repository. claude is the fake in $FAKE/claude, and git
# the fake in $FAKE/bin. claude logs each call to $FAKE/calls. It answers plugin list with the
# JSON of $FAKE/plugins, and plugin marketplace list with zadykian, whose copy, $FAKE/market,
# lists the bundles a, b and c, where $FAKE/added is there. marketplace add makes that file, and an
# install of an ID in $FAKE/refused fails. git ls-remote lists the tags of $FAKE/tags.

# start makes work and the fakes, with no plugin installed and the marketplace added.
start() {
    mkdir -p "$FAKE/work" "$FAKE/bin" "$FAKE/market/.claude-plugin"
    cd "$FAKE/work" || return
    jq -n '{plugins: [{name: "a"}, {name: "b"}, {name: "c"}]}' \
        >"$FAKE/market/.claude-plugin/marketplace.json"
    echo '[]' >"$FAKE/plugins"
    : >"$FAKE/calls"
    : >"$FAKE/refused"
    : >"$FAKE/tags"
    touch "$FAKE/added"
    cat >"$FAKE/claude" <<'FAKE'
#!/bin/sh
echo "$*" >>"$FAKE/calls"
case "$*" in
'plugin list --json') cat "$FAKE/plugins" ;;
'plugin marketplace list --json')
    if [ -f "$FAKE/added" ]; then
        jq -n --arg dir "$FAKE/market" '[{name: "zadykian", installLocation: $dir}]'
    else echo '[]'; fi ;;
'plugin marketplace update zadykian') ;;
"plugin marketplace add $4") touch "$FAKE/added" ;;
"plugin install $3 --scope $5 --json")
    ! grep -qxF "$3" "$FAKE/refused" || { echo '{"message": "no such plugin"}'; exit 1; }
    echo '{"outcome": "ok"}' ;;
*) exit 2 ;;
esac
FAKE
    cat >"$FAKE/bin/git" <<'FAKE'
#!/bin/sh
[ "$1" != ls-remote ] || cat "$FAKE/tags"
FAKE
    chmod +x "$FAKE/claude" "$FAKE/bin/git"
}

# install runs tools/install in work with the arguments.
install() {
    step CLAUDE="$FAKE/claude" PATH="$FAKE/bin:$PATH" "$ROOT/tools/install" "$@"
}

# called checks that claude was called with each of the argument lists, and no other install.
called() {
    local call
    for call; do
        grep -qxF -- "$call" "$FAKE/calls" || fail "no call '$call': $(cat "$FAKE/calls")"
    done
    local made wanted
    made=$(grep -c '^plugin install ' "$FAKE/calls") || true
    wanted=$(printf '%s\n' "$@" | grep -c '^plugin install ') || true
    [ "$made" = "$wanted" ] || fail "$made installs, not $wanted: $(cat "$FAKE/calls")"
}

setup installs-at-user-scope-each-bundle-it-lacks
start
jq -n --arg here "$(pwd -P)" '[{id: "a@zadykian", scope: "user"},
    {id: "b@zadykian", scope: "project", projectPath: $here}]' >"$FAKE/plugins"
install
exits 0
called 'plugin marketplace update zadykian' 'plugin install b@zadykian --scope user --json' \
    'plugin install c@zadykian --scope user --json'
prints 'b@zadykian'

setup installs-at-project-scope-each-bundle-this-directory-lacks
start
jq -n --arg here "$(pwd -P)" '[{id: "a@zadykian", scope: "user"},
    {id: "b@zadykian", scope: "project", projectPath: $here},
    {id: "c@zadykian", scope: "project", projectPath: "/elsewhere"}]' >"$FAKE/plugins"
install --scope project
exits 0
called 'plugin install a@zadykian --scope project --json' \
    'plugin install c@zadykian --scope project --json'

setup adds-the-marketplace-at-the-last-release
start
rm "$FAKE/added"
printf '%s\trefs/tags/%s\n' 1 v1.2.0 2 v1.10.0 3 v2.0.0-rc.1 4 x >"$FAKE/tags"
install --scope=user
exits 0
called 'plugin marketplace add zadykian/toolkit@v1.10.0' \
    'plugin install a@zadykian --scope user --json' \
    'plugin install b@zadykian --scope user --json' \
    'plugin install c@zadykian --scope user --json'

setup fails-where-no-release-is-found
start
rm "$FAKE/added"
install
exits 1
prints 'no release of zadykian/toolkit found'
called

setup notes-that-each-bundle-is-installed-already
start
jq -n '[{id: "a@zadykian", scope: "user"}, {id: "b@zadykian", scope: "user"},
    {id: "c@zadykian", scope: "user"}]' >"$FAKE/plugins"
install
exits 0
prints 'each bundle of zadykian is installed at user scope already'
called

setup goes-on-past-a-failed-install-and-fails
start
echo b@zadykian >"$FAKE/refused"
install
exits 1
prints 'b@zadykian is not installed: no such plugin'
prints 'c@zadykian'
called 'plugin install a@zadykian --scope user --json' \
    'plugin install b@zadykian --scope user --json' \
    'plugin install c@zadykian --scope user --json'

setup refuses-a-scope-it-does-not-know
start
install --scope local
exits 1
prints 'the scope is user or project, not local'
install --scope
exits 1
prints '--scope needs user or project'
called

setup runs-piped-to-sh
start
step CLAUDE="$FAKE/claude" PATH="$FAKE/bin:$PATH" \
    sh -c "sh -s -- --scope project <'$ROOT/tools/install'"
exits 0
called 'plugin install a@zadykian --scope project --json' \
    'plugin install b@zadykian --scope project --json' \
    'plugin install c@zadykian --scope project --json'
