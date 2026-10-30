#!/bin/sh
# The lean plugin's PreToolUse hook for the Workflow tool (docs/lean.md): denies a script that
# calls agent() with options naming none of agentType, model and effort, as such an agent takes
# the session's model. The reason names the accepted forms. The script comes from the tool's
# `script`, or from the file at `scriptPath`; a saved workflow, by `name`, has none to read. The
# hook fails open: with no jq, input it cannot parse, or a file it cannot read, it allows.

set -u

# offenders prints the lines, comma-separated, of the agent( calls in the script on stdin whose
# code, with its strings and comments left out, holds none of the three keys. It reads a call
# up to its closing parenthesis, and a call inside a call apart. It allows a call whose options
# are no object literal, or spread one in, as the keys may be there.
offenders() {
    awk '
    function start(lineno) { n++; at[n] = depth; ln[n] = lineno; buf[n] = " " }
    function add(c, j) { for (j = 1; j <= n; j++) buf[j] = buf[j] c }
    # opaque: the options, the second argument, are no object literal, or spread one in, so the
    # script may hold the keys there.
    function opaque(s,    k, c, nest, rest) {
        for (k = 1; k <= length(s); k++) {
            c = substr(s, k, 1)
            if (c ~ /[([{]/) nest++
            else if (c ~ /[)\]}]/) nest--
            else if (c == "," && nest == 0) break
        }
        rest = substr(s, k + 1)
        sub(/^[ \t\n]+/, "", rest)
        if (k > length(s) || rest ~ /^\)/) return 0
        return rest !~ /^\{/ || rest ~ /\.\.\./
    }
    function finish() {
        if (!opaque(buf[n]) && buf[n] !~ /[^A-Za-z0-9_$](agentType|model|effort)[^A-Za-z0-9_$]/)
            out = out (out == "" ? "" : ",") ln[n]
        n--
    }
    {
        if (quote != "`") quote = ""
        len = length($0)
        for (i = 1; i <= len; i++) {
            c = substr($0, i, 1)
            if (block) { if (substr($0, i, 2) == "*/") { block = 0; i++ } continue }
            if (quote != "") {
                if (c == "\\") i++
                else if (c == quote) quote = ""
                continue
            }
            if (c == "\"" || c == "\047" || c == "`") { quote = c; add(" "); continue }
            if (substr($0, i, 2) == "//") break
            if (substr($0, i, 2) == "/*") { block = 1; i++; continue }
            if (substr($0, i, 6) == "agent(" && substr(" " $0, i, 1) !~ /[A-Za-z0-9_$]/) {
                depth++; start(NR); i += 5; continue
            }
            if (c == "(") depth++
            if (c == ")") { depth--; if (n > 0 && depth < at[n]) finish() }
            add(c)
        }
        add("\n")
    }
    END { print out }'
}

main() {
    command -v jq >/dev/null 2>&1 || return 0
    input=$(cat)
    script=$(printf '%s\n' "$input" | jq -r '.tool_input.script // empty' 2>/dev/null) || return 0
    if [ -z "$script" ]; then
        file=$(printf '%s\n' "$input" | jq -r '.tool_input.scriptPath // empty' 2>/dev/null) ||
            return 0
        [ -f "$file" ] && [ -r "$file" ] || return 0
        script=$(cat -- "$file") || return 0
    fi
    lines=$(printf '%s\n' "$script" | offenders)
    [ -n "$lines" ] || return 0
    printf '{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny", '
    printf '"permissionDecisionReason": "lean: agent() at line %s of the workflow script names ' \
        "$lines"
    printf "no agentType, model or effort, so it runs on the session model. Give it a role's "
    printf "agent, as agentType: 'lean:checker', or set model with effort.\"}}\n"
}

main
