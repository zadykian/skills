#!/bin/sh
# The lean plugin's PreToolUse hook for the Bash tool (docs/lean.md): denies a foreground command
# that polls, as a loop with sleep, a watch, `gh run watch` or a --watch flag, unless a `timeout`
# of 240 s or less bounds it. The reason names the accepted forms. The test of a poll is the one
# in skills/cost/rows.jq. The hook fails open: with no jq, or input it cannot parse, it allows.

set -u

# polls prints "yes" for the Bash input on stdin that holds an unbounded foreground poll. A line
# break counts as a semicolon, and a tool `timeout`, in ms, bounds the call as `timeout N` does.
polls() {
    jq -r '
        def poll:
          test("\\b(until|while)\\b.*\\bsleep\\b|(^|[;&|(])\\s*watch\\s|\\bgh run watch\\b|--watch\\b");
        .tool_input | select(.run_in_background != true) |
        (.command // "" | gsub("\n"; ";")) as $c | select($c | poll) |
        select(([$c | scan("\\btimeout\\s+([0-9]+)s?\\b")[0] | tonumber] | any(. <= 240)) | not) |
        select((.timeout // 1e9) > 240000) | "yes"' 2>/dev/null
}

main() {
    command -v jq >/dev/null 2>&1 || return 0
    [ "$(polls)" = yes ] || return 0
    printf '{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny", '
    printf '"permissionDecisionReason": "lean: a foreground poll with no bound holds the turn and '
    printf "the cache. Run it with run_in_background: true, or as a \`Monitor\` that prints on a "
    printf "change of state, or bound it with \`timeout 240\`.\"}}\n"
}

main
