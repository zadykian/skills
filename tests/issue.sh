# shellcheck shell=bash
# The cases of issue/check.sh, each issue #1, as the issues event sets ISSUE and leaves PR empty.

# The check links to the skill on main, as check runs it from this checkout.
url=https://github.com/zadykian/toolkit/blob/main/skills/issue/SKILL.md#3-write-it

# issue starts the case $1, of issue #1 with the body $2 and the fields of the JSON $3 over it,
# and checks it.
issue() {
    setup "$1"
    answer repos/o/r/issues/1 "$(jq -n --arg body "$2" --argjson over "${3:-null}" '{number: 1,
        title: "feat(issue): check an issue", body: $body, updated_at: "2026-10-28T09:00:00Z"} *
        ($over // {})')"
    check issue PR= ISSUE=1
}

summary=$'### Summary\n\nA check is missing. Line references are to main 0123456.'
today=$'\n\n### Today\n\n- `actions/x.sh:12` checks nothing.'
proposal=$'\n\n### Proposal\n\n- Check it.'
clean=$summary$today$proposal

issue warns-on-an-empty-body ''
warns '::warning title=issue%3A The body is empty::The body of #1 is empty.'
summarizes "The rule: $url"
warnings 1

issue warns-on-a-blank-body $' \r\n\t\n'
warns 'The body of #1 is empty.'

issue warns-on-no-body '' '{"body": null}'
warns 'The body of #1 is empty.'

issue passes-a-clean-issue "$clean"
warnings 0
summarizes 'This check warns and blocks nothing. No findings remain'
