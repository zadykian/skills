#!/bin/bash
# Warns where the description of pull request $PR of $GH_REPO strays from the form that
# atomic-commits §6 sets. It reads the pull request with $GH_TOKEN, lib/markdown.sh its
# description, and lib/report.sh reports the findings.

set -euo pipefail

# shellcheck source=actions/lib/report.sh
. "$GITHUB_ACTION_PATH/../lib/report.sh"
# shellcheck source=actions/lib/markdown.sh
. "$GITHUB_ACTION_PATH/../lib/markdown.sh"
report_start pr-description

skill=$(file_url skills/atomic-commits/SKILL.md)
url=$skill#6-stack-mechanics-git--238
# The form of a description, as section 6 shows it, in the parts that the fixes quote.
problem_md='## Problem

What is wrong or missing today, and why it matters: one to three sentences. Closes #12.'
changes_md='## Changes

- One bullet per high-level change, said by behavior, not by file.'
footer_md='BREAKING CHANGE: what changed, and what callers must do.'

# template prints the parts $1, $2... of the form as a Markdown code block.
template() {
    local text
    text=$(printf '%s\n\n' "$@")
    printf '~~~markdown\n%s\n~~~' "$text"
}

# words prints the count of words in the text $1: runs of characters between spaces, other than
# those of ASCII punctuation alone, such as a bullet's - or a heading's ##.
words() {
    { LC_ALL=C grep -o '[^[:space:]]*[^[:space:][:punct:]][^[:space:]]*' <<<"$1" || true; } | wc -l
}

rule empty 'The description is empty' "$url" "Describe the pull request in the form that section \
6 sets, and end it in the footer where the title has \`!\`.

$(template "$problem_md" "$changes_md" "$footer_md")"

# The most words of a description, as $url sets it. No input changes it.
max=200
pull=$(gh api "repos/$GH_REPO/pulls/$PR")
# GitHub keeps the line ends that the browser sent, \r\n.
body=$(jq -r '.body // ""' <<<"$pull")
body=${body//$'\r'/}
if [ -z "${body//[[:space:]]/}" ]; then
    finding empty "The description of #$PR is empty."
    report_finish
fi

markdown_read "$body"

rule problem 'The description does not open with a Problem section in prose' "$url" "Open the \
description with \`## Problem\`: one to three sentences on what is wrong or missing today, and \
why it matters. An HTML comment holds no prose.

$(template "$problem_md")"
p=$(first 2 Problem)
if [ "$p" = -1 ]; then
    finding problem "The description has no \`## Problem\` heading."
else
    at="\`## Problem\`, line $((h_starts[p] + 1)) of the description,"
    before=''
    for ((i = 0; i < h_starts[p]; i++)); do
        if [ "${kinds[i]}" = code ] || (($(words "${texts[i]}"))); then
            before=$(quote "${texts[i]}") && break
        fi
    done
    [ -z "$before" ] || finding problem "$at is not its first section: $before comes before it."
    (($(words "$(section "$p")"))) || finding problem "$at holds no prose."
fi

rule changes 'The description has no Changes section of bullets after Problem' "$url" "Follow \
\`## Problem\` with \`## Changes\`: a bullet for each high-level change, said by behavior, not \
by file.

$(template "$changes_md")"
c=$(first 2 Changes)
if [ "$c" = -1 ]; then
    finding changes "The description has no \`## Changes\` heading."
else
    at="\`## Changes\`, line $((h_starts[c] + 1)) of the description,"
    [ "$p" = -1 ] || [ "$c" -gt "$p" ] ||
        finding changes "$at comes before \`## Problem\`, line $((h_starts[p] + 1))."
    # A bullet holds text, which a thematic break, such as - - -, lacks.
    bullet='^[[:blank:]]*[-*+][[:blank:]]+[^[:blank:]]' content='[^-*[:blank:]]'
    bullets=0 opening=''
    while IFS= read -r line; do
        [ -n "$opening" ] || [ -z "${line//[[:blank:]]/}" ] || opening=$(quote "$line")
        [[ ! $line =~ $bullet || ! $line =~ $content ]] || bullets=$((bullets + 1))
    done <<<"$(section "$c")"
    [ "$bullets" != 0 ] || finding changes "$at holds no bullet${opening:+: it opens $opening}."
fi

rule sections 'The description has a heading other than the two, or out of order' "$url" "Keep \
to these headings, at level 2 and in this order, each once: fold any other into them. A heading \
in a code block is no heading.

$(template "$problem_md" "$changes_md")"
names=(Problem Changes) last=-1
for i in "${!h_texts[@]}"; do
    at="The heading ${h_quotes[i]}, line $((h_starts[i] + 1)) of the description,"
    k=-1
    for j in "${!names[@]}"; do [ "${h_levels[i]} ${h_texts[i]}" != "2 ${names[j]}" ] || k=$j; done
    if [ "$k" = -1 ]; then
        finding sections "$at is neither \`## Problem\` nor \`## Changes\`."
    elif [ "$k" -le "$last" ]; then
        finding sections "$at comes after \`## ${names[last]}\`: they go Problem, then Changes, \
each once."
    else
        last=$k
    fi
done

rule breaking "The title's ! and the BREAKING CHANGE: footer do not match" "$url" "A breaking \
change has both: \`!\` before the title's colon, as \`feat(scope)!: ...\`, and the footer, as \
the description's last paragraph. Only an attribution line, such as \`🤖 Generated \
with [Claude Code](...)\`, may follow it. Where nothing breaks, drop both.

$(template "$footer_md")"
title=$(jq -r .title <<<"$pull")
bang='^[[:alpha:]]+(\([^()]*\))?!:' token='^BREAKING[ -]CHANGE:[[:blank:]]+[^[:blank:]]'
# The description's last line, above an attribution line, such as Claude Code's, that may end it.
end=$(filled $((${#kinds[@]} - 1))) last=-1 footer=-1 by='^(🤖 )?Generated with '
if ((end >= 0)) && [[ ${texts[end]} =~ $by ]]; then end=$(filled $((end - 1))); fi
# The first lines of the last paragraph and of the first footer, which open after a blank line.
for ((i = 0; i <= end; i++)); do
    if [ "${kinds[i]}" = text ] && [ -n "${texts[i]//[[:blank:]]/}" ] && { ((i == 0)) ||
        [ "${kinds[i - 1]}" != text ] || [ -z "${texts[i - 1]//[[:blank:]]/}" ]; }; then
        last=$i
        [[ $footer != -1 || ! ${texts[i]} =~ $token ]] || footer=$i
    fi
done
ends='' footed=false
if ((end >= 0)) && [ "${kinds[end]}" = code ]; then
    ends=': it ends in a code block'
elif ((end >= 0)); then
    [ "${kinds[end]}" = text ] || last=$end
    [[ ! ${texts[last]} =~ $token ]] || footed=true
    ends=": it ends in $(quote "${texts[last]}")"
fi
if [[ $title =~ $bang ]] && ! $footed; then
    finding breaking "The title $(quote "$title") has \`!\`, but the description does not end in \
a \`BREAKING CHANGE:\` footer$ends."
elif [[ ! $title =~ $bang ]] && [ "$footer" != -1 ]; then
    finding breaking "The description has a \`BREAKING CHANGE:\` footer, line $((footer + 1)), \
but the title $(quote "$title") has no \`!\`."
fi

rule length "The description is over $max words" "$url" "Cut the description to $max words, \
outside code blocks and HTML comments: one to three sentences of problem, and a bullet for each \
high-level change. Leave the details to the commits.

$(template "$problem_md" "$changes_md")"
prose=''
for i in "${!kinds[@]}"; do [ "${kinds[i]}" = code ] || prose+=${texts[i]}$'\n'; done
count=$(($(words "$prose")))
((count <= max)) || finding length "The description holds $count words, outside code blocks and \
HTML comments: $((count - max)) over $max."
report_finish
