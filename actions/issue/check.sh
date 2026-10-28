#!/bin/bash
# Warns where the title or the body of issue $ISSUE of $GH_REPO strays from the form that section
# 3 of the issue skill sets. It reads the issue with $GH_TOKEN, and lib/report.sh reports the
# findings.

set -euo pipefail
# A $(...) fails as its command fails. A length counts characters, not bytes.
shopt -s inherit_errexit
export LC_ALL=C.UTF-8
# shellcheck source=actions/lib/report.sh
. "$GITHUB_ACTION_PATH/../lib/report.sh"
# shellcheck source=actions/lib/markdown.sh
. "$GITHUB_ACTION_PATH/../lib/markdown.sh"
report_start issue

skill=$(file_url skills/issue/SKILL.md)
url=$skill#3-write-it
# The skill fixes these, and no input changes them: the types and the form of a header, as
# atomic-commits sets a commit's, and the most characters of a title.
types='feat fix refactor perf test docs style build ci chore revert'
header_form="^(${types// /|})(\([a-z0-9._/-]+\))?!?: [^ ]"
max_title=72

issue=$(gh api "repos/$GH_REPO/issues/$ISSUE")
title=$(jq -r .title <<<"$issue")
# GitHub keeps the line ends that the browser sent, \r\n.
body=$(jq -r '.body // ""' <<<"$issue")
body=${body//$'\r'/}

rule title "The title is not a Conventional Commits header of $max_title characters at most" \
    "$url" "Retitle the issue as atomic-commits sets a commit's header, in $max_title characters \
at most: \`type(scope)!: description\`, its type one of \`$types\` and its scope lowercase. \
\`gh issue edit $ISSUE --title '<type>(<scope>): <description>'\` does it."
[[ $title =~ $header_form ]] ||
    finding title "The title $(quote "$title") is not \`type(scope)!: description\`."
[ "${#title}" -le "$max_title" ] || finding title "The title $(quote "$title") is ${#title} \
characters long: $((${#title} - max_title)) over $max_title."

rule empty 'The body is empty' "$url" "Write the body as section 3 sets it: the issue form's \
fields, in its order, each a \`### LABEL\` and its text."
if [ -z "${body//[[:space:]]/}" ]; then
    finding empty "The body of #$ISSUE is empty."
    report_finish
fi
report_finish
