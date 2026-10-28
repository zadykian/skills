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

issue warns-on-a-title-off-the-form "$clean" '{"title": "Check an issue"}'
warns "::The title \`Check an issue\` is not \`type(scope)!: description\`."
warnings 1

title=$(sed -n 's/^title: "\(.*\)"$/\1/p' "$ROOT/skills/issue/change.yml")
issue warns-on-the-title-of-the-form "$clean" "{\"title\": \"$title\"}"
warns "::The title \`type(scope): description\` is not \`type(scope)!: description\`."
warnings 1

# 72 characters, of two bytes each but the type's.
edge="feat: $(printf 'é%.0s' $(seq 66))"
issue passes-a-title-of-72-characters "$clean" "{\"title\": \"$edge\"}"
warnings 0

issue warns-on-a-title-of-73-characters "$clean" "{\"title\": \"${edge}é\"}"
warns 'é…` is 73 characters long: 1 over 72.'
warnings 1
