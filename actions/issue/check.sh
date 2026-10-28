#!/bin/bash
# Warns where the title or the body of issue $ISSUE of $GH_REPO strays from the form that section
# 3 of the issue skill sets. It reads the issue with $GH_TOKEN, lib/markdown.sh its body, and
# lib/report.sh reports the findings.

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
# The skill fixes these, and no input changes them: the labels of the issue form's fields, in its
# order; the types and the form of a header, as atomic-commits sets a commit's; and the most
# characters of a title.
labels=('Summary' 'Today' 'Proposal' 'Pull requests' 'Waits' 'Open decisions')
types='feat fix refactor perf test docs style build ci chore revert'
header_form="^(${types// /|})(\([a-z0-9._/-]+\))?!?: [^ ]"
max_title=72
# The body of section 3's example, which the fixes quote as a Markdown code block. Its backticks
# are Markdown's, never a command.
# shellcheck disable=SC2016
form_md='### Summary

SUMMARY. Line references are to main SHA.

### Today

- `path/file:12-30` does X.

### Proposal

- Do Y.'
skeleton=$(printf '~~~markdown\n%s\n~~~' "$form_md")
# The labels joined by commas, as a fix lists them.
printf -v listed '%s, ' "${labels[@]}" && listed=${listed%, }

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
fields, in its order, each a \`### LABEL\` and its text.

$skeleton"
if [ -z "${body//[[:space:]]/}" ]; then
    finding empty "The body of #$ISSUE is empty."
    report_finish
fi

markdown_read "$body"

rule sections "The body has a heading other than the form's fields, or out of order" "$url" \
    "Keep to the form's fields, each a heading of level 3, once and in this order: $listed. \
Fold any other heading into them. A heading in a code block or an HTML comment is none.

$skeleton"
last=-1
for i in "${!h_texts[@]}"; do
    at="The heading ${h_quotes[i]}, line $((h_starts[i] + 1)) of the body,"
    k=-1
    for j in "${!labels[@]}"; do [ "${h_texts[i]}" != "${labels[j]}" ] || k=$j; done
    if [ "$k" = -1 ]; then
        finding sections "$at is none of the form's fields."
        continue
    fi
    [ "${h_levels[i]}" = 3 ] ||
        finding sections "$at is of level ${h_levels[i]}: write it \`### ${labels[k]}\`."
    if [ "$k" -le "$last" ]; then
        finding sections "$at comes after \`### ${labels[last]}\`: the fields go in the form's \
order, each once."
    else
        last=$k
    fi
done
report_finish
