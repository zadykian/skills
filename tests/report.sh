# shellcheck shell=bash
# The cases of lib/report.sh, through a check that sources it.

# probe runs a check.sh of the lines of stdin, between report_start probe and report_finish, with
# the VAR=VALUE arguments. It declares the rules a and b, and fails the case where the check exits
# non-zero.
probe() {
    {
        printf '#!/bin/bash\nset -euo pipefail\n. %q\nreport_start probe\n' "$ROOT/actions/lib/report.sh"
        printf "rule a 'Rule A' https://example.test/a 'Fix A.'\n"
        printf "rule b 'Rule B' https://example.test/b 'Fix B.'\n"
        cat
        printf 'report_finish\n'
    } >"$FAKE/check.sh"
    chmod +x "$FAKE/check.sh"
    step "$@" "$FAKE/check.sh"
    [ "$STATUS" = 0 ] || fail "the check exited with $STATUS: $(cat "$FAKE/out")"
}

setup annotates
probe <<'CHECK'
finding a 'The title says 100% done.' src/x.go 12
finding a 'Quoted: a, b.' 'a,b:c.txt'
finding a $'Two\r\nlines.'
CHECK
rule_a='The rule: https://example.test/a'
warns "::warning title=probe%3A Rule A,file=src/x.go,line=12::The title says 100%25 done.%0A$rule_a"
warns "::warning title=probe%3A Rule A,file=a%2Cb%3Ac.txt::Quoted: a, b.%0A$rule_a"
warns "::warning title=probe%3A Rule A::Two%0D%0Alines.%0A$rule_a"
warnings 3

setup annotates-ten-at-most
probe <<'CHECK'
for i in $(seq 12); do finding a "Finding $i."; done
CHECK
warnings 10
warns "::Finding 10.%0A$rule_a%0AThe job summary holds 2 more findings."
! grep -qF 'Finding 11.' "$FAKE/out" || fail "annotated the 11th finding"

setup summarizes
probe <<'CHECK'
finding a 'The title says 100% done.' src/x.go 12
finding a $'Two\nlines.'
CHECK
summarizes "### probe

This check warns and does not block the merge. It found 2 findings as of \`0123456\`.
"
summarizes "#### Rule A

The rule: https://example.test/a

- \`src/x.go:12\`: The title says 100% done.
- Two
  lines.

How to fix it:

Fix A."
! grep -qF 'Rule B' "$GITHUB_STEP_SUMMARY" || fail "the summary has a section for Rule B"

setup summarizes-a-clean-check
probe </dev/null
summarizes "merge. No findings remain as of \`0123456\`."
warnings 0

marker='<!-- zadykian/actions:probe -->'
# marked prints a page of the comments of the ids given, each of which the marker starts.
marked() {
    jq -nc --arg body "$marker"$'\nOld.' '[$ARGS.positional[] | {id: tonumber, body: $body}]' \
        --args "$@"
}
old=$(marked 5)
setup comments
probe <<<"finding a 'Found.'"
wrote POST repos/o/r/issues/1/comments "$marker
### probe"
writes 1

setup edits-the-comment
answer repos/o/r/issues/1/comments '[{"id": 4, "body": "Looks good."}]' "$old"
probe <<<"finding a 'Found.'"
wrote PATCH repos/o/r/issues/comments/5 '- Found.'
writes 1

setup edits-the-comment-to-clean
answer repos/o/r/issues/1/comments "$old"
probe </dev/null
wrote PATCH repos/o/r/issues/comments/5 "No findings remain as of \`0123456\`."
writes 1

setup leaves-the-oldest-comment
answer repos/o/r/issues/1/comments "$(marked 5 6)" "$(marked 7)"
probe <<<"finding a 'Found.'"
wrote PATCH repos/o/r/issues/comments/5 '- Found.'
wrote DELETE repos/o/r/issues/comments/6
wrote DELETE repos/o/r/issues/comments/7
writes 3

# Another run creates the comment 5 once this one has read the comments, and before its own.
setup moves-its-report-to-the-oldest
answer 'POST repos/o/r/issues/1/comments' '{"id": 9}'
later repos/o/r/issues/1/comments "$(marked 5 9)"
probe <<<"finding a 'Found.'"
wrote POST repos/o/r/issues/1/comments '- Found.'
wrote PATCH repos/o/r/issues/comments/5 '- Found.'
wrote DELETE repos/o/r/issues/comments/9
writes 3

setup keeps-its-comment-as-the-oldest
answer 'POST repos/o/r/issues/1/comments' '{"id": 5}'
later repos/o/r/issues/1/comments "$(marked 5 9)"
probe <<<"finding a 'Found.'"
wrote DELETE repos/o/r/issues/comments/9
writes 2

setup passes-over-a-comment-deleted-first
answer repos/o/r/issues/1/comments "$(marked 5 6)"
refuse DELETE repos/o/r/issues/comments/6 404
probe <<<"finding a 'Found.'"
wrote PATCH repos/o/r/issues/comments/5 '- Found.'
grep -qF -- '-X DELETE repos/o/r/issues/comments/6' "$FAKE/calls" || fail "deleted no comment 6"
warnings 1

setup comments-nothing-clean
probe </dev/null
writes 0

setup comments-nothing-when-told
probe COMMENT=false <<<"finding a 'Found.'"
writes 0
! grep -qF issues/1/comments "$FAKE/calls" || fail "read the comments"

setup warns-on-a-refused-comment
refuse POST repos/o/r/issues/1/comments
probe <<'CHECK'
for i in $(seq 12); do finding a "Finding $i."; done
CHECK
refused='could not comment on #1, so the job summary alone holds the report: Resource not'
warns "::warning::probe $refused accessible by integration (HTTP 403)"
warns "::Finding 9.%0A$rule_a%0AThe job summary holds 3 more findings."
warnings 10
summarizes '- Finding 12.'

setup warns-on-a-refused-delete
answer repos/o/r/issues/1/comments "$(marked 5 6)"
refuse DELETE repos/o/r/issues/comments/6
probe <<<"finding a 'Found.'"
warns "::warning::probe $refused accessible by integration (HTTP 403)"
warnings 2

# An issue's report, as the issues event sets ISSUE and leaves PR empty.
updated=2026-10-28T09:00:00Z
as_of="as of the issue's last update, \`$updated\`."
# probe_issue runs probe on the issue #1, last updated at $updated.
probe_issue() {
    answer repos/o/r/issues/1 "{\"number\": 1, \"updated_at\": \"$updated\"}"
    probe PR= ISSUE=1
}

setup comments-on-an-issue
probe_issue <<<"finding a 'Found.'"
wrote POST repos/o/r/issues/1/comments "$marker
### probe

This check warns and blocks nothing. It found 1 finding $as_of"
writes 1
! grep -qF pulls/1 "$FAKE/calls" || fail "read the pull request"

setup edits-the-comment-on-an-issue-to-clean
answer repos/o/r/issues/1/comments "$old"
probe_issue </dev/null
wrote PATCH repos/o/r/issues/comments/5 "warns and blocks nothing. No findings remain $as_of"
writes 1
warnings 0

setup comments-nothing-on-a-clean-issue
probe_issue </dev/null
summarizes "No findings remain $as_of"
writes 0

setup warns-on-a-refused-comment-on-an-issue
refuse POST repos/o/r/issues/1/comments
probe_issue <<<"finding a 'Found.'"
warns "::warning::probe $refused accessible by integration (HTTP 403)"

setup cuts-a-long-comment
probe <<'CHECK'
pad=$(printf '%090d' 0)
for i in $(seq 700); do finding a "Finding $i: $pad."; done
CHECK
cut='[the job summary](https://github.com/o/r/actions/runs/7) holds all of it._'
jq -e --arg cut "$cut" '.input.body | length < 65536 and endswith($cut)' "$FAKE/writes" \
    >/dev/null || fail "the comment is not cut: $(tail -c 300 "$FAKE/writes")"

setup warns-on-an-error
probe <<'CHECK'
false
finding a 'Never found.'
CHECK
warns '::warning::probe could not check #1: check.sh:7: false exited with 1'
warnings 1

setup warns-on-an-unset-variable
probe <<<"echo \"\$UNSET\""
warns '::warning::probe could not check #1: the check exited with 1'
prints 'UNSET: unbound variable'

setup warns-on-an-undeclared-rule
probe <<<"finding c 'No rule c.'"
warns '::warning::probe could not check #1: no rule c is declared, for the finding: No rule c.'

setup warns-as-the-check-says
probe <<<"cannot_check 'GitHub lists no commit.'"
warns '::warning::probe could not check #1: GitHub lists no commit.'
warnings 1

setup warns-on-an-error-in-an-issue
probe_issue <<<false
warns '::warning::probe could not check #1: check.sh:7: false exited with 1'
warnings 1

setup warns-on-another-event
probe PR= ISSUE= GITHUB_EVENT_NAME=push </dev/null
warns '::warning::probe checks a pull request or an issue, and the push event has neither: run it'
warns 'event has neither: run it on pull_request or issues.'
warnings 1

# The runner downloads OWNER/REPO/actions/NAME@REF into _actions/OWNER/REPO/REF/actions/NAME.
actions=/home/runner/work/_actions
setup links-at-a-sha
probe GITHUB_ACTION_PATH="$actions/o/r/$HEAD_SHA/actions/probe" <<<'file_url skills/x/SKILL.md'
prints "https://github.com/o/r/blob/$HEAD_SHA/skills/x/SKILL.md"

setup links-at-a-tag
probe GITHUB_ACTION_PATH="$actions/o/r/v1.2.0/actions/probe" <<<'file_url skills/x/SKILL.md'
prints 'https://github.com/o/r/blob/v1.2.0/skills/x/SKILL.md'

setup links-at-a-branch-with-a-slash
probe GITHUB_ACTION_PATH="$actions/o/r/feat/x/actions/probe" <<<'file_url a/README.md'
prints 'https://github.com/o/r/blob/feat/x/a/README.md'

setup links-a-checkout-to-main
probe GITHUB_ACTION_PATH=/home/runner/work/r/r/actions/probe <<<'file_url skills/x/SKILL.md'
prints 'https://github.com/zadykian/toolkit/blob/main/skills/x/SKILL.md'
