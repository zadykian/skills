#!/bin/bash
# Warns where the body of issue $ISSUE of $GH_REPO strays from the form that section 3 of the
# issue skill sets. It reads the issue with $GH_TOKEN, and lib/report.sh reports the findings.

set -euo pipefail
# A $(...) fails as its command fails. A length counts characters, not bytes.
shopt -s inherit_errexit
export LC_ALL=C.UTF-8
# shellcheck source=actions/lib/report.sh
. "$GITHUB_ACTION_PATH/../lib/report.sh"
report_start issue

skill=$(file_url skills/issue/SKILL.md)
url=$skill#3-write-it

issue=$(gh api "repos/$GH_REPO/issues/$ISSUE")
# GitHub keeps the line ends that the browser sent, \r\n.
body=$(jq -r '.body // ""' <<<"$issue")
body=${body//$'\r'/}

rule empty 'The body is empty' "$url" "Write the body as section 3 sets it: the issue form's \
fields, in its order, each a \`### LABEL\` and its text."
if [ -z "${body//[[:space:]]/}" ]; then
    finding empty "The body of #$ISSUE is empty."
    report_finish
fi
report_finish
