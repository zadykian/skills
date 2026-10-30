# shellcheck shell=bash
# The cases of tools/layoutcheck, in work, a marketplace of two bundles: a, of the skill x, and b,
# of the skill y and the agent z, under b's own path. Each case changes it, and checks the
# findings on it.

# start makes work, whose components each hold the frontmatter that claude needs to load them.
start() {
    mkdir -p "$FAKE/work/.claude-plugin" "$FAKE/work/skills/x" "$FAKE/work/skills/y" \
        "$FAKE/work/b/agents"
    cd "$FAKE/work" || return
    component skills/x/SKILL.md x
    component skills/y/SKILL.md y
    component b/agents/z.md z
    jq -n '{name: "m", owner: {name: "o"}, plugins: [
        {name: "a", source: "./", strict: false, skills: ["./skills/x"]},
        {name: "b", source: "./", strict: false, skills: ["./skills/y"],
        agents: ["./b/agents/z.md"]}]}' >.claude-plugin/marketplace.json
}

# component writes the file $1, a skill's or an agent's, named $2.
component() {
    mkdir -p "$(dirname "$1")"
    printf -- '---\nname: %s\ndescription: The %s of a case.\n---\n\nA case.\n' "$2" "$2" >"$1"
}

# finds checks that tools/layoutcheck fails work, with each finding after it.
finds() {
    step "$ROOT/tools/layoutcheck" "$FAKE/work"
    exits 1
    local finding
    for finding; do prints "$finding"; done
}

setup 'layoutcheck: each bundle loads what its entry lists'
start
step "$ROOT/tools/layoutcheck" "$FAKE/work"
exits 0

setup 'layoutcheck: a root agents/ reaches every bundle'
start
component agents/leak.md leak
finds 'agents: every bundle loads it from the root'

setup 'layoutcheck: a root workflow reaches every bundle'
start
mkdir workflows
printf '%s\n' "export const meta = { name: 'leak', description: 'A case' }" 'return 1' \
    >workflows/leak.js
finds 'workflows: every bundle loads it from the root'

setup 'layoutcheck: a root hooks/hooks.json runs for every bundle'
start
mkdir hooks
echo '{"hooks": {}}' >hooks/hooks.json
finds "hooks/hooks.json: it runs for every bundle; write each bundle's hooks inline"

setup 'layoutcheck: no marketplace, nothing to check'
mkdir -p "$FAKE/work"
step "$ROOT/tools/layoutcheck" "$FAKE/work"
exits 0
