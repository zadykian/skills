# shellcheck shell=bash
# The cases of tools/install, in work, a repository whose settings enable bundles of the
# marketplace m. claude is the fake in $FAKE/claude: it answers plugin list and plugin marketplace
# list with the JSON of $FAKE/plugins and $FAKE/marketplaces, logs each install to $FAKE/installs,
# and fails one whose ID is in $FAKE/refused.

# start makes work, whose settings.json enables a@m, b@m and c@m, and turns d@m off, and the fake
# claude, which knows m and has no plugin installed.
start() {
    mkdir -p "$FAKE/work/.claude"
    cd "$FAKE/work" || return
    jq -n '{enabledPlugins: {"a@m": true, "b@m": true, "c@m": true, "d@m": false}}' \
        >.claude/settings.json
    echo '[]' >"$FAKE/plugins"
    echo '[{"name": "m"}]' >"$FAKE/marketplaces"
    : >"$FAKE/installs"
    : >"$FAKE/refused"
    cat >"$FAKE/claude" <<'FAKE'
#!/bin/sh
case "$*" in
'plugin list --json') cat "$FAKE/plugins" ;;
'plugin marketplace list --json') cat "$FAKE/marketplaces" ;;
"plugin install $3 --scope project --json")
    echo "$3" >>"$FAKE/installs"
    ! grep -qxF "$3" "$FAKE/refused" || { echo '{"message": "no such plugin"}'; exit 1; }
    echo '{"outcome": "ok"}' ;;
*) exit 2 ;;
esac
FAKE
    chmod +x "$FAKE/claude"
}

# install runs tools/install in work, as the hook runs it.
install() {
    step CLAUDE="$FAKE/claude" CLAUDE_PROJECT_DIR="$FAKE/work" "$ROOT/tools/install"
    exits 0
}

# installs checks that tools/install installed the IDs after it, and no other.
installs() {
    [ "$(cat "$FAKE/installs")" = "$(printf '%s\n' "$@")" ] ||
        fail "installed $(tr '\n' ' ' <"$FAKE/installs"), not $*"
}

# silent checks that the last step printed nothing.
silent() {
    [ ! -s "$FAKE/out" ] || fail "printed $(cat "$FAKE/out")"
}

setup installs-each-enabled-bundle-that-does-not-load-here
start
jq -n --arg here "$(pwd -P)" '[{id: "a@m", scope: "project", projectPath: "/elsewhere"},
    {id: "b@m", scope: "user"}, {id: "c@m", scope: "project", projectPath: $here}]' \
    >"$FAKE/plugins"
install
installs a@m
prints '{"systemMessage":"tools/install: installed a@m at project scope: run /reload-plugins'

setup prints-nothing-where-each-bundle-loads
start
jq -n '[{id: "a@m", scope: "user"}, {id: "b@m", scope: "user"}, {id: "c@m", scope: "user"}]' \
    >"$FAKE/plugins"
install
installs
silent

setup leaves-out-a-bundle-that-the-local-settings-turn-off
start
jq -n '{enabledPlugins: {"b@m": false}}' >.claude/settings.local.json
install
installs a@m c@m
prints 'installed a@m c@m at project scope'

setup waits-for-a-marketplace-not-fetched
start
echo '[]' >"$FAKE/marketplaces"
install
installs
prints 'a@m b@m c@m: their marketplace is not fetched yet, so the next session installs them.'

setup reports-a-failed-install-and-goes-on
start
echo b@m >"$FAKE/refused"
install
installs a@m b@m c@m
prints 'installed a@m c@m at project scope'
prints 'could not install b@m (no such plugin).'

setup reports-a-failed-plugin-list
start
printf '#!/bin/sh\nexit 1\n' >"$FAKE/claude"
install
installs
prints 'claude plugin list failed, so no bundle is installed'

setup reports-settings-that-are-not-json
start
echo '{' >.claude/settings.json
install
installs
prints 'is not valid JSON, so no bundle is installed'

setup prints-nothing-where-settings-enable-no-bundle
start
echo '{}' >.claude/settings.json
install
installs
silent
