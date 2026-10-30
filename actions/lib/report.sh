# shellcheck shell=bash
# The report of an action's check.sh, which sources it: its findings, as annotations, a job
# summary, and one comment on the pull request or the issue it checks. Sourcing it defines
# functions and sets the report_ variables, and runs nothing.
#
#   report_start NAME                  starts the report of the action NAME
#   rule KEY TITLE URL FIX             declares the rule KEY
#   finding KEY MESSAGE [FILE [LINE]]  records a finding of the rule KEY
#   report_finish                      reports the findings, and exits 0
#   cannot_check REASON                warns that the check could not run, and exits 0
#   file_url PATH                      prints the URL of the file PATH at the action's ref
#
# report_start reads GH_REPO, owner/name, PR, the pull request's number, and COMMENT, true where
# omitted. Where PR is empty, it reads ISSUE, the issue's number. Where both are empty, as on an
# event other than pull_request and issues, it warns and exits 0. It then traps errors, so that a
# check runs under set -euo pipefail and never fails the job: an error ends it in one warning,
# `NAME could not check #N: REASON`, and the status 0. N is the number either way, as in the
# comment's endpoints, repos/OWNER/REPO/issues/N/comments. Call finding and cannot_check in the
# check's own shell, never in a pipeline or a $(...), which run in a subshell: feed a loop with
# `done <<<"$list"` instead.
#
# TITLE is a line of text, URL the rule's section of the skill, and FIX how to fix a finding, in
# Markdown. MESSAGE says where and what is wrong, quoting it. FILE is a path from the repository's
# root, and LINE a line of its new side: with both, the annotation shows in Files changed.
#
# file_url prints https://github.com/OWNER/REPO/blob/REF/PATH, where the step runs
# `uses: OWNER/REPO/actions/NAME@REF` and PATH is a path from that repository's root. An action run
# from a checkout, as `./actions/NAME`, links to PATH on main of zadykian/toolkit.
#
# report_finish reads the SHA of the pull request's head, or the issue's last update, its
# updated_at, then:
#
# - writes the report to $GITHUB_STEP_SUMMARY, as of that SHA or update. It opens with "This check
#   warns and does not block the merge", or on an issue, where no merge waits, with "This check
#   warns and blocks nothing". It then gives each rule with findings a section: its title, link,
#   findings and fix;
# - where COMMENT is true, keeps its one comment to the report, the one that
#   <!-- zadykian/actions:NAME --> starts: it creates or edits it. A clean check edits it to say
#   that no findings remain, and never creates one. Runs that race may each create one, so it
#   then keeps the oldest, with its report, and deletes the others. A report over GitHub's limit
#   is cut, with a note. A refusal, as of a fork's read-only token, is one warning;
# - prints a ::warning for each of the first findings, 10 at most, as GitHub shows 10 a step. The
#   last says how many more the summary holds. On a pull request, it leaves out each warning that
#   another workflow run's check run on the head shows already, as Files changed shows those of
#   every run on the head: of an edit to the title, and of a run that a newer one cancelled. Where
#   gh cannot list them, as where a private repository's job grants no checks: read, it leaves
#   out none.
#
# A check.sh, for one rule:
#
#   #!/bin/bash
#   set -euo pipefail
#   # shellcheck source=actions/lib/report.sh
#   . "$GITHUB_ACTION_PATH/../lib/report.sh"
#   report_start pr-description
#   skill=$(file_url skills/atomic-commits/SKILL.md)
#   rule empty 'The description is empty' "$skill#6-stack-mechanics-git--238" \
#       "Describe the change under \`## Problem\` and \`## Changes\`."
#   body=$(gh api "repos/$GH_REPO/pulls/$PR" --jq .body)
#   [ -n "${body//[[:space:]]/}" ] || finding empty "The description of #$PR is empty."
#   report_finish

# The rules by index: their keys, titles, links and fixes.
report_keys=() report_titles=() report_urls=() report_fixes=()
# The findings by index: their rules' indices, messages, files and lines.
report_rules=() report_messages=() report_files=() report_lines=()
# The action's name, the number of the pull request or the issue it reports on, and the error
# that ends it.
report_name='' report_number='' report_error=''

# report_start starts the report of the action $1, on the pull request $PR, or the issue $ISSUE
# where PR is empty.
report_start() {
    report_name=$1 report_number=${PR:-${ISSUE-}}
    if [ -z "$report_number" ]; then
        echo "::warning::$1 checks a pull request or an issue, and the ${GITHUB_EVENT_NAME-}" \
            "event has neither: run it on pull_request or issues."
        exit 0
    fi
    set -E
    trap 'report_error="${BASH_SOURCE[0]##*/}:$LINENO: $BASH_COMMAND exited with $?"' ERR
    trap 'report_exit $?' EXIT
}

# cannot_check warns that the check could not run, for the reason $1, and exits 0.
cannot_check() {
    printf '::warning::%s could not check #%s: %s\n' "$report_name" "$report_number" \
        "$(report_escape "$1")"
    exit 0
}

# report_exit turns the check's exit with the status $1, other than 0, into a warning and the
# status 0.
report_exit() {
    [ "$1" = 0 ] || cannot_check "${report_error:-the check exited with $1}"
}

# file_url prints the URL of the file $1 at the ref of the action's step. A composite action's
# own steps get no GITHUB_ACTION_REPOSITORY or GITHUB_ACTION_REF, as actions/runner's
# ActionRunner.cs clears them, so it reads the action path. The runner downloads
# OWNER/REPO/actions/NAME@REF into _actions/OWNER/REPO/REF/actions/NAME, as its ActionManager.cs
# does, and REF may hold slashes. A checkout's ./actions/NAME runs in the workspace, at a commit
# the step cannot tell. GITHUB_SHA is the merge commit on pull_request, while the checkout may
# hold the head, or another repository. So it links to main.
file_url() {
    if [[ ${GITHUB_ACTION_PATH-} =~ /_actions/([^/]+/[^/]+)/(.+)/actions/[^/]+$ ]]; then
        printf 'https://github.com/%s/blob/%s/%s\n' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "$1"
    else
        printf 'https://github.com/zadykian/toolkit/blob/main/%s\n' "$1"
    fi
}

# rule declares the rule $1, titled $2, which the skill's section at the URL $3 sets, and whose
# findings the Markdown $4 says how to fix.
rule() {
    report_keys+=("$1") report_titles+=("$2") report_urls+=("$3") report_fixes+=("$4")
}

# finding records the finding $2 of the rule $1, at the file $3 and its line $4 where given.
finding() {
    local i
    for i in "${!report_keys[@]}"; do
        [ "${report_keys[i]}" = "$1" ] || continue
        report_rules+=("$i") report_messages+=("$2") report_files+=("${3-}") report_lines+=("${4-}")
        return 0
    done
    cannot_check "no rule $1 is declared, for the finding: $2"
}

# report_plural prints the count $1 of the noun $2: 1 finding, or 2 findings.
report_plural() {
    if [ "$1" = 1 ]; then printf '1 %s' "$2"; else printf '%s %ss' "$1" "$2"; fi
}

# report_escape prints the text $1 escaped as a workflow command's message, or as a property
# where $2 is set.
report_escape() {
    local text=${1//'%'/%25}
    text=${text//$'\r'/%0D}
    text=${text//$'\n'/%0A}
    [ -z "${2-}" ] || text=${text//:/%3A} text=${text//,/%2C}
    printf '%s' "$text"
}

# report_shown prints the warnings that the check runs on the commit $1 show, a line each, as
# report_annotate prints them. It skips this workflow run's, as GitHub shows its last attempt
# alone. It prints each warning three times: with its file and line, with its file alone, and
# with neither, as GitHub stores one of no line at line 1, and one of no file at .github. It drops
# the note on more findings.
report_shown() {
    local own="/actions/runs/${GITHUB_RUN_ID-}/" runs run
    runs=$(gh api --paginate "repos/$GH_REPO/commits/$1/check-runs?per_page=100" --jq "
        .check_runs[] | select(.output.annotations_count > 0)
        | select(.details_url // \"\" | contains(\"$own\") | not) | .id") || return
    for run in $runs; do
        gh api --paginate "repos/$GH_REPO/check-runs/$run/annotations?per_page=100" | jq -r '
            def text: gsub("%"; "%25") | gsub("\r"; "%0D") | gsub("\n"; "%0A");
            def property: text | gsub(":"; "%3A") | gsub(","; "%2C");
            .[] | select(.annotation_level == "warning")
            | "::warning title=\(.title // "" | property)" as $title
            | (.message | sub("\nThe job summary holds [0-9]+ more findings?\\.$"; "") | text)
            as $text
            | "\($title)::\($text)", "\($title),file=\(.path | property)::\($text)",
                "\($title),file=\(.path | property),line=\(.start_line)::\($text)"' || return
    done
}

# report_annotate prints a ::warning for each of the first $1 findings that no line of $2 shows
# already. The last says how many more there are.
report_annotate() {
    local i rule message properties more shown=$'\n'${2-}$'\n' left=() left_messages=()
    for i in "${!report_messages[@]}"; do
        rule=${report_rules[i]}
        message="${report_messages[i]}"$'\n'"The rule: ${report_urls[rule]}"
        properties="title=$(report_escape "$report_name: ${report_titles[rule]}" property)"
        if [ -n "${report_files[i]}" ]; then
            properties+=",file=$(report_escape "${report_files[i]}" property)"
            [ -z "${report_lines[i]}" ] || properties+=",line=${report_lines[i]}"
        fi
        [[ $shown != *$'\n'"::warning $properties::$(report_escape "$message")"$'\n'* ]] || continue
        left+=("$properties") left_messages+=("$message")
    done
    more=$((${#left[@]} - $1))
    for ((i = 0; i < ${#left[@]} && i < $1; i++)); do
        message=${left_messages[i]}
        if [ $((i + 1)) = "$1" ] && [ "$more" -gt 0 ]; then
            message+=$'\n'"The job summary holds $(report_plural "$more" 'more finding')."
        fi
        printf '::warning %s::%s\n' "${left[i]}" "$(report_escape "$message")"
    done
}

# report_text prints the report in Markdown, which says that the check warns and $1, as of $2.
report_text() {
    local count=${#report_messages[@]} i j at found
    printf '### %s\n\nThis check warns and %s. ' "$report_name" "$1"
    if [ "$count" = 0 ]; then
        printf 'No findings remain as of %s.\n' "$2"
        return
    fi
    printf 'It found %s as of %s.\n' "$(report_plural "$count" finding)" "$2"
    for i in "${!report_keys[@]}"; do
        found=''
        for j in "${!report_messages[@]}"; do
            [ "${report_rules[j]}" = "$i" ] || continue
            at=${report_files[j]}${report_lines[j]:+:${report_lines[j]}}
            found+="- ${at:+\`$at\`: }${report_messages[j]//$'\n'/$'\n'  }"$'\n'
        done
        [ -z "$found" ] || printf '\n#### %s\n\nThe rule: %s\n\n%s\nHow to fix it:\n\n%s\n' \
            "${report_titles[i]}" "${report_urls[i]}" "$found" "${report_fixes[i]}"
    done
}

# report_marked prints the ids of the comments that the marker $1 starts, the oldest first, as
# GitHub lists them by ascending id.
report_marked() {
    gh api --paginate "repos/$GH_REPO/issues/$report_number/comments?per_page=100" \
        --jq ".[] | select(.body | startswith(\"$1\")) | .id"
}

# report_comment keeps the action's comment to the report $1: it edits the one that its marker
# starts, or creates one where $2, the count of findings, is not 0. Runs that race may each create
# one, so it then moves the report to the oldest and deletes the others: the run that ends last
# leaves one. It fails as gh fails, but on a comment that another run deleted first.
report_comment() {
    # The comments made so far start with this marker, so it keeps the old name, zadykian/actions.
    local marker="<!-- zadykian/actions:$report_name -->" ids id body run note first other error
    ids=$(report_marked "$marker") || return
    id=${ids%%$'\n'*}
    [ -n "$id" ] || [ "$2" != 0 ] || return 0
    # GitHub takes 65536 characters at most.
    run=${GITHUB_SERVER_URL-}/${GITHUB_REPOSITORY-}/actions/runs/${GITHUB_RUN_ID-}
    note=$'\n\n'"_The report is cut here: [the job summary]($run) holds all of it._"
    body=$(jq -n --arg body "$marker"$'\n'"$1" --arg note "$note" '{body: (if ($body | length)
        > 60000 then ($body[:60000] | sub("\n[^\n]*$"; "")) + $note else $body end)}') || return
    if [ -n "$id" ]; then
        gh api -X PATCH "repos/$GH_REPO/issues/comments/$id" --input - <<<"$body" >/dev/null
    else
        id=$(gh api -X POST "repos/$GH_REPO/issues/$report_number/comments" --input - --jq .id \
            <<<"$body")
    fi || return
    ids=$(report_marked "$marker") || return
    first=${ids%%$'\n'*}
    if [ -n "$first" ] && [ "$first" != "$id" ]; then
        gh api -X PATCH "repos/$GH_REPO/issues/comments/$first" --input - <<<"$body" >/dev/null
    fi || return
    for other in ${ids#"$first"}; do
        error=$(gh api -X DELETE "repos/$GH_REPO/issues/comments/$other" 2>&1) ||
            [[ $error == *'(HTTP 404)'* ]] || { printf '%s\n' "$error" >&2 && return 1; }
    done
}

# report_finish reports the findings, and exits 0. A comment's refusal takes one of the 10
# warnings.
report_finish() {
    local head updated report error shown='' limit=10
    if [ -n "${PR-}" ]; then
        head=$(gh api "repos/$GH_REPO/pulls/$PR" --jq .head.sha)
        report=$(report_text 'does not block the merge' "\`${head:0:7}\`")
        shown=$(report_shown "$head") || shown=''
    else
        updated=$(gh api "repos/$GH_REPO/issues/$ISSUE" --jq .updated_at)
        report=$(report_text 'blocks nothing' "the issue's last update, \`$updated\`")
    fi
    printf '%s\n' "$report" >>"${GITHUB_STEP_SUMMARY:-/dev/stdout}"
    if [ "${COMMENT:-true}" = true ] &&
        ! error=$({ report_comment "$report" "${#report_messages[@]}" >/dev/null; } 2>&1); then
        error=${error##*$'\n'}
        error="could not comment on #$report_number, so the job summary alone holds the report: \
${error#gh: }"
        echo "::warning::$report_name $(report_escape "$error")"
        limit=9
    fi
    report_annotate "$limit" "$shown"
    exit 0
}
