# shellcheck shell=bash
# The cases of tools/install, in work, a repository. claude is the fake in $FAKE/claude, which
# logs each call to $FAKE/calls. It answers plugin list with the
# JSON of $FAKE/plugins, and plugin marketplace list with zadykian, whose copy, $FAKE/market,
# lists the bundles a, b and c, where $FAKE/added is there. An install of an ID in $FAKE/refused
# fails.

# start makes work and the fakes, with no plugin installed and the marketplace added.
start() {
    mkdir -p "$FAKE/work" "$FAKE/market/.claude-plugin"
    cd "$FAKE/work" || return
    jq -n '{plugins: [{name: "a"}, {name: "b"}, {name: "c"}]}' \
        >"$FAKE/market/.claude-plugin/marketplace.json"
    echo '[]' >"$FAKE/plugins"
    : >"$FAKE/calls"
    : >"$FAKE/refused"
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
"plugin install $3 --scope $5 --json")
    ! grep -qxF "$3" "$FAKE/refused" || { echo '{"message": "no such plugin"}'; exit 1; }
    echo '{"outcome": "ok"}' ;;
*) exit 2 ;;
esac
FAKE
    chmod +x "$FAKE/claude"
}

# install runs tools/install in work with the arguments.
install() {
    step CLAUDE="$FAKE/claude" "$ROOT/tools/install" "$@"
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

setup fails-without-the-marketplace
start
rm "$FAKE/added"
install
exits 1
prints 'claude plugin marketplace add zadykian/toolkit'
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

setup refuses-an-argument
start
install --scope user
exits 1
prints 'usage: tools/install'
called
